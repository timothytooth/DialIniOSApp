//
//  DIALBroadcastObject.h
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 11/12/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

@import Foundation;

@interface DIALBroadcastObject : NSObject

/**
 * The user who broadcasted
 */
@property (nonatomic, strong, readonly) NSString *username;

/**
 * The user profile image
 */
@property (nonatomic, strong, readonly) NSURL *userProfileImageURL;

/**
 *
 */
@property (nonatomic, strong, readonly) NSString *broadcastString;

/**
 *
 */
@property (nonatomic, strong, readonly) NSString *locationString;


/**
 * The user profile image
 */
@property (nonatomic, strong, readonly) NSURL *broadcastImageURL;

@property (nonatomic, strong, readonly) NSData *broadcastData;

/**
 *
 */
@property (nonatomic, strong, readonly) NSArray<NSString *> *commentArray;

- (void)setPropertiesWithUsername:(NSString *)username userProfileImageURL:(NSString *)userProfileImageURL broadcast:(NSString *)broadcast location:(NSString *)location broadcastData:(NSData *)broadcastData;

- (void)mattsMethod;

@end
