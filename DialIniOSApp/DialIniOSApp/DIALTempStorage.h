//
//  DIALTempStorage.h
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 3/12/17.
//  Copyright © 2017 Esposito, Timothy. All rights reserved.
//

@class DIALBroadcastObject;
@import Foundation;

@interface DIALTempStorage : NSObject

@property (nonatomic, strong) NSMutableArray<DIALBroadcastObject *> *tempStorage;

+ (instancetype)sharedStorage;

@end
