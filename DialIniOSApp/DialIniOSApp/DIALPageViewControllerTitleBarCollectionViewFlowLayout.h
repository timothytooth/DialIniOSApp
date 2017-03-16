//
//  DIALPageViewControllerTitleBarCollectionViewFlowLayout.h
//  DialIn
//
//  Created by Esposito, Timothy on 8/11/15.
//  Copyright (c) 2015 Audible, Inc. All rights reserved.
//
@import UIKit;

/**
 * Displays a line underneath the selected cell in the title bar collection view inside of Discover
 */
@interface DIALPageViewControllerTitleBarCollectionViewFlowLayout : UICollectionViewFlowLayout

/**
 * Index path of the selected cell used to determine where to draw line
 */
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end
