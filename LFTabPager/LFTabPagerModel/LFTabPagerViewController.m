//
//  LFTabPagerViewController.m
//  LFTabPager
//
//  引用参考：https://github.com/NazgulLee/LJTabPager
//
//  源代码区：https://github.com/lefengxu/LFTabPager
//
//  Created by 许乐峰 on 2018/4/8.
//  Copyright © 2018年 xulefeng. All rights reserved.
//

#import "LFTabPagerViewController.h"
#import "LFPagerTabBar.h"

#define kPagerTabBarHeight 40.0f

@interface LFPagerViewControllerInfo : NSObject

@property (nonatomic, strong) id parentViewController; /**<父控制器*/
@property (nonatomic, strong) NSMutableArray *childViewControllers;  /**<子控制器列表*/
@property (nonatomic, assign) NSInteger selectedIndex;  /**<二级菜单选中的下标*/
@end

@implementation LFPagerViewControllerInfo
@end


@interface LFTabPagerViewController () <UIScrollViewDelegate, LFPagerTabBarDelegate>

@property (nonatomic, strong) NSArray *titles; /**< 每次设置titles会使topTabBar重新布局*/
@property (nonatomic, strong) LFPagerTabBar *topTabBar;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *onViewControllers; /**< 存放已加载的视图控制器*/
@property (nonatomic, strong) NSIndexPath *initialSelectedIndex;


@end

@implementation LFTabPagerViewController {
    BOOL _isScrollCausedByDragging; //!< 标识下方的scrollView滑动是因为用户直接滑动还是因为用户点选topTabBar的tabItem导致的
    CGFloat _initialContentOffsetX; //!< 一次滑动开始时scrollView的contentOffset
//    NSInteger _initialSelectedIndex; //!< 一次滑动开始时选中的index
    NSInteger _sectionNumber; //!< 视图控制器的数量
    NSArray *_indexNumberList;
    CGRect _viewFrame;
    UIDeviceOrientation _lastOrientation;
}

@synthesize titles = _titles;
#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    _isScrollCausedByDragging = YES;
    _lastOrientation = [UIDevice currentDevice].orientation;
    self.automaticallyAdjustsScrollViewInsets = NO; //告诉viewController不要自动调整scrollview的contentInset
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [self configureViews];
//    _initialSelectedIndex = self.topTabBar.selectedSection;
    self.initialSelectedIndex = self.topTabBar.selectedIndexPath;
    [self loadVCs];
}


#pragma mark - Initialization
- (void)configureViews {
//    [self.view addSubview:self.topTabBar];
//    CGFloat topTabBarX = 0;
//    CGFloat topTabBarY = 0;
//    CGFloat topTabBarW = [UIScreen mainScreen].bounds.size.width;
//    CGFloat topTabBarH = 40;
//    self.topTabBar.frame = CGRectMake(topTabBarX, topTabBarY, topTabBarW, topTabBarH);
//
//    [self.view addSubview:self.scrollView];
//    CGFloat scrollViewX = 0;
//    CGFloat scrollViewY = CGRectGetMaxY(self.topTabBar.frame);
//    CGFloat scrollViewW = CGRectGetWidth(self.topTabBar.frame);
//    CGFloat scrollViewH = self.view.bounds.size.height - topTabBarH;
//    self.scrollView.frame = CGRectMake(scrollViewX, scrollViewY, scrollViewW, scrollViewH);
//    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
//    self.view.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:self.scrollView];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
//    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:@{@"view": self.scrollView}]];
//    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:@{@"view": self.scrollView}]];

    [self.view addSubview:self.topTabBar];
    self.topTabBar.translatesAutoresizingMaskIntoConstraints = NO;
//    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:@{@"view": self.topTabBar}]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.topTabBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.topTabBar attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.topTabBar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.topTabBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:40]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topTabBar attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
}

//- (void)configureViews {
//    [self.view addSubview:self.scrollView];
//    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
//
//    [self.view addSubview:self.topTabBar];
//    self.topTabBar.translatesAutoresizingMaskIntoConstraints = NO;
//    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:@{@"view": self.topTabBar}]];
//    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.topTabBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
//    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.topTabBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:40]];
//
//
//    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:@{@"view": self.scrollView}]];
//
//    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topTabBar attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
//
//    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
//}


- (void)orientationChanged:(NSNotification *)notification {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
        
    } else if (orientation == UIDeviceOrientationPortrait) {
        
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIDeviceOrientation newOrientation = [UIDevice currentDevice].orientation;
    if (self.scrollView.contentSize.width == 0 || self.scrollView.contentSize.height == 0 || newOrientation != _lastOrientation) {
        _lastOrientation = newOrientation;
        for (NSInteger index = 0; index < self.onViewControllers.count; index++) {
            //            UIViewController *controller = self.onViewControllers[index];
            LFPagerViewControllerInfo *vcInfo = self.onViewControllers[index];
            UIViewController *controller = vcInfo.parentViewController;
            if ([controller isKindOfClass:[UIViewController class]]) {
                controller.view.hidden = YES;
            }
        }
        self.scrollView.contentSize = CGSizeMake(_sectionNumber * self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:self.selectedIndexPath.section];
        [self showViewAtIndexPath:indexPath];
    }
    
}

- (void)loadVCs {
    if (self.vcsSource) {
        //        _sectionNumber = [self.vcsSource numberOfViewControllers];
        _sectionNumber = [self.vcsSource numberOfSections];
        
        NSMutableArray *indexNumberList = [NSMutableArray array];
        for (int i=0; i<_sectionNumber; i++) {
            NSInteger indexNumber = [self.vcsSource numberOfViewControllersInSection:i];
            [indexNumberList addObject:@(indexNumber)];
        }
        _indexNumberList = [indexNumberList copy];
        
        self.titles = [self.vcsSource titles];
        NSAssert(_sectionNumber == self.titles.count, @"[vcsSource titles].count must equal to [vcsSource numberOfSections]");
        __weak typeof(self)weakSelf = self;
        [self.titles enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSArray class]]) {
                NSArray * array = obj;
                NSInteger rowCount = [weakSelf.vcsSource numberOfViewControllersInSection:idx];
                
                NSAssert(rowCount == array.count, @"rowCount must equal to [vcsSource numberOfViewControllersInSection:]");
            }
        }];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:self.selectedIndexPath.section];
        [self showViewAtIndexPath:indexPath];
    }
}
#pragma mark - Data Source
#pragma mark - Delegate
#pragma UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _isScrollCausedByDragging = YES;
    _initialContentOffsetX = scrollView.contentOffset.x;
    self.initialSelectedIndex = self.selectedIndexPath;
//    self.topTabBar.scrollOrientation = SCROLL_ORIENTATION_NONE; // 重置scrollOrientation
    [self.topTabBar recordInitialAndDestX];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_isScrollCausedByDragging) {
        self.topTabBar.pagerContentOffsetX = scrollView.contentOffset.x;
    }
//    if (scrollView.contentOffset.x - _initialContentOffsetX > 0) {
//        self.topTabBar.scrollOrientation = SCROLL_ORIENTATION_RIGHT;
//    } else if (scrollView.contentOffset.x - _initialContentOffsetX < 0) {
//        self.topTabBar.scrollOrientation = SCROLL_ORIENTATION_LEFT;
//    } else {
//        self.topTabBar.scrollOrientation = SCROLL_ORIENTATION_NONE;
//    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (_initialSelectedIndex.section != self.topTabBar.selectedIndexPath.section) { // viewController切换了
        _initialSelectedIndex = self.topTabBar.selectedIndexPath;
        
        LFPagerViewControllerInfo *vcInfo = self.onViewControllers[_initialSelectedIndex.section];
        NSInteger selectedIndex = vcInfo.selectedIndex;
        [self showViewAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:_initialSelectedIndex.section]];
    }
}

#pragma LJPagerTabBarDelegate
- (void)showViewAtIndexPath:(NSIndexPath *)indexPath {
    BOOL _firstShown = NO;
    _isScrollCausedByDragging = NO;
    [self.topTabBar checkSelectedTabItemVisible];

    NSInteger section = indexPath.section;
    NSInteger index = indexPath.item;
    
    LFPagerViewControllerInfo *vcInfo = self.onViewControllers[section];
    UIViewController *controller = vcInfo.parentViewController;
    NSArray *childControllers = vcInfo.childViewControllers;
    if ([controller isKindOfClass:[NSNull class]]) {
        if (0 != childControllers.count) {
            controller = [[UIViewController alloc] init];
            
        } else {
            controller = [self.vcsSource viewControllerAtIndexPath:indexPath];
        }

        vcInfo.parentViewController = controller;
        _firstShown = YES;
    }


    vcInfo.selectedIndex = index;

    CGFloat targetx = section * self.scrollView.bounds.size.width;
    if (controller.parentViewController == nil) {
        [self addChildViewController:controller];
        controller.view.frame = CGRectMake(targetx, 0, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
        [self.scrollView addSubview:controller.view];
        [controller didMoveToParentViewController:self];
    } else {
        controller.view.frame = CGRectMake(targetx, 0, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
        controller.view.hidden = NO;
    }
    
    if (0!=childControllers.count) {
        UIViewController *subController = vcInfo.childViewControllers[index];
        if ([subController isKindOfClass:[NSNull class]]) {
            subController = [self.vcsSource viewControllerAtIndexPath:indexPath];
            subController.view.frame = CGRectMake(0, 0, controller.view.bounds.size.width, controller.view.bounds.size.height);
            
            [controller addChildViewController:subController];
            [controller.view addSubview:subController.view];
            [subController didMoveToParentViewController:self];
            vcInfo.childViewControllers[index] = subController;
        } else {
            subController.view.frame = CGRectMake(0, 0, controller.view.bounds.size.width, controller.view.bounds.size.height);
            subController.view.hidden = NO;
            [controller.view bringSubviewToFront:subController.view];
        }
    }

    
    controller.view.backgroundColor = [UIColor yellowColor];
    self.scrollView.backgroundColor = [UIColor redColor];
    if (section-1 >= 0) {
        UIViewController *leftController = self.onViewControllers[section-1];
        if ([leftController isKindOfClass:[UIViewController class]] && leftController.parentViewController != nil) {
            CGSize size = self.scrollView.bounds.size;
            leftController.view.frame = CGRectMake(targetx - size.width, 0, size.width, size.height);
            leftController.view.hidden = NO;
        }
    }
    if (section+1 < _sectionNumber) {
        UIViewController *rightController = self.onViewControllers[section+1];
        if ([rightController isKindOfClass:[UIViewController class]] && rightController.parentViewController != nil) {
            CGSize size = self.scrollView.bounds.size;
            rightController.view.frame = CGRectMake(targetx + size.width, 0, size.width, size.height);
            rightController.view.hidden = NO;
        }
    }
    [self.scrollView setContentOffset:CGPointMake(targetx, 0) animated:NO];
    [self callDelegateAtIndex:section withObject:[NSNumber numberWithBool:_firstShown]];
}

#pragma mark - Target Action
#pragma mark - Network Operation
#pragma mark - Public Method
#pragma mark - Private Method
- (void)callDelegateAtIndex:(NSInteger)index withObject:(NSNumber *)object{
//    LFPagerViewControllerInfo *vcInfo = self.onViewControllers[index];
//    UIViewController *controller = vcInfo.parentViewController;
//    if ([controller isKindOfClass:[UIViewController class]]) {
//        if ([controller conformsToProtocol:@protocol(LJTabPagerVCDelegate)]) {
//            if ([controller respondsToSelector:@selector(hasBeenSelectedAndShown:)]) {
//                [controller performSelector:@selector(hasBeenSelectedAndShown:) withObject:object afterDelay:0];
//            }
//        }
//    }
}
#pragma mark - Setter
- (void)setSelectedColor:(UIColor *)selectedColor {
    _selectedColor = selectedColor;
    self.topTabBar.selectedColor = selectedColor;
}

- (void)setUnSelectedColor:(UIColor *)unSelectedColor {
    _unSelectedColor = unSelectedColor;
    self.topTabBar.unSelectedColor = unSelectedColor;
}

- (void)setSelectedLineColor:(UIColor *)selectedLineColor {
    _selectedLineColor = selectedLineColor;
    self.topTabBar.selectedLineColor = selectedLineColor;
}

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath {
    self.topTabBar.selectedIndexPath = selectedIndexPath;
}

- (void)setSelectedLineWidth:(CGFloat)selectedLineWidth {
    self.topTabBar.selectedLineWidth = selectedLineWidth;
}
#pragma mark - Getter
- (NSIndexPath *)selectedIndexPath {
    return self.topTabBar.selectedIndexPath;
}
#pragma mark - Lazy
- (LFPagerTabBar *)topTabBar {
    if (!_topTabBar) {
        _topTabBar = [[LFPagerTabBar alloc] init];
        _topTabBar.backgroundColor = self.tabBarBKColor;
        _topTabBar.tabBarDelegate = self;
    }
    return _topTabBar;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.delegate = self;
        _scrollView.pagingEnabled = YES;
        _scrollView.bounces = NO;
        _scrollView.directionalLockEnabled = YES;
        _scrollView.delaysContentTouches = YES;
    }
    return _scrollView;
}

- (void)setTitles:(NSArray *)titles {
    _titles = titles;
    self.topTabBar.titles = titles;
}

- (NSArray *)titles {
    if (!_titles) {
        _titles = [self.vcsSource titles];
    }
    return _titles;
}

- (UIColor *)tabBarBKColor {
    if (!_tabBarBKColor) {
        _tabBarBKColor = [UIColor colorWithWhite:0.95 alpha:0.95];
    }
    return _tabBarBKColor;
}

- (NSMutableArray *)onViewControllers {
    if (!_onViewControllers) {
        NSInteger n = _sectionNumber;
        _onViewControllers = [NSMutableArray array];
        for (NSInteger i = 0; i < n; i++) {
            
            LFPagerViewControllerInfo *info = [[LFPagerViewControllerInfo alloc] init];
            info.parentViewController = [NSNull null];
            info.childViewControllers = nil;
            
            NSInteger indexNumber =  [_indexNumberList[i] integerValue];
            if (indexNumber > 1) {
                NSMutableArray *childVcList = [NSMutableArray array];
                for (int j=0; j<indexNumber; j++) {
                    [childVcList addObject:[NSNull null]];
                }
                info.childViewControllers = childVcList;
            }
            
            [_onViewControllers addObject:info];
        }
    }
    return _onViewControllers;
}
@end
