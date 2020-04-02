//
//  UIApplication+Zhuge.m
//  HelloZhuge
//
//  Created by jiaokang on 2018/9/5.
//  Copyright © 2018年 37degree. All rights reserved.
//

#import "UIApplication+Zhuge.h"
#import "Zhuge.h"
#import "ZGSharedDur.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "ZhugeAutoTrackUtils.h"

@implementation UIApplication (Zhuge)

-(BOOL)zhuge_sendAction:(SEL)action to:(id)to from:(id)from forEvent:(UIEvent *)event{

    /*
     默认先执行 AutoTrack
     如果先执行原点击处理逻辑，可能已经发生页面 push 或者 pop，导致获取当前 ViewController 不正确
     */

    @try {
        [self zhuge_track:action to:to from:from forEvent:event];
    } @catch (NSException *exception) {
        NSLog(@"%@ error: %@", self, exception);
    }
    return [self zhuge_sendAction:action to:to from:from forEvent:event];
}

- (void)zhuge_track:(SEL)action to:(id)to from:(id)from forEvent:(UIEvent *)event {
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
    
    if ([event isKindOfClass:[UIEvent class]] && event.type == UIEventTypeTouches && [[[event allTouches] anyObject] phase] == UITouchPhaseEnded) {
        [ZhugeAutoTrackUtils zhugeAutoTrackClick:from withController:isTabBar ? (UITabBarController *)to : nil andTag:@"type2"];
        return;
    }
    
}


@end
