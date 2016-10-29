//
//  DIALRootPageViewController.m
//  DialIniOSApp
//
//  Created by Esposito, Timothy on 10/29/16.
//  Copyright © 2016 Esposito, Timothy. All rights reserved.
//

#import "DIALRootPageViewController.h"
#import "DIALMainCollectionViewController.h"
#import "DIALCollectionViewFloatLayout.h"
#import "DIALTestTableViewController.h"

@interface DIALRootPageViewController () <UIPageViewControllerDelegate, UIPageViewControllerDataSource>

/**
 * The array of all view controllers to be displayed
 */
@property (nonatomic,strong) NSArray<UIViewController *> *viewControllersArray;

@end

@implementation DIALRootPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.delegate = self;
    self.dataSource = self;
    
    DIALCollectionViewFloatLayout *floatLayout = [[DIALCollectionViewFloatLayout alloc] init];
    DIALMainCollectionViewController *mainCollectionViewController = [[DIALMainCollectionViewController alloc] initWithCollectionViewLayout:floatLayout];
    
    DIALTestTableViewController *testTableViewController = [[DIALTestTableViewController alloc] initWithStyle:UITableViewStylePlain];
    
    self.viewControllersArray = @[mainCollectionViewController, testTableViewController];
    
    [self setViewControllers:@[ self.viewControllersArray[0] ] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    return [self.viewControllersArray objectAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSUInteger index = [self.viewControllersArray indexOfObject:viewController];
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger index = [self.viewControllersArray indexOfObject:viewController];
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.viewControllersArray count]) {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
}

@end
