//
//  DIALCollectionViewFloatLayout.m
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 10/23/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

#import "DIALCollectionViewFloatLayout.h"

@interface DIALCollectionViewFloatLayout ()

/**
 * The content size
 */
@property (nonatomic) CGSize contentSize;

/**
 * The layout attributes array
 */
@property (nonatomic, strong) NSArray<UICollectionViewLayoutAttributes *> *layoutAttributesCache;

@end

@implementation DIALCollectionViewFloatLayout

- (void)prepareLayout {
    if (!self.layoutAttributesCache.count) {
        self.layoutAttributesCache = [NSArray array];
        
        CGFloat width = 0;
        CGFloat height = 0;
    
        CGFloat yOffsetArray[2];

        for (NSInteger item = 0; item < [self.collectionView numberOfItemsInSection:0]; item++) {
            NSInteger xOffset = 0;
            NSInteger yOffset = 0;
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
            
            NSUInteger remainder = indexPath.row % 8;

            // Here we determine the width and the height of each item
            if (remainder == 0 || remainder == 4) {
                width = CGRectGetWidth(self.collectionView.bounds);
                height = [self.delegate preferredItemHeight];
            } else if (remainder == 1 || remainder == 7) {
                width = CGRectGetWidth(self.collectionView.bounds)/2;
                height = [self.delegate preferredItemHeight];
            } else {
                width = CGRectGetWidth(self.collectionView.bounds)/2;
                height = [self.delegate preferredItemHeight]/2;
            }
            
            // Here we determine the offset on the x-axis of each item
            if (remainder == 2 || remainder == 3 || remainder == 7) {
                xOffset = width;
            }
            
            // Here we determine the offset on the y-axis of each item
            if (remainder == 0 || remainder == 4) {
                yOffset = yOffsetArray[0];
                
                yOffsetArray[0] = yOffsetArray[0] + height;
                yOffsetArray[1] = yOffsetArray[1] + height;
            } else if (remainder == 1 || remainder == 5 || remainder == 6) {
                yOffset = yOffsetArray[0];

                yOffsetArray[0] = yOffsetArray[0] + height;
            } else {
                yOffset = yOffsetArray[1];

                yOffsetArray[1] = yOffsetArray[1] + height;
            }
            
            UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            layoutAttributes.frame = CGRectMake(xOffset, yOffset, width, height);
            
            self.layoutAttributesCache = [self.layoutAttributesCache arrayByAddingObject:layoutAttributes];
        }
        
        CGFloat maxHeight = MAX(yOffsetArray[0], yOffsetArray[1]);
        self.contentSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), maxHeight);
    }
}

- (CGSize)collectionViewContentSize {
    return self.contentSize;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray<UICollectionViewLayoutAttributes *> *layoutAttributesArray = [NSMutableArray array];
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in  self.layoutAttributesCache) {
        if (CGRectIntersectsRect(layoutAttributes.frame, rect)) {
            [layoutAttributesArray addObject:layoutAttributes];
        }
    }
    
    return layoutAttributesArray;
}

@end
