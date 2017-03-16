//
//  ABMKSharingPaneAnimator.m
//  Audible
//
//  Created by Esposito, Timothy on 5/20/15.
//  Copyright (c) 2015 Audible, Inc. All rights reserved.
//

#import "DIALActionSheetAnimator.h"

@interface DIALActionSheetAnimator ()

/**
 * A view to display as a fading overlay
 */
@property (nonatomic, strong) UIView *fadeOverlayView;

/**
 * The view controller that is currently being displayed
 */
@property (nonatomic, weak) UIViewController *displayedViewController;

@end

@implementation DIALActionSheetAnimator

/**
 *
 */
static const CGFloat DIALActionSheetWidthIPad = 200;

/**
 *
 */
static const NSTimeInterval DIALActionSheetAnimatorTransitionDuration = 0.4;

#pragma mark - Private API

- (CGRect)rectForDismissedState:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = [transitionContext containerView];

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIViewController *fromViewController;
        CGFloat containerViewHeight = CGRectGetHeight(containerView.bounds);
        CGFloat containerViewWidth = CGRectGetWidth(containerView.bounds);

        if (self.presenting) {
            fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        } else {
            fromViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        }


        switch (fromViewController.interfaceOrientation) {
            case UIInterfaceOrientationLandscapeRight: {
                return CGRectMake(-containerViewWidth, (containerViewHeight - self.actionSheetHeight) / 2, DIALActionSheetWidthIPad, self.actionSheetHeight);
            }
            case UIInterfaceOrientationLandscapeLeft: {
                return CGRectMake(containerViewWidth, (containerViewHeight - self.actionSheetHeight) / 2, DIALActionSheetWidthIPad, self.actionSheetHeight);
            }
            case UIInterfaceOrientationPortraitUpsideDown: {
                return CGRectMake((containerViewWidth - DIALActionSheetWidthIPad) / 2, containerViewHeight, DIALActionSheetWidthIPad, self.actionSheetHeight);
            }
            case UIInterfaceOrientationPortrait: {
                return CGRectMake((containerViewWidth - DIALActionSheetWidthIPad) / 2, containerViewHeight, DIALActionSheetWidthIPad, self.actionSheetHeight);
            }
            default: {
                return CGRectZero;
            }
        }
    } else {
        return CGRectMake(0, CGRectGetHeight(containerView.bounds), CGRectGetWidth(containerView.bounds), self.actionSheetHeight);
    }
}

- (CGRect)rectForPresentedState:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = [transitionContext containerView];

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIViewController *fromViewController;
        CGFloat containerViewHeight = CGRectGetHeight(containerView.bounds);
        CGFloat containerViewWidth = CGRectGetWidth(containerView.bounds);

        if (self.presenting) {
            fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        } else {
            fromViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        }

        switch (fromViewController.interfaceOrientation) {
            case UIInterfaceOrientationLandscapeRight:
            case UIInterfaceOrientationLandscapeLeft: {
                return CGRectMake((DIALActionSheetWidthIPad / 2), (containerViewHeight - self.actionSheetHeight) / 2, DIALActionSheetWidthIPad, self.actionSheetHeight);
            }
            case UIInterfaceOrientationPortraitUpsideDown:
            case UIInterfaceOrientationPortrait: {
                return CGRectMake((containerViewWidth - DIALActionSheetWidthIPad) / 2, (containerViewHeight - self.actionSheetHeight) / 2, DIALActionSheetWidthIPad, self.actionSheetHeight);
            }
            default: {
                return CGRectZero;
            }
        }
    } else {
        return CGRectMake(0, CGRectGetHeight(containerView.bounds) - self.actionSheetHeight, CGRectGetWidth(containerView.bounds), self.actionSheetHeight);
    }
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController __unused *)presenting sourceController:(UIViewController __unused *)source {
    self.presenting = YES;
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController __unused *)dismissed {
    self.presenting = NO;
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning> __unused)transitionContext {
    return DIALActionSheetAnimatorTransitionDuration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    if (self.isPresenting) {
        [self presentViewController:transitionContext];
    } else {
        [self dismissViewController:transitionContext];
    }
}

- (void)userDidTapFadeOverlay {
    [self.displayedViewController dismissViewControllerAnimated:YES completion:nil];
    self.displayedViewController = nil;
}

- (void)presentViewController:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = transitionContext.containerView;

    UIView *toView = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey].view;

    UIColor *initialFade = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    UIColor *finalFade = [[UIColor blackColor] colorWithAlphaComponent:0.5];

    self.displayedViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    CGRect initialFrame = [self rectForDismissedState:transitionContext];
    CGRect finalFrame = [self rectForPresentedState:transitionContext];

    toView.frame = initialFrame;

    self.fadeOverlayView = [[UIView alloc] initWithFrame:containerView.bounds];
    self.fadeOverlayView.backgroundColor = initialFade;
    [self.fadeOverlayView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapFadeOverlay)]];

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        toView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

        toView.layer.cornerRadius = 6;
        toView.layer.masksToBounds = YES;

        self.fadeOverlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    } else {
        toView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }

    [containerView addSubview:self.fadeOverlayView];
    [containerView addSubview:toView];

    typeof(self) __weak weakSelf = self;

    [UIView animateWithDuration:[self transitionDuration:transitionContext]
        animations:^{
                         toView.frame = finalFrame;
                         weakSelf.fadeOverlayView.backgroundColor = finalFade;
        }
        completion:^(BOOL __unused finished) {
                         [transitionContext completeTransition:YES];
        }];
}

- (void)dismissViewController:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *fromView = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey].view;

    UIColor *initialFade = [[UIColor blackColor] colorWithAlphaComponent:0];

    self.displayedViewController = nil;

    CGRect initialFrame = [self rectForDismissedState:transitionContext];

    typeof(self) __weak weakSelf = self;

    [UIView animateWithDuration:[self transitionDuration:transitionContext]
        animations:^{
                         fromView.frame = initialFrame;
                         weakSelf.fadeOverlayView.backgroundColor = initialFade;
        }
        completion:^(BOOL __unused finished) {
                         [transitionContext completeTransition:YES];
                         [fromView removeFromSuperview];
                         [weakSelf.fadeOverlayView removeFromSuperview];
        }];
}

- (void)animationEnded:(BOOL __unused)transitionCompleted {
    self.presenting = NO;
}

@end
