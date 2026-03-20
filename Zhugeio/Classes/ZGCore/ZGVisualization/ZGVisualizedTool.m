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
    if (!view.window || view.hidden || view.alpha <= 0.01 || !view.userInteractionEnabled) {
        return YES;
    }
    UIWindow *window = view.window;
    CGPoint centerInBounds = CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds));
    CGPoint point = [view convertPoint:centerInBounds toView:window];
    
    UIView *hitView = [window hitTest:point withEvent:nil];
    if (hitView == view || [hitView isDescendantOfView:view]) {
        return NO;
    }
    // 如果点到的不是自己（或子 view），说明被挡住
    return !(hitView == view || [hitView isDescendantOfView:view]);
}


// 根据层数，查询一个 view 所有可能覆盖的 view
//+ (NSArray *)findAllPossibleCoverViews:(UIView *)view hierarchyCount:(NSInteger)count {
//    NSMutableArray <UIView *> *allOtherViews = [NSMutableArray array];
//    NSInteger index = count;
//    UIView *currentView = view;
//    while (index > 0 && currentView) {
//        NSArray *allBrotherViews = [self findPossibleCoverAllBrotherViews:currentView];
//          if (allBrotherViews.count > 0) {
//              [allOtherViews addObjectsFromArray:allBrotherViews];
//          }
//        currentView = currentView.superview;
//        index--;
//    }
//    return [allOtherViews copy];
//}
//
//
//// 寻找一个 view 同级的后添加的 view
//+ (NSArray *)findPossibleCoverAllBrotherViews:(UIView *)view {
//    __block NSMutableArray <UIView *> *otherViews = [NSMutableArray array];
//    UIView *superView = view.superview;
//    if (superView) {
//        // 逆序遍历
//        [superView.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIView *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
//            if (obj == view) {
//                *stop = YES;
//            } else if (obj.alpha > 0 && !obj.hidden && obj.userInteractionEnabled) { // userInteractionEnabled 为 YES 才有可能遮挡响应事件
//                [otherViews addObject:obj];
//            }
//        }];
//    }
//    return otherViews;
//}


@end
