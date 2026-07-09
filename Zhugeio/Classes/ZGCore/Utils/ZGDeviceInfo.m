//
//  ZGDeviceInfo.m
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2020/8/17.
//  Copyright © 2020 GoodMorning. All rights reserved.
//

#import "ZGDeviceInfo.h"
#import "sys/utsname.h"

@implementation ZGDeviceInfo

// 设备型号
+ (NSString *)getDeviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return deviceString;
}

@end
