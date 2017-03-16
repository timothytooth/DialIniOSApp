//
//  UIColor+hexColor.m
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 11/25/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

#import "UIColor+hexValue.h"

NSUInteger hexDigit(char digit);

@implementation UIColor (hexValue)

static NSCache *colorCache;

+ (void)initialize {
    colorCache = [[NSCache alloc] init];
    // Assign name of cache
    colorCache.name = @"AMZNColorCache";
}

+ (UIColor *)colorWithHexValue:(NSString *)hexValue {
    NSAssert([hexValue length] == 6, @"Hex value should be exactly 6 characters long");
    
    // check if we already have an existing color object in cache
    UIColor *cachedColor = [colorCache objectForKey:hexValue];
    if (cachedColor) {
        // if so, lets simply return it
        return cachedColor;
    }
    
    CGFloat red = (hexDigit([hexValue characterAtIndex:0]) * 16 + hexDigit([hexValue characterAtIndex:1])) / 255.0;
    CGFloat green = (hexDigit([hexValue characterAtIndex:2]) * 16 + hexDigit([hexValue characterAtIndex:3])) / 255.0;
    CGFloat blue = (hexDigit([hexValue characterAtIndex:4]) * 16 + hexDigit([hexValue characterAtIndex:5])) / 255.0;
    
    UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    
    // store the newly created color object in a cache so we can reuse it.
    [colorCache setObject:color forKey:hexValue];
    
    return color;
}

@end

NSUInteger hexDigit(char digit) {
    if (digit >= '0' && digit <= '9') {
        return digit - '0';
    } else if (digit >= 'a' && digit <= 'z') {
        return digit - 'a' + 10;
    } else if (digit >= 'A' && digit <= 'Z') {
        return digit - 'A' + 10;
    }
    
    NSCAssert(NO, @"Please specify a valid hex character"); // Illegal value
    return 0;
}
