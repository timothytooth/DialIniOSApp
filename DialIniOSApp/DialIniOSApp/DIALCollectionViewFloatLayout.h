//
//  DIALCollectionViewFloatLayout.h
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 10/23/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

@import UIKit;

/**
 * The collection view layout 
 */
@protocol DIALCollectionViewFloatLayoutDelegate

/**
 * The the preferred height of most items in the collection view. Some items will receive half of this height at the smallest.
 */
- (CGFloat)preferredItemHeight;

@end

@interface DIALCollectionViewFloatLayout : UICollectionViewLayout

/**
 * The delegate
 */
@property (nonatomic, weak) id<DIALCollectionViewFloatLayoutDelegate> delegate;

@end
