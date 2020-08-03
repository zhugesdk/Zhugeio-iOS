//
//  ZGCMMotionManager.m
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2020/7/12.
//  Copyright © 2020 GoodMorning. All rights reserved.
//

#import "ZGCMMotionManager.h"
#import <CoreMotion/CoreMotion.h>

@interface ZGCMMotionManager ()

@property (nonatomic, strong) CMMotionManager *motionManager;

@end

@implementation ZGCMMotionManager

+ (ZGCMMotionManager *)sharedManager {
    static ZGCMMotionManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[ZGCMMotionManager alloc]init];
    });
    return shared;
}

-(NSString *)setupGyro {
    // 1.初始化运动管理对象
    self.motionManager = [[CMMotionManager alloc] init];
    // 2.判断加速计是否可用
    if (![self.motionManager isAccelerometerAvailable]) {
        return @"加速计不可用";
    }
    // 3.设置加速计更新频率，以秒为单位
    self.motionManager.accelerometerUpdateInterval = 0.1;
    // 4.开始实时获取
    __block NSString *gyro = @"";
    [self.motionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
        //获取加速度
        CMAcceleration acceleration = accelerometerData.acceleration;
//        NSLog(@"加速度 == x:%f, y:%f, z:%f", acceleration.x, acceleration.y, acceleration.z);
        gyro = [NSString stringWithFormat:@"x:%f, y:%f, z:%f",acceleration.x, acceleration.y, acceleration.z];
//        return [NSString stringWithFormat:@"x:%f, y:%f, z:%f",acceleration.x, acceleration.y, acceleration.z];
    }];
    return gyro;
}

@end
