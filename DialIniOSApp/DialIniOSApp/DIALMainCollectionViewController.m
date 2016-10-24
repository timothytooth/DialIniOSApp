//
//  ViewController.m
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 10/22/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

#import "DIALMainCollectionViewController.h"
#import "DIALCategoryCollectionViewCell.h"
#import "DIALCategoryObject.h"
#import "DIALCollectionViewFloatLayout.h"

@interface DIALMainCollectionViewController ()<DIALCollectionViewFloatLayoutDelegate>


/**
 * The category object array
 */
@property (nonatomic, strong) NSArray<DIALCategoryObject *> *categoryObjectArray;

@end

@implementation DIALMainCollectionViewController

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithCollectionViewLayout:layout];
    
    if (self) {
        _categoryObjectArray = @[[[DIALCategoryObject alloc] init], [[DIALCategoryObject alloc] init], [[DIALCategoryObject alloc] init], [[DIALCategoryObject alloc] init], [[DIALCategoryObject alloc] init], [[DIALCategoryObject alloc] init], [[DIALCategoryObject alloc] init], [[DIALCategoryObject alloc] init]];
        
        [self.collectionView registerClass:[DIALCategoryCollectionViewCell class] forCellWithReuseIdentifier:DIALCategoryCollectionViewCellReuseIdentifier];
        
        self.collectionView.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}

#pragma mark - UIViewController lifecycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if([self.collectionView.collectionViewLayout isKindOfClass:[DIALCollectionViewFloatLayout class]]) {
        ((DIALCollectionViewFloatLayout *)self.collectionView.collectionViewLayout).delegate = self;
    }
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.categoryObjectArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DIALCategoryCollectionViewCell *categoryCollectionViewCell = [collectionView dequeueReusableCellWithReuseIdentifier:DIALCategoryCollectionViewCellReuseIdentifier forIndexPath:indexPath];
    DIALCategoryObject *categoryObject = self.categoryObjectArray[indexPath.row];
    categoryCollectionViewCell.backgroundColor = categoryObject.backgroundColor;
    
    return categoryCollectionViewCell;
}

#pragma mark - UICollectionViewDelegate methods

#pragma mark - DIALCollectionViewFloatLayoutDelegate method

- (CGFloat)preferredItemHeight {
    return CGRectGetWidth(self.collectionView.bounds);
}

@end
