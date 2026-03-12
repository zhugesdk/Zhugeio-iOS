//
//  ZhugePrivates.h
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2021/1/18.
//  Copyright © 2021 GoodMorning. All rights reserved.
//


#import "Zhuge.h"
#import "ZhugeDbAdapter.h"

@interface Zhuge ()
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *appSocketToken;
@property (nonatomic, strong) NSNumber *sessionId;
@property (nonatomic, strong) NSDate *screenShotTime;
@property (nonatomic) UIBackgroundTaskIdentifier taskId;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) dispatch_queue_t uploadQueue;
@property (nonatomic, strong) NSMutableArray *eventsQueue;
@property (nonatomic, strong) ZhugeConfig *config;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) NSUInteger sendCount;
@property (nonatomic, assign) SCNetworkReachabilityRef reachability;
@property (nonatomic, strong) CTTelephonyNetworkInfo *telephonyInfo;
@property (nonatomic, copy) NSString *net;
@property (nonatomic, copy) NSString *radio;
@property (nonatomic, copy) NSString *cr;
//最后一次成功上传归因数据时的应用版本
@property (nonatomic, copy) NSString *lastUploadAdInfoAppVersion;
@property (nonatomic, strong) NSMutableDictionary *eventTimeDic;
@property (nonatomic, strong) NSMutableDictionary *envInfo;


@property (nonatomic, strong) NSNumber *lastSessionActiveTime;

@property (nonatomic, assign) BOOL isForeground;
@property (atomic, assign) BOOL allowUplode;
@property (nonatomic) volatile int32_t sessionCount; //毫秒偏移量

@property (nonatomic, strong) NSMutableArray * archiveEventQueue;
@property (nonatomic, strong) NSMutableDictionary * utmDic;

@property (nonatomic, strong) ZhugeDbAdapter *dbAdapter;

@property (nonatomic, strong) NSMutableArray *ignoredViewTypeList;

@property (nonatomic, assign) BOOL isInitSDK;
@property (nonatomic, strong) NSDate *uploadDate;


#pragma mark - Codeless

@property (nonatomic, strong) ZGABTestDesignerConnection *abtestDesignerConnection;

@end


