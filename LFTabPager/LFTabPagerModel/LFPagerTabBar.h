//
//  LFPagerTabBar.h
//  LFTabPager
//
//  Created by 许乐峰 on 2018/4/8.
//  Copyright © 2018年 xulefeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LFPagerTabBarDelegate <NSObject>

@required
- (void)showViewAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface LFPagerTabBar : UIScrollView

@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, weak) id<LFPagerTabBarDelegate> tabBarDelegate;

@property (nonatomic, strong) UIColor *selectedLineColor;
@property (nonatomic, strong) UIColor *unSelectedColor;
@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, assign) NSIndexPath *selectedIndexPath;
@property (nonatomic, assign) CGFloat selectedLineWidth;
@property (nonatomic, assign) CGFloat pagerContentOffsetX;

/// 下面的scrollView刚开始滑动时，记录tabBar的contentOffset作为初始值，当前选中的tabItem后面第二个tabItem加spacing／2的位置减去屏幕宽度作为向右滑结束时tabBar至少要有的contentOffset值，当前选中的tabItem前面第二个tabItem减spacing/2的位置作为向左滑结束时tabBar至多有的contentOffset值，这样保证向右滑动结束时在选中的tabItem的右边还能看到其他tabItem，或者向左滑动结束时在在选中的tabItem的左边还能看到其他tabItem
- (void)recordInitialAndDestX;
/// 下面的scrollView停止滑动时，检查当前选中的tabItem是否在屏幕中，若不在，则把它拉回屏幕中
- (void)checkSelectedTabItemVisible;

@end
