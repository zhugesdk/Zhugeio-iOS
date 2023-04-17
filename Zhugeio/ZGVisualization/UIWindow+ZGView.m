//
//  UIWindow+ZGView.m
//  FQ_AlertTipView
//
//  Created by 范奇 on 2023/2/23.
//

#import "UIWindow+ZGView.h"
#import "UIView+ZGView.h"

@implementation UIWindow (ZGView)

- (UIView *)zg_subFullElement {
    CGSize fullScreenSize = UIScreen.mainScreen.bounds.size;
    __block UIView * fullView = nil;
    // 逆序遍历，从而确保从最上层开始查找，直到全屏 view 停止
    [self.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGRect rect = [obj convertRect:obj.bounds toView:nil];
        BOOL isFullScreenShow = CGPointEqualToPoint(rect.origin, CGPointZero) && CGSizeEqualToSize(rect.size, fullScreenSize);
        if (isFullScreenShow && obj.zg_isVisible && obj.userInteractionEnabled == YES) {
            fullView = obj;
            *stop = YES;
        }
    }];
    // 再逆序翻转，保证和显示优先级一致
    return fullView ? fullView : self;
}


/// 获取当前显示的 window
+ (UIWindow *)zg_currentWindow {
    UIWindow *keyWindow = nil;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in windowScene.windows) {
                    // 可能创建的 window 被隐藏
                    if (![self isVisibleForView:window]) {
                        continue;
                    }
                    // iOS 13 及以上，可能动态设置其他 window 为 keyWindow，此时直接使用此 keyWindow
                    if (window.isKeyWindow) {
                        return window;
                    }
                    // 获取 windowScene.windows 中第一个 window
                    if (!keyWindow) {
                        keyWindow = window;
                    }
                }
                break;
            }
        }
    }
#endif
    return keyWindow ?: [self topWindow];
}
 
+ (UIWindow *)topWindow {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    NSArray<UIWindow *> *allWindows = [UIApplication sharedApplication].windows;
 
    // 逆序遍历，获取最上层全屏可见 window
    CGSize fullScreenSize = [UIScreen mainScreen].bounds.size;
    for (UIWindow *window in [allWindows reverseObjectEnumerator]) {
        if ([window isMemberOfClass:UIWindow.class] && CGSizeEqualToSize(fullScreenSize, window.frame.size) && [self isVisibleForView:window]) {
            return window;
        }
    }
    return nil;
}

+(BOOL)isVisibleForView:(UIWindow *)window{
    if(window.bounds.size.width == 0 || window.bounds.size.height == 0){
        return NO;
    }
    return window.hidden == NO && window.alpha > 0.01;
}


@end
