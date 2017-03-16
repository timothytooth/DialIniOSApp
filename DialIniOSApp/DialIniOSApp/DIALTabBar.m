//
//  DIALTabBar.m
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 12/26/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

#import "DIALTabBar.h"

@interface DIALTabBar ()

/**
 * The stack view
 */
@property (nonatomic, strong) UIStackView *stackView;

@property (nonatomic, strong) UIButton *broadcastButton;

@property (nonatomic, strong) UIButton *discoverButton;

@property (nonatomic, strong) UIButton *friendButton;

@property (nonatomic, strong) UIButton *profileButton;

@property (nonatomic, strong) UIButton *photoButton;

@property (nonatomic, weak) NSLayoutConstraint *leadingConstraint;

@property (nonatomic, weak) UIButton *selectedButton;

/**
 *
 */
@property (nonatomic, weak) NSLayoutConstraint *trailingConstraint;

@end

@implementation DIALTabBar

/**
 *
 */
static const CGFloat DIALTabBarLeadingConstantStart = 40;

/**
 *
 */
static const CGFloat DIALTabBarLeadingConstantEnd = -240;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setupViews];
        [self setupConstraints];
    }
    
    return self;
}

- (void)setupViews {
    UIImage *broadcastImage = [UIImage imageNamed:@"broadcast_icon"];
    self.broadcastButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.broadcastButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.broadcastButton setImage:broadcastImage forState:UIControlStateNormal];
    [self.broadcastButton addTarget:self action:@selector(userDidTapBroadcastButton) forControlEvents:UIControlEventTouchUpInside];

    UIImage *discoverImage = [UIImage imageNamed:@"discover_icon"];
    self.discoverButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.discoverButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.discoverButton setImage:discoverImage forState:UIControlStateNormal];
    [self.discoverButton addTarget:self action:@selector(userDidTapDiscoverButton) forControlEvents:UIControlEventTouchUpInside];

    UIImage *friendImage = [UIImage imageNamed:@"friend_icon"];
    self.friendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.friendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.friendButton setImage:friendImage forState:UIControlStateNormal];
    [self.friendButton addTarget:self action:@selector(userDidTapFriendButton) forControlEvents:UIControlEventTouchUpInside];

    UIImage *profileImage = [UIImage imageNamed:@"profile_icon"];
    self.profileButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.profileButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.profileButton setImage:profileImage forState:UIControlStateNormal];
    [self.profileButton addTarget:self action:@selector(userDidTapProfileButton) forControlEvents:UIControlEventTouchUpInside];

    UIImage *photoImage = [self imageWithImage:[UIImage imageNamed:@"photo_action"] scaledToSize:CGSizeMake(48, 48)];
    self.photoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.photoButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.photoButton setImage:photoImage forState:UIControlStateNormal];
    self.photoButton.tintColor = [UIColor lightGrayColor];
    [self.photoButton addTarget:self action:@selector(userDidTouchDownPhotoButton) forControlEvents:UIControlEventTouchDown];
    [self.photoButton addTarget:self action:@selector(userDidTouchUpInsidePhotoButton) forControlEvents:UIControlEventTouchUpInside];
    
    self.stackView = [[UIStackView alloc] initWithFrame:CGRectZero];
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.alignment = UIStackViewAlignmentBottom;
    self.stackView.distribution = UIStackViewDistributionEqualCentering;
    self.stackView.axis = UILayoutConstraintAxisHorizontal;
    
    [self.stackView addArrangedSubview:self.broadcastButton];
    [self.stackView addArrangedSubview:self.discoverButton];
    [self.stackView addArrangedSubview:self.photoButton];
    [self.stackView addArrangedSubview:self.friendButton];
    [self.stackView addArrangedSubview:self.profileButton];
    
    [self addSubview:self.stackView];
}

- (void)setupConstraints {
    self.leadingConstraint = [NSLayoutConstraint constraintWithItem:self.stackView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:DIALTabBarLeadingConstantStart];
    
    self.trailingConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.stackView attribute:NSLayoutAttributeTrailing multiplier:1 constant:DIALTabBarLeadingConstantStart];
    
    [NSLayoutConstraint activateConstraints:@[self.leadingConstraint, self.trailingConstraint]];
    
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_stackView]-16-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_stackView)]];
}

- (UIImage*)imageWithImage:(UIImage*)image
              scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)animateSelectedStateForButton:(UIButton *)button {
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        button.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:nil];
}

- (void)animateUnselectedStateForButton:(UIButton *)button {
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        button.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:nil];
}

- (void)selectBroadcastButton {
    [self animateUnselectedStateForButton:self.selectedButton];
    self.selectedButton = self.broadcastButton;
    [self animateSelectedStateForButton:self.selectedButton];
}

- (void)selectDiscoverButton {
    [self animateUnselectedStateForButton:self.selectedButton];
    self.selectedButton = self.discoverButton;
    [self animateSelectedStateForButton:self.selectedButton];
}

- (void)selectPhotoButton {
    [self animateUnselectedStateForButton:self.selectedButton];
    self.selectedButton = nil;
}

- (void)selectFriendButton {
    [self animateUnselectedStateForButton:self.selectedButton];
    self.selectedButton = self.friendButton;
    [self animateSelectedStateForButton:self.selectedButton];
}

- (void)selectProfileButton {
    [self animateUnselectedStateForButton:self.selectedButton];
    self.selectedButton = self.profileButton;
    [self animateSelectedStateForButton:self.selectedButton];
}

- (void)userDidTapBroadcastButton {
    [self selectBroadcastButton];
    
    [self.delegate userDidTapBroadcastButton];
}

- (void)userDidTapDiscoverButton {
    [self selectDiscoverButton];
    
    [self.delegate userDidTapDiscoverButton];
}

- (void)userDidTouchDownPhotoButton {
    [self.delegate userDidTouchDownPhotoButton];
}

- (void)userDidTouchUpInsidePhotoButton {
    [self selectPhotoButton];
    
    [self.delegate userDidTouchUpInsidePhotoButton];
}

- (void)userDidTapFriendButton {
    [self selectFriendButton];
    
    [self.delegate userDidTapFriendButton];
}

- (void)userDidTapProfileButton {
    [self selectProfileButton];
    
    [self.delegate userDidTapProfileButton];
}

- (void)setLayoutConstraintConstantsWithProgress:(CGFloat)progress forward:(BOOL)forward {
    CGFloat newConstant;
    if (forward) {
        newConstant = DIALTabBarLeadingConstantStart - ((DIALTabBarLeadingConstantStart - DIALTabBarLeadingConstantEnd) * progress);
    } else {
        newConstant = DIALTabBarLeadingConstantEnd + ((DIALTabBarLeadingConstantStart - DIALTabBarLeadingConstantEnd) * progress);
    }
    
    self.leadingConstraint.constant = newConstant;
    self.trailingConstraint.constant = newConstant;
    
    [self layoutIfNeeded];
}

- (void)animateButtonsFromView {
    self.leadingConstraint.constant = DIALTabBarLeadingConstantEnd;
    self.trailingConstraint.constant = DIALTabBarLeadingConstantEnd;
    
    [UIView animateWithDuration:0.4 animations:^{
        [self layoutIfNeeded];
    }];
}

@end
