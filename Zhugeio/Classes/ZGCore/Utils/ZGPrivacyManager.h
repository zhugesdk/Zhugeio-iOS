//
//  ZGPrivacyManager.h
//  Pods
//
//  Created by kang on 2025/7/20.
//


#import <Foundation/Foundation.h>

@interface ZGPrivacyManager : NSObject

+ (instancetype)sharedManager;

/// 设置用户是否同意隐私协议（YES: 同意）
- (void)setUserAgreed:(BOOL)agreed;

- (void)setPrivacyControl:(BOOL)enable;

/// 获取用户是否已同意
- (BOOL)isUserAgreed;

@end
