//
//  ZGLocationManager.m
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2020/5/29.
//  Copyright © 2020 GoodMorning. All rights reserved.
//

#import "ZGLocationManager.h"
#import <UIKit/UIKit.h>

@implementation ZGLocationManager

+ (ZGLocationManager *)sharedManager {
    static ZGLocationManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[ZGLocationManager alloc]init];
    });
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        manager = [[CLLocationManager alloc] init];
        manager.delegate = self;
        manager.desiredAccuracy = kCLLocationAccuracyBest;
        
        // 请求授权 requestWhenInUseAuthorization用在>=iOS8.0上
        // respondsToSelector: 前面manager是否有后面requestWhenInUseAuthorization方法
        // 1. 适配 动态适配
        if ([manager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [manager requestWhenInUseAuthorization];
            [manager requestAlwaysAuthorization];
        }
        // 2. 另外一种适配 systemVersion 有可能是 8.1.1
        float osVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        if (osVersion >= 8) {
            [manager requestWhenInUseAuthorization];
            [manager requestAlwaysAuthorization];
        }
        
    }
    return self;
}

- (void) getZGLocationWithSuccess:(ZGLocationSuccess)succsess failed:(ZGLocationFailed)failed {
    successCallBack = [succsess copy];
    failedCallBack  = [failed copy];
    
    [manager stopUpdatingLocation];
    
    [manager startUpdatingLocation];
}

+ (void)getZGLocationWithSuccess:(ZGLocationSuccess)success failed:(ZGLocationFailed)failed {
    [[ZGLocationManager sharedManager] getZGLocationWithSuccess:success failed:failed];
}

- (void)stop {
    [manager stopUpdatingLocation];
}

+ (void)stop {
    [[ZGLocationManager sharedManager] stop];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    for (CLLocation *loc in locations) {
        CLLocationCoordinate2D l = loc.coordinate;
        double lng = l.longitude;
        double lat = l.latitude;

        NSLog(@"lng lat == (%f, %f)", lng, lat);
        
        successCallBack ? successCallBack(lng, lat) : nil;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    failedCallBack ? failedCallBack(error) : nil;
    if ([error code] == kCLErrorDenied) {
        NSLog(@"访问被拒绝");
    }
    if ([error code] == kCLErrorLocationUnknown) {
        NSLog(@"无法获取位置信息");
    }
}

@end
