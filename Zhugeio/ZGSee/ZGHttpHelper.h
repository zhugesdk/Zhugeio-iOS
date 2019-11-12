//
//  ZGHttpHelper.h
//  HelloZhuge
//
//  Created by jiaokang on 2018/9/5.
//  Copyright © 2018年 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZGReachability.h"
@interface ZGHttpHelper : NSObject

+ (BOOL)isExistenceNetwork;//检查网络是否可用
+ (void)post:(NSString *)Url RequestStr:(NSString *)str FinishBlock:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) block;//post请求封装
+ (void)post:(NSString *)Url RequestParams:(NSMutableDictionary *)params FinishBlock:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) block;//post请求封装

+ (void)sendRequestForUrl:(NSString *)urlString FinishBlock:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) block;
@end
