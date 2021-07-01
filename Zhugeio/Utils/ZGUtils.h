//
//  ZGUtils.h
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2020/5/15.
//  Copyright © 2020 GoodMorning. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGUtils : NSObject

+ (NSString *)getCurrentTimestamp;

+ (NSString *)currentDate;

/*
 *  ZGSEE API Format
 */
+ (NSString *)getZGSeeUploadUrl:(NSString *)api;

+ (NSString *)getZGSeePolicyUrl:(NSString *)api appkey:(NSString *)appkey;

// format dic
+ (NSMutableDictionary *)addSymbloToDic:(NSDictionary *)dic;

//生成128位秘钥
+ (NSString *)random128BitAESKey;

// 转json
+ (NSString*)dictionaryToJson:(NSDictionary *)dic;

+ (NSString *)parseUrl:(NSString *) url;

@end

NS_ASSUME_NONNULL_END
