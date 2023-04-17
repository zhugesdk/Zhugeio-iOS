//
//  UIWindow+ZGView.h
//  FQ_AlertTipView
//
//  Created by 范奇 on 2023/2/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (ZGView)

/// 获取当前最上层全屏视图
- (UIView *)zg_subFullElement;

/// 获取当前的window
+ (UIWindow *)zg_currentWindow;

@end

NS_ASSUME_NONNULL_END
