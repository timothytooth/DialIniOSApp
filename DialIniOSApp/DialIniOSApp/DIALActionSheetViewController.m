//
//  DIALActionSheetViewController.m
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 11/19/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

#import "DIALActionSheetViewController.h"

@interface DIALActionSheetButton : UIButton

@end

@implementation DIALActionSheetButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setupViews];
        [self setupConstraints];
    }
    
    return self;
}

- (void)setupViews {
    self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.titleLabel.textColor = [UIColor blackColor];
}

- (void)setupConstraints {
}

@end

@interface DIALActionSheetViewController ()

/**
 * The stack view containing the buttons in the custom action sheet
 */
@property (nonatomic, strong) UIStackView *view;

/**
 * Reference to all the block handlers linked to menu buttons
 */
@property (nonatomic, strong) NSMutableArray *actions;

@end

@implementation DIALActionSheetViewController

/**
 * Dynamic as needed
 */
@dynamic view;

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [self setupViews];
    }
    
    return self;
}

- (void)setupViews {
    self.view = [[UIStackView alloc] initWithFrame:CGRectZero];
    self.view.axis = UILayoutConstraintAxisVertical;
    self.view.distribution = UIStackViewDistributionFillEqually;
    self.view.spacing = 0;
    
    self.actions = [NSMutableArray array];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)addButtonWithName:(NSString *)name action:(void (^)())action {
    DIALActionSheetButton *actionSheetButton = [[DIALActionSheetButton alloc] initWithFrame:CGRectZero];
    [actionSheetButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [actionSheetButton setTitle:name forState:UIControlStateNormal];
    actionSheetButton.backgroundColor = [UIColor whiteColor];
    [actionSheetButton addTarget:self action:@selector(userDidTapButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if (action) {
        [self.actions addObject:action];
    }
    
    [self.view addArrangedSubview:actionSheetButton];
}

- (void)userDidTapButton:(id)sender {
    NSUInteger buttonIndex = [self.view.arrangedSubviews indexOfObject:sender];
    void (^handlerBlock)() = nil;
    
    [self dismissViewControllerAnimated:YES completion:handlerBlock];
}

@end
