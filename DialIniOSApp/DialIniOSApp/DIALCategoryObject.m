//
//  DIALCategoryObject.m
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 10/22/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

#import "DIALCategoryObject.h"

@interface DIALCategoryObject ()

@property (nonatomic, strong) UIColor *color;

@end

@implementation DIALCategoryObject

- (UIColor *)backgroundColor {
    if (!self.color) {
        self.color = [[UIColor alloc] initWithRed:arc4random()%256/256.0
                                                     green:arc4random()%256/256.0
                                                      blue:arc4random()%256/256.0
                                                     alpha:1.0];
    }
    
    return self.color;
}

@end
