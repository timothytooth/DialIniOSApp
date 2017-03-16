//
//  DIALRootPageViewController.m
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 10/29/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

#import "DIALRootPageViewController.h"
#import "DIALMainCollectionViewController.h"
#import "DIALCollectionViewFloatLayout.h"
#import "DIALTestTableViewController.h"
#import "DIALBroadcastTableViewController.h"
#import "DIALFriendViewController.h"
#import "DIALProfileViewController.h"
#import "AVCamCameraViewController.h"

@interface DIALRootPageViewController () <UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIScrollViewDelegate>

/**
 * The array of all view controllers to be displayed
 */
@property (nonatomic,strong) NSArray<UIViewController *> *viewControllersArray;

/**
 *
 */
@property (nonatomic, getter=isPhotoTransitioning) BOOL photoTransitioning;

/**
 *
 */
@property (nonatomic) BOOL forward;

@property (nonatomic) BOOL movingToPhoto;

@property (nonatomic) NSUInteger cameraViewControllerIndex;

@property (nonatomic, readwrite, strong) AVCamCameraViewController *cameraViewController;

@end

@implementation DIALRootPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.delegate = self;
    self.dataSource = self;
    
    [self.view.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
        if ([subview isKindOfClass:[UIScrollView class]]) {
            ((UIScrollView *)subview).delegate = self;
        }
    }];
    
    DIALBroadcastTableViewController *broadcastTableViewController = [[DIALBroadcastTableViewController alloc] initWithStyle:UITableViewStylePlain];
    
    DIALCollectionViewFloatLayout *floatLayout = [[DIALCollectionViewFloatLayout alloc] init];
    
    DIALMainCollectionViewController *mainCollectionViewController = [[DIALMainCollectionViewController alloc] initWithCollectionViewLayout:floatLayout];
    
    self.cameraViewController = [[AVCamCameraViewController alloc] init];

    DIALFriendViewController *friendViewController = [[DIALFriendViewController alloc] init];
    
    DIALProfileViewController *profileViewController = [[DIALProfileViewController alloc] init];
    
    self.viewControllersArray = @[broadcastTableViewController, mainCollectionViewController, self.cameraViewController, friendViewController, profileViewController];
    
    self.cameraViewControllerIndex = [self.viewControllersArray indexOfObject:self.cameraViewController];
    
    [self setViewControllers:@[ self.viewControllersArray[0] ] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    return [self.viewControllersArray objectAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSUInteger index = [self.viewControllersArray indexOfObject:viewController];
    if (index == 0 || index == NSNotFound) {
        return nil;
    }
    
    index--;
    
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger index = [self.viewControllersArray indexOfObject:viewController];
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == self.viewControllersArray.count) {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers {
    self.photoTransitioning = YES;
    
    UIViewController *currentViewController = pageViewController.viewControllers.firstObject;
    UIViewController *pendingViewController = pendingViewControllers.firstObject;
    if ([currentViewController isKindOfClass:[AVCamCameraViewController class]] || [pendingViewController isKindOfClass:[AVCamCameraViewController class]]) {
        self.movingToPhoto = YES;
        
        self.forward = [self.viewControllersArray indexOfObject:pendingViewController] == self.cameraViewControllerIndex;
    } else {
        self.movingToPhoto = NO;
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    self.photoTransitioning = NO;
    
    [self.rootPageViewControllerDelegate pageViewController:self transitionCompletedWithPageIndex:[self.viewControllersArray indexOfObject:self.viewControllers.firstObject]];
}

#pragma mark - Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint contentOffset = scrollView.contentOffset;
    CGFloat percentComplete = fabs(contentOffset.x - self.view.frame.size.width) / self.view.frame.size.width;
    if (self.isPhotoTransitioning && self.movingToPhoto) {
        [self.rootPageViewControllerDelegate pageViewController:self photoTransitioningWithProgress:percentComplete forward:self.forward];
        NSLog(@"percentComplete: %f", percentComplete);
    }
}

- (BOOL)isPhotoViewControllerPresenting {
    return self.cameraViewControllerIndex == [self.viewControllersArray indexOfObject:self.viewControllers.firstObject];
}

- (void)navigateToPageWithIndex:(NSUInteger)index {
    UIViewController *viewController = [self.viewControllersArray objectAtIndex:index];
    
    [self setViewControllers:@[viewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
}

@end
