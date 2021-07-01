//
//  ZGUtils.m
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2020/5/15.
//  Copyright © 2020 GoodMorning. All rights reserved.
//

#import "ZGUtils.h"
#import <sys/sysctl.h>
#import <mach/mach.h>
#import<SystemConfiguration/CaptiveNetwork.h>
#import "ZGCMMotionManager.h"

@interface ZGUtils ()

@end

@implementation ZGUtils

//当前时间戳 精确到毫秒
+ (NSString *)getCurrentTimestamp {
    NSString *tempString = [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970] * 1000];
    return tempString;
}

+ (NSString *)currentDate{
    NSDate *date = [NSDate date];
    NSDateFormatter *fm = [[NSDateFormatter alloc]init];
    [fm setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [fm stringFromDate:date];
}

#pragma mark ZGSEE
+ (NSString *)getZGSeeUploadUrl:(NSString *)api{
    return [api stringByAppendingString:@"/sdk_zgsee"];
}

+ (NSString *)getZGSeePolicyUrl:(NSString *)api appkey:(NSString *)appkey{
    return [api stringByAppendingFormat:@"/appkey/%@",appkey];
}

// format dic
+ (NSMutableDictionary *)addSymbloToDic:(NSDictionary *)dic{
    NSMutableDictionary *copy = [NSMutableDictionary dictionaryWithCapacity:[dic count]];
    for (NSString *key in dic) {
        id value = dic[key];
        NSString *newKey = [NSString stringWithFormat:@"_%@",key];
        [copy setValue:value forKey:newKey];
    }
    return copy;
}


//生成128位秘钥
+ (NSString *)random128BitAESKey {
    uint8_t randomBytes [16];
    int result = SecRandomCopyBytes(kSecRandomDefault,8,randomBytes);
    if(result == errSecSuccess){
        NSMutableString * uuidStringReplacement = [[NSMutableString alloc] initWithCapacity:8 * 2];
        for(NSInteger index = 0; index< 8; index ++) {
            [uuidStringReplacement appendFormat:@"%02x",randomBytes [index]];
        }
        return uuidStringReplacement;
    } else {
        NSLog(@"SecRandomCopyBytes由于某种原因失败");
        return @"";
    }
    return @"";
}

// dic to json string
+ (NSString*)dictionaryToJson:(NSDictionary *)dic {
    NSError *parseError = nil;
    if (dic == nil) {
        return nil;
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

// json string to dic
//+ (NSDictionary *)jsonToDictionary:(NSString *)jsonString {
//
//}

+ (NSString *)parseUrl:(NSString *) url{
    NSString * result;
    if ([url hasSuffix:@"/"]) {
        result = [url substringToIndex:[url length] - 1];
    }else{
        result = url;
    }
    if ([result hasSuffix:@"/apipool"] || [result hasSuffix:@"/APIPOOL"] ) {
        result = [result substringToIndex:[result length] - 8];
    }
    return result;
}

@end
