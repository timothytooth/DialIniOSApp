//
//  DIALBroadcastTableViewController.m
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 11/12/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

#import "DIALBroadcastTableViewController.h"
#import "DIALBroadcastObject.h"
#import "DIALBroadcastTableViewCell.h"
#import "DIALActionSheetViewController.h"
#import "DIALActionSheetAnimator.h"
#import "DIALTempStorage.h"

@interface DIALBroadcastTableViewController () <DIALBroadcastTableViewCellDelegate>

/**
 * The list of broadcasts
 */
@property (nonatomic, strong) NSArray<DIALBroadcastObject *> *broadcasts;

@property (nonatomic, strong) DIALActionSheetAnimator *actionSheetAnimator;

@end

@implementation DIALBroadcastTableViewController

static const CGFloat DIALBroadcastTableViewCellSeparatorInset = 8;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.actionSheetAnimator = [[DIALActionSheetAnimator alloc] init];
    self.actionSheetAnimator.actionSheetHeight = 200;
    
    self.tableView.contentInset = UIEdgeInsetsMake(UIApplication.sharedApplication.statusBarFrame.size.height, 0, 0, 0);
    
    [self.tableView registerClass:[DIALBroadcastTableViewCell class] forCellReuseIdentifier:DIALBroadcastTableViewCellIdentifier];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 180;
    
    // This is the way to remove the line separators between empty cells
    self.tableView.tableFooterView = [UIView new];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, DIALBroadcastTableViewCellSeparatorInset, 0, DIALBroadcastTableViewCellSeparatorInset);
    
    DIALBroadcastObject *firstBroadcast = [[DIALBroadcastObject alloc] init];
    [firstBroadcast setPropertiesWithUsername:@"everday_joe12" userProfileImageURL:@"https://static1.squarespace.com/static/50de3e1fe4b0a05702aa9cda/t/50eb2245e4b0404f3771bbcb/1357589992287/ss_profile.jpg" broadcast:@"Come chill with the cool kids!" location:@"The Charter House" broadcastData:nil];
    
    DIALBroadcastObject *secondBroadcast = [[DIALBroadcastObject alloc] init];
    [secondBroadcast setPropertiesWithUsername:@"dirtbag_zuckerberg" userProfileImageURL:@"https://static1.squarespace.com/static/50de3e1fe4b0a05702aa9cda/t/50eb2245e4b0404f3771bbcb/1357589992287/ss_profile.jpg" broadcast:@"Coding up an epic storm" location:@"Facebook HQ" broadcastData:nil];
    
    DIALBroadcastObject *thirdBroadcast = [[DIALBroadcastObject alloc] init];
    [thirdBroadcast setPropertiesWithUsername:@"kimberly69" userProfileImageURL:@"https://assets.entrepreneur.com/content/16x9/822/20150406145944-dos-donts-taking-perfect-linkedin-profile-picture-selfie-mobile-camera-2.jpeg" broadcast:@"Twerk team Tuesday" location:@"Mill's Tavern" broadcastData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://assets.entrepreneur.com/content/16x9/822/20150406145944-dos-donts-taking-perfect-linkedin-profile-picture-selfie-mobile-camera-2.jpeg"]]];

    
    self.broadcasts = @[firstBroadcast, secondBroadcast, thirdBroadcast];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.broadcasts = [self.broadcasts arrayByAddingObjectsFromArray:[[DIALTempStorage sharedStorage].tempStorage copy]];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.broadcasts.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DIALBroadcastTableViewCell *broadcastTableViewCell = [tableView dequeueReusableCellWithIdentifier:DIALBroadcastTableViewCellIdentifier forIndexPath:indexPath];
    broadcastTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
    broadcastTableViewCell.contentView.userInteractionEnabled = NO;
    [broadcastTableViewCell configureTableViewCellWithBroadcast:self.broadcasts[indexPath.row]];
    broadcastTableViewCell.delegate = self;
    
    return broadcastTableViewCell;
}

#pragma mark - DIALBroadcastTableViewCellDelegate methods

- (void)userDidTapEllipsesButtonWithCell:(UITableViewCell *)cell {
    DIALActionSheetViewController *actionSheetViewController = [[DIALActionSheetViewController alloc] init];
    actionSheetViewController.modalPresentationStyle = UIModalPresentationCustom;
    actionSheetViewController.transitioningDelegate = self.actionSheetAnimator;
    
    [actionSheetViewController addButtonWithName:@"View details" action:nil];
    [actionSheetViewController addButtonWithName:@"Share" action:nil];
    [actionSheetViewController addButtonWithName:@"Message" action:nil];
    
    [self presentViewController:actionSheetViewController animated:YES completion:nil];
}

@end
