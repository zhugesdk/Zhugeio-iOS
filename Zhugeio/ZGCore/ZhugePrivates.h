//
//  ZhugePrivates.h
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2021/1/18.
//  Copyright © 2021 GoodMorning. All rights reserved.
//


#import "Zhuge.h"

@interface Zhuge ()<ShakeGestureDelegate> {
    
}

@property (nonatomic, copy) NSString *apiURL;
@property (nonatomic, copy) NSString *backupURL;
@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *deviceId;
@property (nonatomic, strong) NSNumber *sessionId;
@property (nonatomic, strong) NSDate *screenShotTime;
@property (nonatomic, copy) NSString *deviceToken;
@property (nonatomic) UIBackgroundTaskIdentifier taskId;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSMutableArray *eventsQueue;
@property (nonatomic, strong) ZhugeConfig *config;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) NSUInteger sendCount;
@property (nonatomic, assign) SCNetworkReachabilityRef reachability;
@property (nonatomic, strong) CTTelephonyNetworkInfo *telephonyInfo;
@property (nonatomic, copy) NSString *net;
@property (nonatomic, copy) NSString *radio;
@property (nonatomic, copy) NSString *cr;
@property (nonatomic, strong) NSMutableDictionary *eventTimeDic;
@property (nonatomic, strong) NSMutableDictionary *envInfo;
@property (nonatomic, assign) NSInteger  zhugeSeeReal;
@property (nonatomic, copy) NSString *zhugeSeeNet;
@property (nonatomic, copy) NSString *ZGPublicKey;
@property (nonatomic, copy) NSString *ZGPublicMD5;

@property (nonatomic, strong) NSNumber *lastSessionId;

@property (nonatomic, assign) BOOL isForeground;
@property (nonatomic) volatile int32_t sessionCount; //毫秒偏移量
@property (nonatomic) volatile int32_t seeCount;
@property (nonatomic, assign) BOOL localZhugeSeeState;

@property (nonatomic, strong) NSMutableArray * archiveEventQueue;
@property (nonatomic, strong) NSMutableDictionary * utmDic;
@property (nonatomic, assign) int retryPost;

@property (nonatomic, strong) CMMotionManager *motionManager;

// 判断 viewDidAppear 是否已经被 hook
@property (nonatomic, assign) BOOL viewDidAppearIsHook;
// 判断 viewDidDisappear 是否已经被 hook
@property (nonatomic, assign) BOOL viewDidDisappearIsHook;

/**
 * 根据deepShare是否已经返回结果来判断是否开始上传数据 默认为NO。
 */
@property (nonatomic, assign) BOOL flushBool;

@property (nonatomic, strong) NSMutableArray *ignoredViewTypeList;

@property (nonatomic, assign) BOOL isInitSDK;


#pragma mark - Codeless

@property (nonatomic, strong) ShakeGesture *shakeGesture;
@property (nonatomic, strong) ZGABTestDesignerConnection *abtestDesignerConnection;
@property (nonatomic, copy) NSString *websocketUrl;
@property (nonatomic, copy) NSString *codelessEventsUrl;
@property (nonatomic, strong) NSSet *variants;
@property (nonatomic, strong) NSSet *eventBindings;
@property (nonatomic, strong) NSNumber *preTime;

@end


