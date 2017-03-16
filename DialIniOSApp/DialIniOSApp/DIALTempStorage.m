//
//  DIALTempStorage.m
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 3/12/17.
//  Copyright © 2017 Esposito, Timothy. All rights reserved.
//

#import "DIALTempStorage.h"
#import "DIALBroadcastObject.h"

@implementation DIALTempStorage

+ (instancetype)sharedStorage {
    static DIALTempStorage *tempStorage;
    
    if (!tempStorage) {
        tempStorage = [[DIALTempStorage alloc] init];
        tempStorage.tempStorage = [NSMutableArray array];
    }
    
    return tempStorage;
}

@end
