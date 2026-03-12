//
//  ZGDeviceInfo.h
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2020/8/17.
//  Copyright © 2020 GoodMorning. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGDeviceInfo : NSObject


// 设备型号
+ (NSString *)getDeviceModel;
+ (NSString *)getSysInfoByName:(char *)typeSpecifier;


// 是否越狱
+ (BOOL)isJailBroken;

// 分辨率
+ (NSString *)resolution;

// 是否破解
+ (BOOL)isPirated;

+ (NSString *)userAgent;


@end

NS_ASSUME_NONNULL_END
