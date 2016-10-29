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

/**
 * The size for a small item
 */
@property (nonatomic) CGSize smallSize;

/**
 * The size for a medium item
 */
@property (nonatomic) CGSize mediumSize;

/**
 * The size for a large item
 */
@property (nonatomic) CGSize largeSize;

/**
 * Used to determine which of three layouts to use
 */
@property (nonatomic) NSUInteger levelThreeSwitch;

@end

@implementation DIALCollectionViewFloatLayout

/**
 * This is the ratio of each item width to its height
 */
static const CGFloat DIALCollectionViewFloatLayoutRatio = 1.33;

/**
 * This is the interim spacing between all items
 */
static const CGFloat DIALCollectionViewFloatLayoutSpacing = 2;

- (void)prepareLayout {
    if (!self.layoutAttributesCache.count) {
        self.contentSize = CGSizeZero;
        self.layoutAttributesCache = [NSArray array];
        
        CGFloat width = (CGRectGetWidth(self.collectionView.bounds) - (DIALCollectionViewFloatLayoutSpacing * 4))/3;
        self.smallSize = CGSizeMake(width, width*DIALCollectionViewFloatLayoutRatio);
        
        self.largeSize = CGSizeMake((self.smallSize.width*2)+DIALCollectionViewFloatLayoutSpacing, (self.smallSize.height*2)+DIALCollectionViewFloatLayoutSpacing);
        
        width = (CGRectGetWidth(self.collectionView.bounds) - (DIALCollectionViewFloatLayoutSpacing * 3))/2;
        self.mediumSize = CGSizeMake(width, width*DIALCollectionViewFloatLayoutRatio);
        
        NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];
        
        if (numberOfItems == 0) {
            return;
        } else if (numberOfItems == 1) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
            UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            layoutAttributes.frame = CGRectMake(DIALCollectionViewFloatLayoutSpacing, DIALCollectionViewFloatLayoutSpacing, self.largeSize.width, self.largeSize.height);
        } else if (numberOfItems%3 == 0) {
            for (NSUInteger item = 0; item < numberOfItems; item+=3) {
                [self addTripleLayoutWithItem:item];
            }
        } else {
            [self addDoubleRowLayoutWithItem:0];
            
            if ((numberOfItems-2)%3 == 0) {
                for (NSUInteger item = 2; item < numberOfItems; item+=3) {
                    [self addTripleLayoutWithItem:item];
                }
            }
            
            if ((numberOfItems-4)%3 == 0) {
                [self addDoubleRowLayoutWithItem:numberOfItems-3];
            }
        }
            
        self.levelThreeSwitch = 0;
    }
}

- (void)addDoubleRowLayoutWithItem:(NSUInteger)item {
    NSInteger yOffset = self.contentSize.height;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
    UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    layoutAttributes.frame = CGRectMake(DIALCollectionViewFloatLayoutSpacing, yOffset+DIALCollectionViewFloatLayoutSpacing, self.mediumSize.width, self.mediumSize.height);
    
    self.layoutAttributesCache = [self.layoutAttributesCache arrayByAddingObject:layoutAttributes];
    
    indexPath = [NSIndexPath indexPathForItem:item+1 inSection:0];
    layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    layoutAttributes.frame = CGRectMake(self.mediumSize.width + (DIALCollectionViewFloatLayoutSpacing*2), yOffset+DIALCollectionViewFloatLayoutSpacing, self.mediumSize.width, self.mediumSize.height);
    
    self.layoutAttributesCache = [self.layoutAttributesCache arrayByAddingObject:layoutAttributes];
    
    self.contentSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), self.contentSize.height+self.mediumSize.height+DIALCollectionViewFloatLayoutSpacing);
}

- (void)addTripleLayoutWithItem:(NSUInteger)item {
    switch (self.levelThreeSwitch) {
        case 0:
            [self addLeftOverloadedTripleLayoutWithItem:item];
            break;
        case 1:
            [self addRightOverloadedTripleLayoutWithItem:item];
            break;
        case 2:
            [self addTripleRowLayoutWithItem:item];
            break;
    }
    
    self.levelThreeSwitch++;
    if (self.levelThreeSwitch > 2) {
        self.levelThreeSwitch = 0;
    }
}

- (void)addLeftOverloadedTripleLayoutWithItem:(NSUInteger)item {
    NSInteger yOffset = self.contentSize.height;

    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
    UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    layoutAttributes.frame = CGRectMake(DIALCollectionViewFloatLayoutSpacing, yOffset+DIALCollectionViewFloatLayoutSpacing, self.largeSize.width, self.largeSize.height);
    
    self.layoutAttributesCache = [self.layoutAttributesCache arrayByAddingObject:layoutAttributes];
    
    indexPath = [NSIndexPath indexPathForItem:item+1 inSection:0];
    layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    layoutAttributes.frame = CGRectMake(self.largeSize.width + (DIALCollectionViewFloatLayoutSpacing*2), yOffset+DIALCollectionViewFloatLayoutSpacing, self.smallSize.width, self.smallSize.height);
    
    self.layoutAttributesCache = [self.layoutAttributesCache arrayByAddingObject:layoutAttributes];
    
    indexPath = [NSIndexPath indexPathForItem:item+2 inSection:0];
    layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    layoutAttributes.frame = CGRectMake(self.largeSize.width + (DIALCollectionViewFloatLayoutSpacing*2), self.smallSize.height+yOffset+(DIALCollectionViewFloatLayoutSpacing*2), self.smallSize.width, self.smallSize.height);
    
    self.layoutAttributesCache = [self.layoutAttributesCache arrayByAddingObject:layoutAttributes];
    
    self.contentSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), self.contentSize.height+self.largeSize.height+DIALCollectionViewFloatLayoutSpacing);
}

- (void)addRightOverloadedTripleLayoutWithItem:(NSUInteger)item {
    NSInteger yOffset = self.contentSize.height;

    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
    UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    layoutAttributes.frame = CGRectMake(DIALCollectionViewFloatLayoutSpacing, yOffset+DIALCollectionViewFloatLayoutSpacing, self.smallSize.width, self.smallSize.height);
    
    self.layoutAttributesCache = [self.layoutAttributesCache arrayByAddingObject:layoutAttributes];
    
    indexPath = [NSIndexPath indexPathForItem:item+1 inSection:0];
    layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    layoutAttributes.frame = CGRectMake(DIALCollectionViewFloatLayoutSpacing, self.smallSize.height+yOffset+(DIALCollectionViewFloatLayoutSpacing*2), self.smallSize.width, self.smallSize.height);
    
    self.layoutAttributesCache = [self.layoutAttributesCache arrayByAddingObject:layoutAttributes];
    
    indexPath = [NSIndexPath indexPathForItem:item+2 inSection:0];
    layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    layoutAttributes.frame = CGRectMake(self.smallSize.width + (DIALCollectionViewFloatLayoutSpacing*2), yOffset+DIALCollectionViewFloatLayoutSpacing, self.largeSize.width, self.largeSize.height);
    
    self.layoutAttributesCache = [self.layoutAttributesCache arrayByAddingObject:layoutAttributes];
    
    self.contentSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), self.contentSize.height+self.largeSize.height+DIALCollectionViewFloatLayoutSpacing);
}

- (void)addTripleRowLayoutWithItem:(NSUInteger)item {
    NSInteger yOffset = self.contentSize.height;

    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
    UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    layoutAttributes.frame = CGRectMake(DIALCollectionViewFloatLayoutSpacing, yOffset+DIALCollectionViewFloatLayoutSpacing, self.smallSize.width, self.smallSize.height);
    
    self.layoutAttributesCache = [self.layoutAttributesCache arrayByAddingObject:layoutAttributes];
    
    indexPath = [NSIndexPath indexPathForItem:item+1 inSection:0];
    layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    layoutAttributes.frame = CGRectMake(self.smallSize.width + (DIALCollectionViewFloatLayoutSpacing*2), yOffset+DIALCollectionViewFloatLayoutSpacing, self.smallSize.width, self.smallSize.height);
    
    self.layoutAttributesCache = [self.layoutAttributesCache arrayByAddingObject:layoutAttributes];
    
    indexPath = [NSIndexPath indexPathForItem:item+2 inSection:0];
    layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    layoutAttributes.frame = CGRectMake((self.smallSize.width*2) + (DIALCollectionViewFloatLayoutSpacing*3), yOffset+DIALCollectionViewFloatLayoutSpacing, self.smallSize.width, self.smallSize.height);
    
    self.layoutAttributesCache = [self.layoutAttributesCache arrayByAddingObject:layoutAttributes];
    
    self.contentSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), self.contentSize.height+self.smallSize.height+DIALCollectionViewFloatLayoutSpacing);
}

- (CGSize)collectionViewContentSize {
    return self.contentSize;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray<UICollectionViewLayoutAttributes *> *layoutAttributesArray = [NSMutableArray array];
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in self.layoutAttributesCache) {
        if (CGRectIntersectsRect(layoutAttributes.frame, rect)) {
            [layoutAttributesArray addObject:layoutAttributes];
        }
    }
    
    return layoutAttributesArray;
}

@end
