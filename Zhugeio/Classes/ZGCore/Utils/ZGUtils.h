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


// format dic
+ (NSMutableDictionary *)addSymbloToDic:(NSDictionary *)dic;

//生成128位秘钥
+ (NSString *)random128BitAESKey;

// 转json
+ (NSString*)dictionaryToJson:(NSDictionary *)dic;

+ (NSString *)parseUrl:(NSString *) url;

/**
 比较指定日期是否是同一天
 */
+ (BOOL)isDateToday:(NSDate *)date;

/**
检查是否有任何前台活跃的 Scene
 */
+(BOOL)hasAnyForegroundScene;

@end

NS_ASSUME_NONNULL_END

/// 安全取字符串
static inline NSString *ZGSafeStringFromDict(NSDictionary *dict, id key) {
    id v = dict[key];
    return [v isKindOfClass:[NSString class]] ? v : nil;
}
