//
//  UIColor+hexColor.h
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 11/25/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

@import UIKit;

/**
 * A convenience method to load colors using hex values. This category is implemented by using the
 * Flyweight pattern to help reduce excessive object creation and string parsing, saving CPU and RAM in the process.
 *
 * \ingroup utilities
 */
@interface UIColor (hexValue)

/**
 * Fetches a color value using the specified hex value.
 * If a matching color could not be found, an exception is thrown.
 */
+ (UIColor *)colorWithHexValue:(NSString *)hexValue;

@end
