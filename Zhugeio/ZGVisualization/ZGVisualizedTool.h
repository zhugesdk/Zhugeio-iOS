//
//  ZGVisualizedTool.h
//  ZGTestDemo
//
//  Created by 范奇 on 2023/2/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGVisualizedTool : NSObject

/// 判断一个 view 是否被覆盖
+ (BOOL) zg_isCoveredForView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
