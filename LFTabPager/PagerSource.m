//
//  PagerSource.m
//  LFTabPager
//
//  引用参考：https://github.com/NazgulLee/LJTabPager
//
//  源代码区：https://github.com/lefengxu/LFTabPager
//
//  Created by 许乐峰 on 2018/4/16.
//  Copyright © 2018年 xulefeng. All rights reserved.
//

#import "PagerSource.h"
#import "TableViewController.h"

@implementation PagerSource

- (NSInteger)numberOfViewControllersInSection:(NSInteger)section {
    NSInteger number = 0;
    if (0 == section) {
        number = 2;
    } else if (1 == section) {
        number = 2;
    } else {
        number = 3;
    }
    
    return number;
}

- (NSInteger)numberOfSections {
    return 3;
}

- (NSArray *)titles {
    //    NSArray *array = @[@[@"个性推荐", @"单曲"], @[@"歌单", @"相声"], @"主播电台", @"排行榜", @"用户", @"歌手", @"专辑"];
    NSArray *array = @[@[@"个性推荐", @"单曲"], @[@"歌单", @"相声"], @"主播电台"];
    return array;
}


- (UIViewController *)viewControllerAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.item;
    NSInteger section = indexPath.section;
    TableViewController *controller = [[TableViewController alloc] init];
    
    if (0 == section) {
        if (0 == index) {
            controller.title = @"个性推荐";
        } else {
            controller.title = @"单曲";
        }
        
    } else if (1 == section) {
        if (0 == index) {
            controller.title = @"歌单";
        } else {
            controller.title = @"相声";
        }
    }
    
    switch (section) {
        case 2:
            controller.title = @"主播电台";
            break;
        case 3:
            controller.title = @"排行榜";
            break;
        case 4:
            controller.title = @"用户";
            break;
        case 5:
            controller.title = @"歌手";
            break;
        case 6:
            controller.title = @"专辑";
            break;
        default:
            break;
    }
    
    return controller;
}

@end
