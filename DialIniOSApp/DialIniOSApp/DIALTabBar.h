//
//  DIALTabBar.h
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 12/26/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

@import UIKit;

@protocol DIALTabBarDelegate

/**
 * The method called when the user taps on the broadcast button
 */
- (void)userDidTapBroadcastButton;

/**
 * The method called when the user taps on the discover button
 */
- (void)userDidTapDiscoverButton;

/**
 * The method called when the user touches down on the photo button
 */
- (void)userDidTouchDownPhotoButton;

/**
 * The method called when the user touches up inside the photo button
 */
- (void)userDidTouchUpInsidePhotoButton;

/**
 * The method called when the user taps on the friend button
 */
- (void)userDidTapFriendButton;

/**
 * The method called when the user taps on the profile button
 */
- (void)userDidTapProfileButton;

@end

@interface DIALTabBar : UIView

/**
 * The delegate
 */
@property (nonatomic) id<DIALTabBarDelegate> delegate;

/**
 *
 */
- (void)setLayoutConstraintConstantsWithProgress:(CGFloat)progress forward:(BOOL)forward;

- (void)selectBroadcastButton;

- (void)selectDiscoverButton;

- (void)selectPhotoButton;

- (void)selectFriendButton;

- (void)selectProfileButton;

- (void)animateButtonsFromView;

@end
