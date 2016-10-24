//
//  ABMKNetworkRequestOperation.m
//  Audible
//
//  Created by Esposito, Timothy on 8/22/16.
//  Copyright © 2016 Audible, Inc. All rights reserved.
//

#import "ABMKNetworkRequestOperation.h"

#import "ABReadOnlyUserDefaults.h"
#import "ABCommonsConstants.h"
#import "NSMutableURLRequest+AudibleHeaders.h"

#import <AmazoniOSCommons/NSMutableURLRequest+AMZRequestSigning.h>
#import <AmazoniOSCommons/ABLoggingManager.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const ABMKNetworkRequestDomain = @"ABMKNetworkRequestDomain";

/**
 * Internal state of the operation
 */
typedef NS_ENUM(NSUInteger, ABMKNetworkRequestOperationState) {
    /**
     * Corresponds to NSOperation's "ready" state
     */
    ABMKNetworkRequestOperationStateReady,
    /**
     * Corresponds to NSOperation's "executing" state
     */
    ABMKNetworkRequestOperationStateExecuting,
    /**
     * Corresponds to NSOperation's "finished" state
     */
    ABMKNetworkRequestOperationStateFinished
};

@interface ABMKNetworkRequestOperation ()

/**
 * Used to keep track of the internal state of the operation since we took control of the operation lifecycle
 */
@property (nonatomic, assign) ABMKNetworkRequestOperationState state;

/**
 * The session is injected in the initializer for unit testing, so we need to keep a reference to it
 */
@property (nonatomic, strong) NSURLSession *session;

/**
 * The content insertion call is an authenticated call, so we need to be able to sign the request
 */
@property (nonatomic, strong) AMZRequestSigningPair *requestSigningPair;

@end

@implementation ABMKNetworkRequestOperation

- (instancetype)initWithSession:(NSURLSession *)session requestSigningPair:(AMZRequestSigningPair *)signingPair {
    NSParameterAssert(session);
    NSParameterAssert(signingPair);

    if (self = [super init]) {
        NSAssert(![self isMemberOfClass:[ABMKNetworkRequestOperation class]], @"This class must be subclassed!");

        _session = session;
        _requestSigningPair = signingPair;
        _state = ABMKNetworkRequestOperationStateReady;
    }

    return self;
}

- (void)start {
    if (self.isCancelled) {
        self.state = ABMKNetworkRequestOperationStateFinished;
        return;
    }

    self.state = ABMKNetworkRequestOperationStateExecuting;

    // Build the endpoint URL
    NSURL *audibleAPIURL = [NSURL URLWithString:[[ABReadOnlyUserDefaults standardUserDefaults] objectForKey:kDefaultAudibleAPIEndpointKey]];
    NSURL *baseURL = [NSURL URLWithString:self.networkRequestURLString relativeToURL:audibleAPIURL];

    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:baseURL resolvingAgainstBaseURL:YES];
    NSMutableArray *queryItems = [NSMutableArray array];

    for (NSString *parameterKey in self.networkRequestParameterDictionary.allKeys) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:parameterKey value:self.networkRequestParameterDictionary[parameterKey]]];
    }

    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"response_groups" value:[self.networkRequestResponseGroups componentsJoinedByString:@","]]];

    components.queryItems = [queryItems copy];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:components.URL];
    request.HTTPMethod = self.networkRequestHTTPMethod;
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    request.cachePolicy = self.networkRequestCachePolicy;

    [request addStandardAmazonHeaders];

    BOOL success = [request signRequestForADPAuthenticatorWithRequestSigningPair:self.requestSigningPair];
    if (!success) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Signing failed for request: %@ signing pair: %@", request, self.requestSigningPair] };
        NSError *signingError = [NSError errorWithDomain:ABMKNetworkRequestDomain code:ABMKNetworkRequestErrorCodeRequestSigningFailed userInfo:userInfo];
        [self networkRequestDidFailWithError:&signingError];

        self.state = ABMKNetworkRequestOperationStateFinished;
        return;
    }

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        typeof(weakSelf) strongSelf = weakSelf;
        
        // Network error occurred
        if (error) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: error.localizedDescription, NSUnderlyingErrorKey: error };
            NSError *networkError = [NSError errorWithDomain:ABMKNetworkRequestDomain code:ABMKNetworkRequestErrorCodeNetworkError userInfo:userInfo];
            [strongSelf networkRequestDidFailWithError:&networkError];

            strongSelf.state = ABMKNetworkRequestOperationStateFinished;
            return;
        }
        
        // Received something other than a 200 OK
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Expected a 200 OK response, but received a %ld %@", httpResponse.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode].capitalizedString] };
            NSError *invalidStatusCodeError = [NSError errorWithDomain:ABMKNetworkRequestDomain code:ABMKNetworkRequestErrorCodeInvalidResponseStatus userInfo:userInfo];
            [strongSelf networkRequestDidFailWithError:&invalidStatusCodeError];

            strongSelf.state = ABMKNetworkRequestOperationStateFinished;
            return;
        }
        
        // Parse the response data
        NSError *JSONParseError;
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONParseError];
        
        // JSON parsing failed
        if (!jsonDictionary) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: JSONParseError.localizedDescription, NSUnderlyingErrorKey: JSONParseError };
            NSError *JSONError = [NSError errorWithDomain:ABMKNetworkRequestDomain code:ABMKNetworkRequestErrorCodeJSONParsingError userInfo:userInfo];
            [self networkRequestDidFailWithError:&JSONError];

            strongSelf.state = ABMKNetworkRequestOperationStateFinished;
            return;
        }
        
        // Create model from JSON object
        NSError *creationError;
        [strongSelf processJSON:jsonDictionary error:&creationError];
        
        // Model creation failed
        if (creationError) {
            [self networkRequestDidFailWithError:&creationError];
            
            strongSelf.state = ABMKNetworkRequestOperationStateFinished;
            return;
        }
        
        // Success!
        [self networkRequestDidSucceed];
        
        strongSelf.state = ABMKNetworkRequestOperationStateFinished;
    }];

    // Check if we're cancelled one last time before starting the network request
    if ([self isCancelled]) {
        self.state = ABMKNetworkRequestOperationStateFinished;
        return;
    }

    [task resume];
}

#pragma mark - Protected methods

- (NSString *)networkRequestURLString {
    NSAssert(NO, @"Subclasses must implement this method!");

    return nil;
}

- (NSArray<NSString *> *)networkRequestResponseGroups {
    return @[ @"default" ];
}

- (NSString *)networkRequestHTTPMethod {
    return @"GET";
}

- (NSDictionary<NSString *, id> *)networkRequestParameterDictionary {
    return nil;
}

- (NSURLRequestCachePolicy)networkRequestCachePolicy {
    return NSURLRequestUseProtocolCachePolicy;
}

- (void)processJSON:(__unused NSDictionary *)json error:(__unused NSError *__autoreleasing *)error {
    NSAssert(NO, @"Subclasses must implement this method!");

    return;
}

- (void)networkRequestDidSucceed {
    NSAssert(NO, @"Subclasses must implement this method!");

    return;
}

- (void)networkRequestDidFailWithError:(__unused NSError *__autoreleasing *)error {
    NSAssert(NO, @"Subclasses must implement this method!");

    return;
}

#pragma mark - NSOperation State

- (BOOL)isExecuting {
    return self.state == ABMKNetworkRequestOperationStateExecuting;
}

- (BOOL)isFinished {
    return self.state == ABMKNetworkRequestOperationStateFinished;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)setState:(ABMKNetworkRequestOperationState)state {
    if (_state != state) {

        switch (state) {
            case ABMKNetworkRequestOperationStateReady:
                // Don't send any KVO notifications for the ready state.
                // This is just the initial internal state and the NSOperation
                // isReady state is handled by the base class.
                break;
            case ABMKNetworkRequestOperationStateExecuting:
                [self willChangeValueForKey:@"isExecuting"];
                _state = state;
                [self didChangeValueForKey:@"isExecuting"];
                break;
            case ABMKNetworkRequestOperationStateFinished:
                [self willChangeValueForKey:@"isFinished"];
                _state = state;
                [self didChangeValueForKey:@"isFinished"];
                break;
            default:
                NSAssert(NO, @"Unknown Network Request Operation State: %ld", (unsigned long)state);
                LogWarningSwift(@"Unknown Network Request Operation State: %ld", (unsigned long)state);
                break;
        }
    }
}

@end

NS_ASSUME_NONNULL_END
