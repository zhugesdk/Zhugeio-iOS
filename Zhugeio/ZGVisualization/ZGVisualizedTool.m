//
//  ZGVisualizedTool.m
//  ZGTestDemo
//
//  Created by 范奇 on 2023/2/23.
//

#import "ZGVisualizedTool.h"
#import "UIWindow+ZGView.h"

@implementation ZGVisualizedTool

+ (BOOL)zg_isCoveredForView:(UIView *)view {
    BOOL covered = NO;
    
    //保障精确度.查找到第 4 层
    NSArray <UIView *> *allOtherViews = [self findAllPossibleCoverViews:view hierarchyCount:4];

    UIWindow * window = [UIWindow zg_currentWindow];
    // 遍历判断是否存在覆盖
    CGRect rect = [view convertRect:view.bounds toView:window];
    // 视图可能超出屏幕，计算 keywindow 交集，即在屏幕显示的有效区域
    CGRect keyWindowFrame = window.frame;
    rect = CGRectIntersection(keyWindowFrame, rect);

    for (UIView *otherView in allOtherViews) {
        /*
         不考虑这种情况,这么处理,就是一个视图盖在上面.但是是透明的.不影响事件.
         */
        CGRect otherRect = [otherView convertRect:otherView.bounds toView:window];
        if (CGRectContainsRect(otherRect, rect)) {
            return YES;
        }
    }
    return covered;
}


// 根据层数，查询一个 view 所有可能覆盖的 view
+ (NSArray *)findAllPossibleCoverViews:(UIView *)view hierarchyCount:(NSInteger)count {
    NSMutableArray <UIView *> *allOtherViews = [NSMutableArray array];
    NSInteger index = count;
    UIView *currentView = view;
    while (index > 0 && currentView) {
        NSArray *allBrotherViews = [self findPossibleCoverAllBrotherViews:currentView];
          if (allBrotherViews.count > 0) {
              [allOtherViews addObjectsFromArray:allBrotherViews];
          }
        currentView = currentView.superview;
        index--;
    }
    return [allOtherViews copy];
}


// 寻找一个 view 同级的后添加的 view
+ (NSArray *)findPossibleCoverAllBrotherViews:(UIView *)view {
    __block NSMutableArray <UIView *> *otherViews = [NSMutableArray array];
    UIView *superView = view.superview;
    if (superView) {
        // 逆序遍历
        [superView.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIView *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if (obj == view) {
                *stop = YES;
            } else if (obj.alpha > 0 && !obj.hidden && obj.userInteractionEnabled) { // userInteractionEnabled 为 YES 才有可能遮挡响应事件
                [otherViews addObject:obj];
            }
        }];
    }
    return otherViews;
}


@end
