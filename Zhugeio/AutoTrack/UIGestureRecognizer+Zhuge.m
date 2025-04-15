//
//  UIGestureRecognizer+Zhuge.m
//  HelloZhuge
//
//  Created by Zhugeio on 2019/7/21.
//  Copyright © 2019 37degree. All rights reserved.
//

#import "UIGestureRecognizer+Zhuge.h"
#import <objc/runtime.h>
#import "ZhugeAutoTrackUtils.h"
#import "NSObject+ZGResponseID.h"
#import "ZGVisualizationManager.h"
#import "Zhuge.h"
@implementation UIGestureRecognizer (Zhuge)

- (void)trackGestureRecognizerAppClick:(UIGestureRecognizer *)gesture {
    @try {
        UIView *view = gesture.view;
        if ([[Zhuge sharedInstance] isViewTypeIgnored:view]) {
            return;
        }
        /*
         ps: 暂只采集 UILabel 和 UIImageView
         若需要添加其他类型的.可设置[Zhuge sharedInstance].config.customGestureViews = @[@"ZGTestGestureView"];
         */
        BOOL isTrackClass = [view isKindOfClass:UILabel.class] || [view isKindOfClass:UIImageView.class] || [ZGVisualizationManager zg_customGestureViewsHasContainCurrentView:view];
        
        if (!isTrackClass) {
            return;
        }
        
        [ZhugeAutoTrackUtils zhugeAutoTrackClick:view withController:nil andTag:@"type3"];
        //可视化埋点
        [[ZGVisualizationManager shareCustomerManger] zg_identificationAndUPloadWithView:view];
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
    self.zg_responseID = [NSString stringWithFormat:@"%@/%@",[target class],NSStringFromSelector(action)];
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
    self.zg_responseID = [NSString stringWithFormat:@"%@/%@",[target class],NSStringFromSelector(action)];
    [self zhuge_addTarget:target action:action];
}
@end
