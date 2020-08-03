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

@end
