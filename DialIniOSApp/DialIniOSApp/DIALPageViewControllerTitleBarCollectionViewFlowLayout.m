//
//  DIALPageViewControllerTitleBarCollectionViewFlowLayout.m
//  DialIn
//
//  Created by Esposito, Timothy on 8/11/15.
//  Copyright (c) 2015 Audible, Inc. All rights reserved.
//

#import "DIALPageViewControllerTitleBarCollectionViewFlowLayout.h"

/**
 *  Height of line drawn under cell
 */
static const CGFloat ABMKDecoratorLineHeight = 4;

/**
 *  Identifier for the bottom bar decoration view
 */
NSString *const DIALBottomBarDecorationViewKind = @"ABMKBottomBarDecorationViewKind";

/**
 * A decoration view that is used to draw the bar underneath the selected list item
 */
@interface DIALBottomBarDecorationView : UICollectionReusableView

@end

@implementation DIALBottomBarDecorationView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.alpha = 1;
    }
    return self;
}

@end

@interface DIALPageViewControllerTitleBarCollectionViewFlowLayout ()

/**
 *  Layout attributes used for decoration view displayed under the selected cell
 */
@property (nonatomic, strong) UICollectionViewLayoutAttributes *decorationAttributes;

@end

@implementation DIALPageViewControllerTitleBarCollectionViewFlowLayout

- (id)init {
    self = [super init];
    if (self) {
        // Register decoration view
        [self registerClass:[DIALBottomBarDecorationView class] forDecorationViewOfKind:DIALBottomBarDecorationViewKind];
    }
    return self;
}

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath {
    if (!_selectedIndexPath || [selectedIndexPath compare:_selectedIndexPath] != NSOrderedSame) {
        _selectedIndexPath = selectedIndexPath;
        // Invalidate layout to draw line under new index path
        // Use perform batch update so that collection view animates change to line
        DIALPageViewControllerTitleBarCollectionViewFlowLayout __weak *weakSelf = self;
        [self.collectionView performBatchUpdates:^{
          [weakSelf invalidateLayout];
          [weakSelf.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        } completion:nil];
    }
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *layoutAttributes = [[super layoutAttributesForElementsInRect:rect] mutableCopy];
    UICollectionViewLayoutAttributes *decorationAttributes;

    for (UICollectionViewLayoutAttributes *attributes in layoutAttributes) {
        if ([attributes.indexPath compare:self.selectedIndexPath] == NSOrderedSame) {
            decorationAttributes = [self layoutAttributesForDecorationViewOfKind:DIALBottomBarDecorationViewKind atIndexPath:self.selectedIndexPath];

            decorationAttributes.frame = CGRectMake(CGRectGetMinX(attributes.frame), CGRectGetMaxY(attributes.frame) - ABMKDecoratorLineHeight, CGRectGetWidth(attributes.frame), ABMKDecoratorLineHeight);
        }
    }

    if (decorationAttributes) {
        [layoutAttributes addObject:decorationAttributes];
    }

    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind atIndexPath:(NSIndexPath *)indexPath {
    if (!self.decorationAttributes) {
        self.decorationAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:decorationViewKind withIndexPath:indexPath];
    }

    return self.decorationAttributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(__unused CGRect)newBounds {
    return YES;
}

@end
