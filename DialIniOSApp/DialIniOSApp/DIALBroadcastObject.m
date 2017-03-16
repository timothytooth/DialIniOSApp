//
//  DIALBroadcastObject.m
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 11/12/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

#import "DIALBroadcastObject.h"

@interface DIALBroadcastObject ()

/**
 * The username who broadcasted
 */
@property (nonatomic, strong, readwrite) NSString *username;

/**
 *
 */
@property (nonatomic, strong, readwrite) NSURL *userProfileImageURL;

/**
 *
 */
@property (nonatomic, strong, readwrite) NSString *broadcastString;

/**
 *
 */
@property (nonatomic, strong, readwrite) NSString *locationString;

@property (nonatomic, strong, readwrite) NSURL *broadcastImageURL;

@property (nonatomic, strong, readwrite) NSData *broadcastData;

/**
 *
 */
@property (nonatomic, strong, readwrite) NSArray<NSString *> *commentArray;

@end

@implementation DIALBroadcastObject

- (void)setPropertiesWithUsername:(NSString *)username userProfileImageURL:(NSString *)userProfileImageURL broadcast:(NSString *)broadcast location:(NSString *)location broadcastData:(NSData *)broadcastData {
    self.username = username;
    self.userProfileImageURL = [[NSURL alloc] initWithString:userProfileImageURL];
    self.broadcastString = broadcast;
    self.locationString = location;
    self.broadcastData = broadcastData;
}

- (void)mattsMethod {
    NSLog(@"%@", @"Hey, Matt!");
}

@end
