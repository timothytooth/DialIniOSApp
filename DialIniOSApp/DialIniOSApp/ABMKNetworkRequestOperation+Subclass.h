//
//  ABMKNetworkRequestOperation+Subclass.h
//  Audible
//
//  Created by Esposito, Timothy on 8/22/16.
//  Copyright © 2016 Audible, Inc. All rights reserved.
//

#import <AmazoniOSCommons/NSMutableURLRequest+AMZRequestSigning.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Methods of ABMKNetworkRequestOperation that are exposed to subclasses
 */
@interface ABMKNetworkRequestOperation (SubclassOnly)

/**
 * This should be the API URL that you plan on making your network request
 */
- (NSString *)networkRequestURLString;

/**
 * The response groups determine how much data the service should return
 */
- (NSArray<NSString *> *)networkRequestResponseGroups;

/**
 * This allows you to specify which HTTP method you are interested in using for the request
 */
- (NSString *)networkRequestHTTPMethod;

/**
 * The dictionary with all the paramenter names and their respective values
 */
- (NSDictionary<NSString *, id> *)networkRequestParameterDictionary;

/**
 * The cache policy to use for this network request
 */
- (NSURLRequestCachePolicy)networkRequestCachePolicy;

/**
 * This method will be called when the JSON response is returned from the service
 */
- (void)processJSON:(NSDictionary *)json error:(NSError *__autoreleasing *)error;

/**
 * This method will be called if the network request succeeds and their are no errors processing the response
 */
- (void)networkRequestDidSucceed;

/**
 * This method will be called if the network request fails or if their were errors processing the response
 */
- (void)networkRequestDidFailWithError:(NSError *__autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
