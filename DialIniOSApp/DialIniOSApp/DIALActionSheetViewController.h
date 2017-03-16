//
//  DIALActionSheetViewController.h
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 11/19/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

@import UIKit;

@interface DIALActionSheetViewController : UIViewController

- (void)addButtonWithName:(NSString *)name action:(void (^)())action;

@end
