//
//  LFPagerTabBar.m
//  LFTabPager
//
//  Created by 许乐峰 on 2018/4/8.
//  Copyright © 2018年 xulefeng. All rights reserved.
//


#define kMinSpacing 40.0
#define kAnimateDuration 0.25

#import "LFPagerTabBar.h"

@interface LFTabInfoModel : NSObject
@property (nonatomic, assign, getter=isHasSecondLevelMenu) BOOL hasSecondLevelMenu;  /**<是否含有二级菜单*/
@property (nonatomic, assign, getter=isUnfolded) BOOL unfolded;  /**<是否展开*/
@property (nonatomic, assign) NSInteger selectedIndex;   /**<已选下标*/
@end

@implementation LFTabInfoModel
@end

@interface LFPagerTabBar () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate> {
    BOOL _needsLayoutTabItems;
}

@property (nonatomic, assign) UIDeviceOrientation lastOrientation;
@property (nonatomic, strong) UIView *selectedLine;
@property (nonatomic, strong) NSArray *tabItemList;
@property (nonatomic, strong) NSMutableArray <LFTabInfoModel *>*sectionStateList;        /**<标题状态*/
@property (nonatomic, strong) UIView *listView;       /**下拉列表背景View*/
@property (nonatomic, strong) UITableView *subTitleTableView;  /**下拉列表*/
@property (nonatomic, assign) CGFloat tabBarInitialX;
@property (nonatomic, assign) CGFloat tabBarLeftDestX;
@property (nonatomic, assign) CGFloat tabBarRightDestX;

@end

@implementation LFPagerTabBar

@synthesize selectedLineColor = _selectedLineColor;
#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        _lastOrientation = [UIDevice currentDevice].orientation;
        _selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.selectedLine.superview == nil) {
        self.selectedLine.frame = CGRectMake(0, self.bounds.size.height - 2, 0, 2);
        [self addSubview:self.selectedLine];
    }
    
    // 在设置标题或者横竖屏切换时重新排版
    UIDeviceOrientation newOrientation = [UIDevice currentDevice].orientation;
    if (_needsLayoutTabItems || newOrientation != self.lastOrientation) {
        self.lastOrientation = newOrientation;
        [self layoutTabItems];
    }
}

#pragma mark - Data Source
#pragma mark - UITableView DataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *titles = self.titles[self.selectedIndexPath.section];
    return titles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *titles = self.titles[self.selectedIndexPath.section];
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.font          = [UIFont systemFontOfSize:11.f];
        cell.textLabel.textColor     = [UIColor blackColor];
        cell.selectionStyle          = UITableViewCellSelectionStyleNone;
        cell.tintColor = self.selectedColor;
    }
    
    NSString *title = titles[indexPath.row];
    cell.textLabel.text = title;
    
    LFTabInfoModel *tabInfoModel = self.sectionStateList[self.selectedIndexPath.section];
    
    if (indexPath.row == tabInfoModel.selectedIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.textColor = self.selectedColor;
    }
    
    return cell;
}


#pragma mark - Delegate
#pragma mark - UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger currentSection = self.selectedIndexPath.section;
    NSInteger currentItem = self.selectedIndexPath.row;
    // 取消前一个选中的，就是单选啦
    LFTabInfoModel *currentPagerTabModel = self.sectionStateList[currentSection];
    NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:currentPagerTabModel.selectedIndex inSection:0];
    UITableViewCell *lastCell = [tableView cellForRowAtIndexPath:lastIndex];
    lastCell.accessoryType = UITableViewCellAccessoryNone;
    lastCell.textLabel.textColor = [UIColor blackColor];
    
    // 选中操作
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.textLabel.textColor = self.selectedColor;
    
    //afterDelay为延迟多少删除上次的选中效果
    [tableView performSelector:@selector(deselectRowAtIndexPath:animated:) withObject:lastIndex afterDelay:.0];
    
    
    UIButton *tabItem = self.tabItemList[self.selectedIndexPath.section];
    
    NSArray *titles = self.titles[currentSection];
    NSString *title = titles[indexPath.row];
    [tabItem setTitle:title forState:UIControlStateNormal];
    
    self.listView.hidden = YES;
    
    currentPagerTabModel.selectedIndex = indexPath.row;
    currentPagerTabModel.unfolded = NO;
    
    currentItem = indexPath.row;
    self.selectedIndexPath = [NSIndexPath indexPathForRow:currentItem inSection:currentSection];
    
    [self highlightTabItemAtIndexPath:self.selectedIndexPath ];
    [self.tabBarDelegate showViewAtIndexPath:self.selectedIndexPath];
}

#pragma mark - Target Action
- (void)clickListView:(UITapGestureRecognizer *)tapGesture {
    // 隐藏二级菜单
    self.listView.hidden = YES;
    LFTabInfoModel *currentPagerTabModel = [self.sectionStateList objectAtIndex:self.selectedIndexPath.section];
    currentPagerTabModel.unfolded = NO;
    [self highlightTabItemAtIndexPath:self.selectedIndexPath];
}
#pragma mark - Public Method
#pragma mark - Private Method
- (void)layoutTabItems {
    [self adjustItemWidth];
    
    CGFloat totalWidth = 0;
    NSInteger itemCount = self.tabItemList.count;
    // 确定每个item的位置
    for (int i=0; i<itemCount; i++) {
        UIButton *tabItem = self.tabItemList[i];
        totalWidth += tabItem.bounds.size.width;
        tabItem.center = CGPointMake(totalWidth - tabItem.bounds.size.width / 2, self.bounds.size.height / 2);
        [self addSubview:tabItem];
    }
    
    self.contentSize = CGSizeMake(totalWidth, self.bounds.size.height);
    _needsLayoutTabItems = NO;
    
    [self highlightTabItemAtIndexPath:self.selectedIndexPath];
    [self moveSelectedLineToIndexPath:self.selectedIndexPath animated:NO];
}

/**
 调整tabItem的宽度。
 原则：当tabItem宽度总和<屏幕宽度，item宽度 = 屏幕宽度/item个数
 */
- (void)adjustItemWidth {
    CGFloat itemTotalWidth = 0;
    NSInteger itemCount = self.tabItemList.count;
    for (int i = 0; i < itemCount; i++) {
        UIButton *tabItem = self.tabItemList[i];
        itemTotalWidth += tabItem.bounds.size.width;
    }
    
    if (itemTotalWidth < [UIScreen mainScreen].bounds.size.width) {
        CGFloat itemWidth = [UIScreen mainScreen].bounds.size.width / itemCount;
        
        [self.tabItemList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIButton *tabItem = obj;
            CGRect bounds = tabItem.bounds;
            bounds.size.width = MAX(bounds.size.width, itemWidth);
            tabItem.bounds = bounds;
        }];
    }
}

- (void)highlightTabItemAtIndexPath:(NSIndexPath *)indexPath {
    

//    [((UIButton *)self.tabItemList[indexPath.section]))];
//    UIColor *tintColor = tabInfoModel.isUnfolded ? self.selectedColor:self.unSelectedColor;
//    UIColor *ti = tabInfoModel.isUnfolded

//     button.imageView.transform = CGAffineTransformMakeRotation(M_PI);
    // 取消前一个选中的，就是单选啦
    LFTabInfoModel *tabInfoModel = self.sectionStateList[indexPath.section];
    if (tabInfoModel.isUnfolded) {
        ((UIButton *)self.tabItemList[self.selectedIndexPath.section]).imageView.transform = CGAffineTransformMakeRotation(M_PI);
    } else {
        ((UIButton *)self.tabItemList[self.selectedIndexPath.section]).imageView.transform = CGAffineTransformIdentity;
    }
 
    [((UIButton *)self.tabItemList[self.selectedIndexPath.section]) setTintColor:self.unSelectedColor];
    [((UIButton *)self.tabItemList[self.selectedIndexPath.section]) setTitleColor:self.unSelectedColor forState:UIControlStateNormal];
    
    [((UIButton *)self.tabItemList[indexPath.section]) setTitleColor:self.selectedColor forState:UIControlStateNormal];
    [((UIButton *)self.tabItemList[indexPath.section]) setTintColor:self.selectedColor];
    
    [((UIButton *)self.tabItemList[self.selectedIndexPath.section]) setTintColor:self.unSelectedColor];
    [((UIButton *)self.tabItemList[indexPath.section]) setTintColor:self.selectedColor];
    
    
    self.selectedIndexPath = indexPath;
    
    LFTabInfoModel *infoModel = self.sectionStateList[indexPath.section];
    infoModel.selectedIndex = indexPath.item;
}

- (void)moveSelectedLineToIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
    CGFloat endLineWidth = ((UIButton *)self.tabItemList[indexPath.section]).bounds.size.width;
    CGFloat endCenterX = ((UIButton *)self.tabItemList[indexPath.section]).center.x;
    if (animated) {
        [UIView animateWithDuration:kAnimateDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.selectedLine.center = CGPointMake(endCenterX, self.selectedLine.center.y);
            self.selectedLine.bounds = CGRectMake(0, 0, endLineWidth, self.selectedLine.bounds.size.height);
        } completion:NULL];
    } else {
        self.selectedLine.center = CGPointMake(endCenterX, self.selectedLine.center.y);
        self.selectedLine.bounds = CGRectMake(0, 0, endLineWidth, self.selectedLine.bounds.size.height);
    }
}


/**
 设置tab的信息状态列表

 @param titles 标题
 @return 信息状态列表
 */
- (NSArray *)sectionStateListWithTitles:(NSArray *)titles {
    NSMutableArray *sectionList = [NSMutableArray array];
    for (id obj in titles) {
        LFTabInfoModel *pagerTabModel = [[LFTabInfoModel alloc] init];
        pagerTabModel.hasSecondLevelMenu = [obj isKindOfClass:[NSArray class]];
        [sectionList addObject:pagerTabModel];
    }
    
    return [sectionList copy];
}


/**
 根据标题数组设置tabItem列表
 */
- (NSArray *)tabItemListWithTitles:(NSArray *)titles {
    NSMutableArray *tabItemList = [NSMutableArray arrayWithCapacity:titles.count];
    for (int i = 0; i < titles.count; i++) {
        id obj = titles[i];
        NSString *title = nil;
        if ([obj isKindOfClass:[NSArray class]]) {
            title = [(NSArray *)obj firstObject];
        } else {
            title = obj;
        }
        
        UIButton *tabItem = [UIButton buttonWithType:UIButtonTypeCustom];
        tabItem.tag = i;
        [tabItem setTitle:title forState:UIControlStateNormal];
        [tabItem setTitleColor:self.unSelectedColor forState:UIControlStateNormal];
        [tabItem setTitleColor:self.selectedColor forState:UIControlStateSelected];
        [tabItem sizeToFit];
        [tabItem addTarget:self action:@selector(toggleTabItem:) forControlEvents:UIControlEventTouchUpInside];
        [tabItemList addObject:tabItem];
        tabItem.bounds = CGRectMake(0, 0, tabItem.bounds.size.width + kMinSpacing, tabItem.bounds.size.height);
        
        if ([obj isKindOfClass:[NSArray class]]) {
            
            UIImage *image = [[UIImage imageNamed:@"list_menu_btn_normal_open"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [tabItem setImage:image forState:UIControlStateNormal];
            tabItem.tintColor = self.unSelectedColor;
            tabItem.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10);
            tabItem.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
            tabItem.transform = CGAffineTransformMakeScale(-1.0, 1.0);
            tabItem.titleLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
            tabItem.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        }
    }
    return [NSArray arrayWithArray:tabItemList];
}


/**
 重置二级标题列表
 */
- (void)resetSubTitleTableView {
    if (!self.listView.isHidden) {
        
        NSArray *subTitles = self.titles[self.selectedIndexPath.section];
        CGFloat height = MIN(subTitles.count * 44, 6*44);
        CGRect frame = self.subTitleTableView.frame;
        frame.size.height = height;
        self.subTitleTableView.frame = frame;
        
        NSInteger subTitleCount = subTitles.count;
        for (int i=0; i<subTitleCount; i++) {
            NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:i inSection:0];
            UITableViewCell *lastCell = [self.subTitleTableView cellForRowAtIndexPath:lastIndex];
            lastCell.accessoryType = UITableViewCellAccessoryNone;
            lastCell.textLabel.textColor = [UIColor blackColor];
        }
        
        [self.subTitleTableView reloadData];
    }
}

- (void)toggleTabItem:(UIButton *)tabItem {
    
    LFTabInfoModel *tabInfoModoel = [self.sectionStateList objectAtIndex:tabItem.tag];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tabInfoModoel.selectedIndex inSection:tabItem.tag];
    [self selectTabItemAtIndexPath:indexPath animated:YES];
    
}

- (void)selectTabItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
    NSInteger currentSelectedSection = self.selectedIndexPath.section;
    NSInteger selectedSection = indexPath.section;
    if (currentSelectedSection == selectedSection) {
        // 如果是点击同个tab则判断是否展开二级菜单
        LFTabInfoModel *tabInfoModoel = [self.sectionStateList objectAtIndex:selectedSection];
        if (tabInfoModoel.isHasSecondLevelMenu) {
            self.listView.hidden = !self.listView.isHidden;
            tabInfoModoel.unfolded = !tabInfoModoel.isUnfolded;
            
            [self resetSubTitleTableView];
        }
        
        
    } else {
        // 若切换不同tab，则判断是否隐藏二级菜单
        LFTabInfoModel *currentTabModel = [self.sectionStateList objectAtIndex:currentSelectedSection];
        
        if (currentTabModel.isHasSecondLevelMenu && currentTabModel.isUnfolded) {
            self.listView.hidden = YES;
            currentTabModel.unfolded = NO;
        }
        
        NSLog(@"hasSecondLevelMenu:%@, isUnfolded:%@", currentTabModel.isHasSecondLevelMenu?@"YES":@"NO", currentTabModel.isUnfolded?@"YES":@"NO");
        
    }
    
    // 计算是否要调整tabBar的contentOffset，保证新选中的tabItem左右至少有一个未选中的tabItem可见
    NSInteger direction = 0;
    NSInteger destIndex = -1;
    CGFloat destOffsetx = self.contentOffset.x;
    if (selectedSection != currentSelectedSection) {
        destIndex = selectedSection < currentSelectedSection ? selectedSection-1 : selectedSection+1;
        direction = selectedSection < currentSelectedSection ? -1 : 1;
    }
    
    if (destIndex >= 0 && destIndex <self.tabItemList.count) {
        UIButton *destTabItem = ((UIButton *)self.tabItemList[destIndex]);
        if (direction == -1) {
            destOffsetx = destTabItem.frame.origin.x;
        } else if (direction == 1) {
            destOffsetx = destTabItem.frame.origin.x + destTabItem.frame.size.width +  self.bounds.size.width;
        }
    }
    if (destOffsetx < 0)
        destOffsetx = 0;
    if (destOffsetx > self.contentSize.width-self.bounds.size.width)
        destOffsetx = self.contentSize.width-self.bounds.size.width;
    
    [self highlightTabItemAtIndexPath:indexPath];
    [self moveSelectedLineToIndexPath:indexPath animated:YES];
    
    [self.tabBarDelegate showViewAtIndexPath:indexPath];
    [self animateContentOffset:CGPointMake(destOffsetx, 0) withDuration:kAnimateDuration];
}

- (void)animateContentOffset:(CGPoint)offset withDuration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.contentOffset = offset;
    } completion:NULL];
}

- (void)recordInitialAndDestX {
    self.tabBarInitialX = self.contentOffset.x;
    self.tabBarRightDestX = 0;
    self.tabBarLeftDestX = self.contentSize.width - self.bounds.size.width;
    if (self.selectedIndexPath.section < self.tabItemList.count - 2) {
        // 当前选中tabItem的下下个tabItem的右边界加tabItem间隔的一半，再减去屏幕宽度，作为上面的scrollView的至少要有的contentOffset
        self.tabBarRightDestX = ((UIButton *)self.tabItemList[self.selectedIndexPath.section + 2]).frame.origin.x + ((UIButton *)self.tabItemList[self.selectedIndexPath.section + 2]).frame.size.width + self.bounds.size.width;
    }
    
    if (1 < self.selectedIndexPath.section) {
        // 当前选中tabItem的上上个tabItem的左边界减tabItem间隔的一半，作为上面的scrollView的至多应有的contentOffset
        self.tabBarLeftDestX = ((UIButton *)self.tabItemList[self.selectedIndexPath.section - 2]).frame.origin.x;
    }
}

- (void)checkSelectedTabItemVisible {
    CGFloat selectedTabItemLeftX = ((UIButton *)self.tabItemList[self.selectedIndexPath.section]).frame.origin.x;
    CGFloat selectedTabItemRightX = ((UIButton *)self.tabItemList[self.selectedIndexPath.section]).frame.origin.x + ((UIButton *)self.tabItemList[self.selectedIndexPath.section]).frame.size.width;
    // 若当前选中的tabItem的右边界不在屏幕中
    if (selectedTabItemRightX > self.contentOffset.x + self.bounds.size.width) {
        CGFloat expectedContentOffset = selectedTabItemRightX - self.bounds.size.width / 2;
        CGFloat maxContentOffset = self.contentSize.width - self.bounds.size.width;
        CGFloat result = expectedContentOffset > maxContentOffset ? maxContentOffset : expectedContentOffset;
        //[self setContentOffset:CGPointMake(result, 0) animated:YES];
        [self animateContentOffset:CGPointMake(result, 0) withDuration:kAnimateDuration];
    }
    // 若当前选中的tabItem的左边界不在屏幕中
    if (selectedTabItemLeftX < self.contentOffset.x) {
        CGFloat expectedContentOffset = selectedTabItemLeftX - self.bounds.size.width / 2;
        CGFloat minContentOffset = 0;
        CGFloat result = expectedContentOffset < minContentOffset ? minContentOffset : expectedContentOffset;
        //[self setContentOffset:CGPointMake(result, 0) animated:YES];
        [self animateContentOffset:CGPointMake(result, 0) withDuration:kAnimateDuration];
    }
}

#pragma mark - Setter
- (void)setSelectedLineColor:(UIColor *)selectedLineColor {
    _selectedLineColor = selectedLineColor;
    self.selectedLine.backgroundColor = selectedLineColor;
}

- (UIColor *)selectedLineColor {
    if (!_selectedLineColor) {
        _selectedLineColor = [UIColor orangeColor];
    }
    return _selectedLineColor;
}

- (void)setTitles:(NSArray *)titles {
    _titles = titles;
    if (self.tabItemList.count > 0) {
        NSInteger n = self.tabItemList.count;
        for (NSInteger i = 0; i < n; i++) {
            [self.tabItemList[i] removeFromSuperview];
        }
    }
    self.sectionStateList = [[self sectionStateListWithTitles:titles] mutableCopy];
    
    self.tabItemList = [self tabItemListWithTitles:titles];
    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    _needsLayoutTabItems = YES;
    [self setNeedsLayout];
}


#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // 输出点击的view的类名
//    NSLog(@"%@", NSStringFromClass([touch.view class]));
    
    // 若为UITableViewCellContentView（即点击了tableViewCell），则不截获Touch事件
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }
    return  YES;
}

#pragma mark - Getter
- (UIColor *)unSelectedColor {
    if (!_unSelectedColor) {
        _unSelectedColor = [UIColor blackColor];
    }
    
    return _unSelectedColor;
}

- (UIColor *)selectedColor {
    if (!_selectedColor) {
        _selectedColor = [UIColor orangeColor];
    }
    
    return _selectedColor;
}

#pragma mark - Setter
/// 根据下面的scrollView的contentOffset的变化来改变selectedLine的位置和长度，以及视情况改变tabBar的contentOffset来保证滑动结束后选中的tabItem的左边或右边能看到有其他的tabItem（如果选中的不是第一个或最后一个）
- (void)setPagerContentOffsetX:(CGFloat)pagerContentOffsetX {
    _pagerContentOffsetX = pagerContentOffsetX;
    NSInteger section = (pagerContentOffsetX + 0.5 * self.bounds.size.width) / self.bounds.size.width; //滑动超过一半就切换高亮的tabItem
    if (section != self.selectedIndexPath.section) {
        LFTabInfoModel *tabinfoModel = [self.sectionStateList objectAtIndex:section];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tabinfoModel.selectedIndex inSection:section];
        [self highlightTabItemAtIndexPath:indexPath];
    }
    
    NSInteger position = pagerContentOffsetX / self.bounds.size.width; //不动或者向右滑时为当前选中的tabItem的index，往左滑时为当前选中的tabItem的左边的index
    if (position == self.tabItemList.count - 1) { //防止后面position＋1溢出
        return;
    }
    CGFloat leftTabItemX = ((UIButton *)self.tabItemList[position]).center.x; //滑动过程中selectedLine左边的tabItem的位置
    CGFloat rightTabItemX = ((UIButton *)self.tabItemList[position + 1]).center.x; //滑动过程中selectedLine右边的tabItem的位置
    CGFloat scale = (pagerContentOffsetX - position * self.bounds.size.width) / self.bounds.size.width;
    CGFloat x = leftTabItemX + scale * (rightTabItemX - leftTabItemX); //计算selectedLine的位置
    self.selectedLine.center = CGPointMake(x, self.selectedLine.center.y);
    CGFloat leftTabItemWidth = ((UIButton *)self.tabItemList[position]).bounds.size.width;
    CGFloat rightTabItemWidth = ((UIButton *)self.tabItemList[position + 1]).bounds.size.width;
    CGFloat width = leftTabItemWidth + scale * (rightTabItemWidth - leftTabItemWidth); //计算selectedLine的宽度
    self.selectedLine.bounds = CGRectMake(0, 0, width, self.selectedLine.bounds.size.height);
    // scale在0.1到0.9之间才做出改变，防止快速滑动下面的scrollView，selectedLine掠过某个tabItem时scale从0突变为1或者从1突变为0造成tabBar闪烁
    if (0.1 < scale && scale < 0.9) {
        CGFloat newScale = scale * 1 / (0.9 - 0.1) - 0.1 / (0.9 - 0.1);//平滑scale的变化
//        if (self.scrollOrientation == SCROLL_ORIENTATION_RIGHT) {
//            if (self.tabBarRightDestX > self.contentOffset.x) {
//                self.contentOffset = CGPointMake(self.tabBarInitialX + newScale * (self.tabBarRightDestX - self.tabBarInitialX), 0);
//            }
//        } else if (self.scrollOrientation == SCROLL_ORIENTATION_LEFT) {
            if (self.tabBarLeftDestX < self.contentOffset.x) {
                self.contentOffset = CGPointMake(self.tabBarInitialX - (1 - newScale) * (self.tabBarInitialX - self.tabBarLeftDestX), 0);
            }
    }
//        }
//    } else {
//        self.scrollOrientation = SCROLL_ORIENTATION_NONE;
//    }
}

#pragma mark - Lazy
- (UIView *)selectedLine {
    if (!_selectedLine) {
        _selectedLine = [[UIView alloc]init];
        _selectedLine.backgroundColor = self.selectedLineColor;
    }
    
    return _selectedLine;
}

- (UIView *)listView {
    if (!_listView) {
        _listView = [[UIView alloc]init];
        _listView.hidden = YES;
        [self.superview addSubview:_listView];
        CGFloat y = CGRectGetMaxY(self.frame);
        CGFloat width =  [UIScreen mainScreen].bounds.size.width;
        CGFloat height = [UIScreen mainScreen].bounds.size.height;
        _listView.frame = CGRectMake(0, y, width, height);
        _listView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.3];
        [_listView addSubview:self.subTitleTableView];
        
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickListView:)];
        tapGesture.delegate = self;
        [_listView addGestureRecognizer:tapGesture];
    }
    
    return _listView;
}

- (UITableView *)subTitleTableView {
    if (!_subTitleTableView) {
        _subTitleTableView = [[UITableView alloc]init];
        _subTitleTableView.tableFooterView = [UIView new];
        _subTitleTableView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 0);
        _subTitleTableView.dataSource = self;
        _subTitleTableView.delegate = self;
    }
    
    return _subTitleTableView;
}

@end
