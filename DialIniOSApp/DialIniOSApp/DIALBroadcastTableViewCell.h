//
//  DIALBroadcastTableViewCell.h
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 11/12/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

@import UIKit;

@class DIALBroadcastObject;
static NSString *DIALBroadcastTableViewCellIdentifier = @"DIALBroadcastTableViewCellIdentifier";

@protocol DIALBroadcastTableViewCellDelegate

/**
 * The delegate callback when the user taps on the ellipses button
 */
- (void)userDidTapEllipsesButtonWithCell:(UITableViewCell *)cell;

@end

@interface DIALBroadcastTableViewCell : UITableViewCell

/**
 * The delegate
 */
@property (nonatomic, weak) id<DIALBroadcastTableViewCellDelegate> delegate;

- (void)configureTableViewCellWithBroadcast:(DIALBroadcastObject *)broadcast;

@end
