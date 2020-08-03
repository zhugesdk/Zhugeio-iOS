//
//  ZGLocationManager.h
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2020/5/29.
//  Copyright © 2020 GoodMorning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ZGLocationSuccess) (double lng,double lat);
typedef void(^ZGLocationFailed) (NSError *error);

@interface ZGLocationManager : NSObject<CLLocationManagerDelegate> {
    
    CLLocationManager *manager;
    ZGLocationSuccess successCallBack;
    ZGLocationFailed failedCallBack;
    
}

+ (ZGLocationManager *)sharedManager;

+ (void)getZGLocationWithSuccess:(ZGLocationSuccess)success failed:(ZGLocationFailed)failed;

+ (void)stop;

@end

NS_ASSUME_NONNULL_END
