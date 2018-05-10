//
//  LFTabPagerViewController.h
//  LFTabPager
//
//  Created by 许乐峰 on 2018/4/8.
//  Copyright © 2018年 xulefeng. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol LFTabPagerViewControllerSource <NSObject>
@required
- (NSInteger)numberOfViewControllersInSection:(NSInteger)section;
- (NSInteger)numberOfSections;
- (UIViewController *)viewControllerAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)titles;

@end


@interface LFTabPagerViewController : UIViewController

@property (nonatomic, strong) UIColor *tabBarBKColor;
@property (nonatomic, weak) id<LFTabPagerViewControllerSource> vcsSource;
@property (nonatomic, readonly) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) UIColor *selectedLineColor;
@property (nonatomic, strong) UIColor *unSelectedColor;
@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, assign) CGFloat selectedLineWidth;

@end
