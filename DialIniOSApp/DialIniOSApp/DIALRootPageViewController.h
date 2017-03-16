//
//  DIALRootPageViewController.h
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 10/29/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

@class AVCamCameraViewController;

@import UIKit;

@protocol DIALRootPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController photoTransitioningWithProgress:(CGFloat)progress forward:(BOOL)forward;

- (void)pageViewController:(UIPageViewController *)pageViewController transitionCompletedWithPageIndex:(NSUInteger)pageIndex;

@end

@interface DIALRootPageViewController : UIPageViewController

@property (nonatomic, readonly, getter=isPhotoViewControllerPresenting) BOOL photoViewControllerPresenting;

/**
 * The delegate
 */
@property (nonatomic, weak) id<DIALRootPageViewControllerDelegate> rootPageViewControllerDelegate;

/**
 * The camera view controller
 */
@property (nonatomic, readonly, strong) AVCamCameraViewController *cameraViewController;

/**
 * This method navigates the page view controller to the page for a given index
 */
- (void)navigateToPageWithIndex:(NSUInteger)index;

@end
