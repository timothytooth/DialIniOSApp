//
//  DIALBroadcastFormView.m
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 11/25/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

#import "DIALBroadcastFormView.h"
#import "UIColor+hexValue.h"

@interface DIALBroadcastFormView ()

/**
 * The button to add a photo to a broadcast
 */
@property (nonatomic, strong) UIButton *photoButton;

/**
 * The okay button
 */
@property (nonatomic, strong) UIButton *okayButton;

@end

@implementation DIALBroadcastFormView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setupViews];
        [self setupConstraints];
    }
    
    return self;
}

- (void)setupViews {
    self.backgroundColor = [UIColor colorWithHexValue:@"5483ce"];
    self.photoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.photoButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.photoButton setImage:[UIImage imageNamed:@"photo_icon"] forState:UIControlStateNormal];
    self.photoButton.tintColor = [UIColor whiteColor];
    [self addSubview:self.photoButton];
    
    self.okayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.okayButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.okayButton setImage:[UIImage imageNamed:@"okay_icon"] forState:UIControlStateNormal];
    self.okayButton.tintColor = [UIColor whiteColor];
    [self addSubview:self.okayButton];
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    self.textField.placeholder = @"What do you want to broadcast live?";
    self.textField.layer.cornerRadius = 2;
    self.textField.layer.masksToBounds = YES;
    self.textField.backgroundColor = [UIColor whiteColor];
    self.textField.layer.cornerRadius = 20;
    [self addSubview:self.textField];
}

- (void)setupConstraints {
    NSDictionary *views = NSDictionaryOfVariableBindings(_photoButton, _textField, _okayButton);
    NSArray *constraints = @[[NSLayoutConstraint constraintWithItem:self.textField attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0], [NSLayoutConstraint constraintWithItem:self.photoButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0], [NSLayoutConstraint constraintWithItem:self.okayButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [NSLayoutConstraint activateConstraints:constraints];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_textField]-[_photoButton(30)]-[_okayButton(30)]-|" options:0 metrics:nil views:views]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_photoButton(30)]" options:0 metrics:nil views:views]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_okayButton(30)]" options:0 metrics:nil views:views]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_textField]-|" options:0 metrics:nil views:views]];
}

@end
