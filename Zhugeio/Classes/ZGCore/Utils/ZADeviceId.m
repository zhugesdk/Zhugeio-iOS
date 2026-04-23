//
//  ZADeviceId.m
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/5/12.
//

/**
 * 先从 keychain 获取 zaid
 * 如果获取不到 生成新的 zaid 存到 keychain
 * return zaid
 */

#import "ZADeviceId.h"
#import "ZGLog.h"

@implementation ZADeviceId

+ (NSString *)getZADeviceId {
    // IDFA
    NSString *deviceId = NULL;
    
    // 优先使用 IDFV：Apple 官方推荐的厂商标识，卸载重装自动重置（符合隐私设计）
    if (NSClassFromString(@"UIDevice")) {
        deviceId = [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
    
    // 降级：UUID 存入 UserDefaults，卸载即清除，不存在跨安装追踪问题
    if (!deviceId) {
        deviceId = [self idFromUserDefaults];
    }
    return deviceId;
}


+ (NSString *)idFromUserDefaults {
    static NSString * const kDeviceIdKey = @"zgid_uuid";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [defaults stringForKey:kDeviceIdKey];

    if (!uuid) {
        uuid = [[NSUUID UUID] UUIDString];
        [defaults setObject:uuid forKey:kDeviceIdKey];
    }
    return uuid;
}


@end
