//
//  UIGestureRecognizer+Zhuge.m
//  HelloZhuge
//
//  Created by jiaokang on 2019/7/21.
//  Copyright © 2019 37degree. All rights reserved.
//

#import "UIGestureRecognizer+Zhuge.h"
#import <objc/runtime.h>
#import "ZhugeAutoTrackUtils.h"
@implementation UIGestureRecognizer (Zhuge)

- (void)trackGestureRecognizerAppClick:(UIGestureRecognizer *)gesture {
    @try {
        UIView *view = gesture.view;
        // 暂只采集 UILabel 和 UIImageView
        BOOL isTrackClass = [view isKindOfClass:UILabel.class] || [view isKindOfClass:UIImageView.class];
        
        if (!isTrackClass) {
            return;
        }
        [ZhugeAutoTrackUtils zhugeAutoTrackClick:view withController:nil andTag:@"type3"];
    } @catch (NSException *exception) {
        NSLog(@"%@ error: %@", self, exception);
    }
}

@end


@implementation UITapGestureRecognizer (Zhuge)

- (instancetype)zhuge_initWithTarget:(id)target action:(SEL)action {
    [self zhuge_initWithTarget:target action:action];
    [self removeTarget:target action:action];
    [self addTarget:target action:action];
    return self;
}

- (void)zhuge_addTarget:(id)target action:(SEL)action {
    [self zhuge_addTarget:self action:@selector(trackGestureRecognizerAppClick:)];
    [self zhuge_addTarget:target action:action];
}

@end



@implementation UILongPressGestureRecognizer (Zhuge)

- (instancetype)zhuge_initWithTarget:(id)target action:(SEL)action {
    [self zhuge_initWithTarget:target action:action];
    [self removeTarget:target action:action];
    [self addTarget:target action:action];
    return self;
}

- (void)zhuge_addTarget:(id)target action:(SEL)action {
    [self zhuge_addTarget:self action:@selector(trackGestureRecognizerAppClick:)];
    [self zhuge_addTarget:target action:action];
}
@end
