//
//  UIApplication+Zhuge.m
//  HelloZhuge
//
//  Created by Zhugeio on 2018/9/5.
//  Copyright © 2018年 37degree. All rights reserved.
//

#import "UIApplication+Zhuge.h"
#import "Zhuge.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "ZhugeAutoTrackUtils.h"
#import "ZGVisualizationManager.h"
static char kZGEventTrackedKey;
@implementation UIApplication (Zhuge)


-(BOOL)zhuge_sendAction:(SEL)action to:(id)to from:(id)from forEvent:(UIEvent *)event{

    /*
     默认先执行 AutoTrack
     如果先执行原点击处理逻辑，可能已经发生页面 push 或者 pop，导致获取当前 ViewController 不正确
     */

    @try {
        if ([self needCheckActionWithEvent:event]) {
            [self zhuge_track:action to:to from:from forEvent:event];
            //可视化埋点.
            [[ZGVisualizationManager shareCustomerManger] zg_identificationAndUPloadWithView:from];
        }
    } @catch (NSException *exception) {
        NSLog(@"%@ error: %@", self, exception);
    }
    return [self zhuge_sendAction:action to:to from:from forEvent:event];
}
-(BOOL)needCheckActionWithEvent:(UIEvent *)event{
    if (![event isKindOfClass:[UIEvent class]]) return NO;
    if (event.type != UIEventTypeTouches) return NO;

    NSSet<UITouch *> *touches = event.allTouches;
    UITouch *endedTouch = nil;
    for (UITouch *t in touches) {
        if (t.phase == UITouchPhaseEnded) {
            endedTouch = t;
            break;
        }
    }
    if (!endedTouch) return NO;
    
    // 检查 UIEvent 是否已经统计过
    NSNumber *tracked = objc_getAssociatedObject(endedTouch, &kZGEventTrackedKey);
    if (tracked.boolValue) {
        // 已经统计过
        return NO;
    }
    // 设置标记，表示这个 event 已经统计
    objc_setAssociatedObject(endedTouch, &kZGEventTrackedKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return YES;
}
- (void)zhuge_track:(SEL)action to:(id)to from:(id)from forEvent:(UIEvent *)event {
    //非全埋点不处理
    if([Zhuge autoTrackInstance].count <= 0){
        return;
    }
    // ViewType 被忽略
    if ([to isKindOfClass:[UITabBar class]]) {
        return;
    }
    BOOL isTabBar = [from isKindOfClass:[UITabBarItem class]] && [to isKindOfClass:[UITabBarController class]];

    
    if ([from isKindOfClass:[UISwitch class]] ||
        [from isKindOfClass:[UIStepper class]] ||
        [from isKindOfClass:[UISegmentedControl class]] ||
        [from isKindOfClass:[UITabBarItem class]]) {
        [ZhugeAutoTrackUtils zhugeAutoTrackClick:from withController:isTabBar ? (UITabBarController *)to : nil andTag:@"type1"];
        return;
    }
    [ZhugeAutoTrackUtils zhugeAutoTrackClick:from withController:isTabBar ? (UITabBarController *)to : nil andTag:@"type2"];
}

@end
