//
//  DIALBroadcastTableViewCell.m
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 11/12/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

@import AVFoundation;

#import "DIALBroadcastTableViewCell.h"
#import "DIALBroadcastObject.h"
#import "UIColor+hexValue.h"

@interface DIALBroadcastTableViewCell ()

/**
 * The profile image that ties a user to the broadcast
 */
@property (nonatomic, strong) UIImageView *userImageView;

/**
 * A short description of the broadcast
 */
@property (nonatomic, strong) UILabel *broadcastLabel;

@property (nonatomic, strong) UILabel *locationLabel;

/**
 * The view that visually shows the user the proximity of the broadcast
 */
@property (nonatomic, strong) UIView *proximityView;

/**
 * The ellipses button that is used to display more actions to take on the broadcast
 */
@property (nonatomic, strong) UIButton *ellipsesButton;

/**
 * The image that was just broadcasted
 */
@property (nonatomic, strong) UIImageView *broadcastImageView;

@property (nonatomic, strong) UILabel *usernameLabel;

@property (nonatomic, strong) UIView *mediaView;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIView *playerView;

@end

@implementation DIALBroadcastTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self setupViews];
        [self setupConstraints];
    }
    
    return self;
}

#pragma mark - Private methods

- (void)setupViews {
    self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.usernameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.usernameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];

    [self addSubview:self.usernameLabel];
    
    NSURL *userImageURL = [[NSURL alloc] initWithString:@"https://expertbeacon.com/sites/default/files/advice_for_men_on_selecting_your_online_dating_profile_photo.jpg"];
    NSData *userImageData = [[NSData alloc] initWithContentsOfURL:userImageURL];
    self.userImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:userImageData]];
    self.userImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.userImageView.layer.cornerRadius = 28;
    self.userImageView.layer.masksToBounds = YES;
    [self addSubview:self.userImageView];
    
    self.broadcastLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.broadcastLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.broadcastLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    [self addSubview:self.broadcastLabel];
    
    self.locationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.locationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.locationLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    [self addSubview:self.locationLabel];
    
    self.proximityView = [[UIView alloc] initWithFrame:CGRectZero];
    self.proximityView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.proximityView];
    
    self.ellipsesButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.ellipsesButton.tintColor = [UIColor blackColor];
    self.ellipsesButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.ellipsesButton setImage:[UIImage imageNamed:@"ellipses_icon"] forState:UIControlStateNormal];
    [self.ellipsesButton addTarget:self action:@selector(userDidTapEllipsesButton) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.ellipsesButton];
    
    self.mediaView = [[UIView alloc] initWithFrame:CGRectZero];
    self.mediaView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.mediaView];
}

- (void)setupConstraints {
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[_userImageView(56)]-[_usernameLabel]->=10-[_ellipsesButton]-16-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_usernameLabel, _userImageView, _ellipsesButton)]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[_userImageView(56)]-[_broadcastLabel]->=10-[_ellipsesButton]-16-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_broadcastLabel, _userImageView, _ellipsesButton)]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[_userImageView(56)]-[_locationLabel]->=10-[_ellipsesButton]-16-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_locationLabel, _userImageView, _ellipsesButton)]];
    
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-16-[_userImageView(56)]->=10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_userImageView)]];
    
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-16-[_usernameLabel]-2-[_broadcastLabel]-2-[_locationLabel]-10-[_mediaView(>=0)]-16-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_usernameLabel, _broadcastLabel, _locationLabel, _mediaView)]];
    
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-16-[_ellipsesButton]->=16-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_ellipsesButton)]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[_mediaView]-16-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_mediaView)]];
}

- (void)userDidTapEllipsesButton {
    [self.delegate userDidTapEllipsesButtonWithCell:self];
}

#pragma mark - Public methods

- (void)configureTableViewCellWithBroadcast:(DIALBroadcastObject *)broadcast {
    NSData *userImageData = [NSData dataWithContentsOfURL:broadcast.userProfileImageURL];
    UIImage *userImage = [UIImage imageWithData:userImageData];
    self.usernameLabel.text = broadcast.username;
    self.userImageView.image = userImage;
    self.broadcastLabel.text = [NSString stringWithFormat:@"\"%@\"", broadcast.broadcastString];
    self.locationLabel.text = broadcast.locationString;
    
    int randomNumber = 0 + arc4random() % (2-0);

    self.proximityView.backgroundColor = randomNumber == 0 ? [UIColor colorWithHexValue:@"63cc7a"] : [UIColor colorWithHexValue:@"cc6363"];
    
    if (broadcast.broadcastImageURL) {
        NSData *broadcastImageData = [NSData dataWithContentsOfURL:broadcast.broadcastImageURL];
        UIImage *broadcastImage = [UIImage imageWithData:broadcastImageData];
        self.broadcastImageView = [[UIImageView alloc] initWithImage:broadcastImage];
        self.broadcastImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.broadcastImageView.layer.cornerRadius = 2;
        self.broadcastImageView.layer.masksToBounds = YES;
        [self.mediaView addSubview:self.broadcastImageView];
        [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_broadcastImageView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_broadcastImageView)]];
        [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_broadcastImageView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_broadcastImageView)]];
        [NSLayoutConstraint activateConstraints:@[[NSLayoutConstraint constraintWithItem:self.broadcastImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.broadcastImageView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]]];
    }
    
    if (broadcast.broadcastData) {
        self.broadcastImageView
    }
}

@end
