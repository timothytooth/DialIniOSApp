//
//  DIALActionSheetAnimator.h
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 5/20/15.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

@import UIKit;

/**
 * This animator handles transition animation for the action sheet
 */
@interface DIALActionSheetAnimator : NSObject <UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate>

/**
 * This indicates whether this animator is working on presenting the next view controller
 */
@property (nonatomic, assign, getter=isPresenting) BOOL presenting;

/**
 * The action sheet height
 */
@property (nonatomic) CGFloat actionSheetHeight;

@end
