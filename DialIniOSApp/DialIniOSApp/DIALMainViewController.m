//
//  DIALMainViewController.m
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 11/25/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

#import "DIALMainViewController.h"
#import "DIALRootPageViewController.h"
#import "DIALBroadcastFormView.h"
#import "DIALTabBar.h"
#import "AVCamCameraViewController.h"

@interface DIALMainViewController () <UITextFieldDelegate, DIALTabBarDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, DIALRootPageViewControllerDelegate, AVCamCameraViewControllerProtocol>

/**
 * The root
 */
@property (nonatomic, strong) DIALRootPageViewController *rootPageViewController;

/**
 *
 */
@property (nonatomic, strong) UIView *rootPageView;

/**
 *
 */
@property (nonatomic, strong) DIALBroadcastFormView *broadcastFormView;


@property (nonatomic, strong) DIALTabBar *tabBar;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation DIALMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.rootPageViewController = [[DIALRootPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.rootPageViewController.rootPageViewControllerDelegate = self;
    self.rootPageView = self.rootPageViewController.view;
    self.rootPageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.rootPageView];
    
    self.tabBar = [[DIALTabBar alloc] initWithFrame:CGRectZero];
    self.tabBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.tabBar.delegate = self;
    
    [self.view addSubview:self.tabBar];
    
    [self.tabBar selectBroadcastButton];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_rootPageView, _tabBar);
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_rootPageView]|" options:0 metrics:nil views:views]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_rootPageView]|" options:0 metrics:nil views:views]];
    
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|->=0-[_tabBar(60)]|" options:0 metrics:nil views:views]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_tabBar]|" options:0 metrics:nil views:views]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.rootPageViewController.cameraViewController.delegate = self;
}

- (void)userDidCaptureMedia {
    
}

- (UIImage *)imageWithImage:(UIImage*)image
              scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)userDidTapBroadcastButton {
    [self.rootPageViewController navigateToPageWithIndex:0];
}

- (void)userDidTapDiscoverButton {
    [self.rootPageViewController navigateToPageWithIndex:1];
}

- (void)userDidTouchDownPhotoButton {
    if (self.rootPageViewController.photoViewControllerPresenting) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:NO block:^(NSTimer __unused *timer) {
            [self.rootPageViewController.cameraViewController recordVideo];
        }];
    }
}

- (void)userDidTouchUpInsidePhotoButton {
    if (self.rootPageViewController.photoViewControllerPresenting) {
        if (self.timer) {
            [self.timer invalidate];
            self.timer = nil;
            
            if (self.rootPageViewController.cameraViewController.isRecording) {
                [self.rootPageViewController.cameraViewController stopRecordingVideo];
            } else {
                [self.rootPageViewController.cameraViewController capturePhoto];
                self.tabBar.hidden = YES;
            }
        } else {
            [self.rootPageViewController.cameraViewController capturePhoto];
            self.tabBar.hidden = YES;
        }
    } else {
        [self.tabBar animateButtonsFromView];
        [self.rootPageViewController navigateToPageWithIndex:2];
    }
}

- (void)userDidTapFriendButton {
    [self.rootPageViewController navigateToPageWithIndex:3];
}

- (void)userDidTapProfileButton {
    [self.rootPageViewController navigateToPageWithIndex:4];
}

- (void)pageViewController:(UIPageViewController *)pageViewController photoTransitioningWithProgress:(CGFloat)progress forward:(BOOL)forward {
    [self.tabBar setLayoutConstraintConstantsWithProgress:progress forward:forward];
}

- (void)pageViewController:(UIPageViewController *)pageViewController transitionCompletedWithPageIndex:(NSUInteger)pageIndex {
    switch (pageIndex) {
        case 0:
            [self.tabBar selectBroadcastButton];
            break;
        case 1:
            [self.tabBar selectDiscoverButton];
            break;
        case 2:
            [self.tabBar selectPhotoButton];
            break;
        case 3:
            [self.tabBar selectFriendButton];
            break;
        case 4:
            [self.tabBar selectProfileButton];
            break;
        default:
            break;
    }
}

@end
