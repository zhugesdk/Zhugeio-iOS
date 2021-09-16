#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif
//
//  Zhuge.m
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import "Zhuge.h"
#import "ZGLog.h"
#import "ZhugePrivates.h"


@implementation Zhuge

static NSUncaughtExceptionHandler *previousHandler;
static void ZhugeReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    if (info != NULL && [(__bridge NSObject*)info isKindOfClass:[Zhuge class]]) {
        @autoreleasepool {
            Zhuge *zhuge = (__bridge Zhuge *)info;
            [zhuge reachabilityChanged:flags];
        }
    }
}

#pragma mark - 初始化
+ (Zhuge *)sharedInstance {
    static Zhuge *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once (&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
        sharedInstance.config = [[ZhugeConfig alloc] init];
        sharedInstance.eventTimeDic = [[NSMutableDictionary alloc]init];
    });
    return sharedInstance;
}

- (ZhugeConfig *)config {
    return _config;
}

- (void)startWithAppKey:(NSString *)appKey andDid:(NSString *)did launchOptions:(NSDictionary *)launchOptions{
    self.deviceId = did;
    [self initWithAppKey:appKey launchOptions:launchOptions withDelegate:nil];
}

- (void)startWithAppKey:(NSString *)appKey launchOptions:(NSDictionary *)launchOptions {
    [self initWithAppKey:appKey launchOptions:launchOptions withDelegate:nil];
}

// 需要DeepShare时，调用此 star 方法
- (void)startWithAppKey:(NSString *)appKey launchOptions:(NSDictionary *)launchOptions delegate:(id)delegate {
    [self initWithAppKey:appKey launchOptions:launchOptions withDelegate:delegate];
}

- (void)startWithAppKey:(NSString *)appKey andDid:(NSString *)did launchOptions:(NSDictionary *)launchOptions withDelegate:(id)delegate {
    self.deviceId = did;
    [self initWithAppKey:appKey launchOptions:launchOptions withDelegate:delegate];
}

- (void)initWithAppKey:(NSString *)appKey launchOptions:(NSDictionary *)launchOptions withDelegate:(id)delegate{
    @try {
        if (appKey == nil || [appKey length] == 0) {
            ZGLogError(@"appKey不能为空。");
            return;
        }
        self.appKey = appKey;
        self.flushBool = NO;
        self.userId = @"";
        self.deviceToken = @"";
        self.sessionId = nil;
        self.net = @"";
        self.radio = @"";
        self.telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
        self.taskId = UIBackgroundTaskInvalid;
        NSString *label = [NSString stringWithFormat:@"io.zhuge.%@.%p", appKey, self];
        self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        self.eventsQueue = [[NSMutableArray alloc] init];
        self.archiveEventQueue = [[NSMutableArray alloc] init];
        self.ignoredViewTypeList = [[NSMutableArray alloc] init];
        self.variants = [NSSet set];
        self.eventBindings = [NSSet set];
        self.cr = [self carrier];
        
//        [[ZGSqliteManager shareManager] openDataBase];
        
        if (!self.apiURL || self.apiURL.length == 0) {
            self.apiURL = ZG_BASE_API;
            self.backupURL = ZG_BACKUP_API;
        }
        
        if (!self.websocketUrl || self.websocketUrl.length == 0) {
            self.websocketUrl = CODELESS_WEB_SOCKET_URL;
            self.codelessEventsUrl = CODELESS_GET_EVENTS_URL;
        }
        
        
        if (self.config.zgSeeEnable) {
            //初始化zhugesee变量
            self.zhugeSeeNet = @"4";
            self.zhugeSeeReal = 1;
            //判断是否开启zgSee
            [self zgSeeBool];
        }
        
        if (self.config.enableJavaScriptBridge) {
            [self swizzleWebViewMethod];
        }
        
        // SDK配置
        if(self.config) {
            ZGLogInfo(@"SDK系统配置: %@", self.config);
        }
        if (self.config.debug) {
            [self.config setSendInterval:2];
        }

        [self setupListeners];
        [self unarchive];
        if (launchOptions && launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
            [self trackPush:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] type:@"launch"];
        }
        
        if (!self.deviceId) {
            self.deviceId = [ZADeviceId getZADeviceId];
        }
        if (self.config.exceptionTrack) {
            previousHandler = NSGetUncaughtExceptionHandler();
            NSSetUncaughtExceptionHandler(&ZhugeUncaughtExceptionHandler);
        }
        
        if (self.config.enableCodeless) {
#if TARGET_IPHONE_SIMULATOR
            [self connectToWebSocket];
#else
            self.shakeGesture = [[ShakeGesture alloc] init];
            self.shakeGesture.delegate = self;
#endif
        }
        
        if (delegate) {
            self.delegate = delegate;
            [DeepShare initWithAppID:self.appKey withLaunchOptions:launchOptions withDelegate:self];
        }
        
        if (!self.sessionId) {
            [self sessionStart];
        }
        
        self.isInitSDK = YES;
        
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"startWithAppKey exception %@",exception);
    }
}

- (void)trackException:(NSException *) exception{
    NSArray * arr = [exception callStackSymbols];
    NSString * reason = [exception reason]; // 崩溃的原因  可以有崩溃的原因(数组越界,字典nil,调用未知方法...) 崩溃的控制器以及方法
    NSString * name = [exception name];
    NSMutableString *stack = [NSMutableString string];
    long sum = 0;
    for (NSString *ele in arr) {
        sum = sum + ele.length;
        if ((sum + 5) >256) {
            break;
        }
        [stack appendString:[ele stringByReplacingOccurrencesOfString:@" " withString:@""]];
        [stack appendString:@" \n "];
    }
    NSMutableDictionary *pr = [self eventData];
    pr[@"$异常名称"]=name;
    pr[@"$异常描述"]=reason;
    pr[@"$异常进程名称"]= [[NSProcessInfo processInfo] processName];

    pr[@"$应用包名"] = [[NSBundle mainBundle] bundleIdentifier];
    pr[@"$出错堆栈"] = stack;
    pr[@"$前后台状态"] = self.isForeground?@"前台":@"后台";
    pr[@"$eid"] = @"崩溃";
    NSMutableDictionary *e = [NSMutableDictionary dictionary];
    e[@"dt"] = @"abp";
    e[@"pr"] = pr;
    NSArray *events = @[e];
    NSString *eventData = [self encodeAPIData:[self wrapEvents:events]];

    ZGLogInfo(@"上传崩溃事件：%@",eventData);
    NSData *eventDataBefore = [eventData dataUsingEncoding:NSUTF8StringEncoding];
    NSData *zlibedData = [eventDataBefore zgZlibDeflate];
    NSString *event = [zlibedData zgBase64EncodedString];
    NSString *result = [[event stringByReplacingOccurrencesOfString:@"\r" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSString *requestData = [NSString stringWithFormat:@"method=event_statis_srv.upload&compress=1&event=%@", result];

    BOOL success = [self request:@"/APIPOOL/" WithData:requestData andError:nil];
    
    success ? ZGLogDebug(@"上传崩溃事件成功") : ZGLogDebug(@"上传崩溃事件失败");
    
    if (previousHandler) {
        previousHandler(exception);
    }
}
// 出现崩溃时的回调函数
void ZhugeUncaughtExceptionHandler(NSException * exception){
    [[Zhuge sharedInstance]trackException:exception];
}

#pragma mark - DeepShare
- (void)onInappDataReturned: (NSDictionary *) params withError: (NSError *) error  tag:(NSString *)tag{
    self.utmDic = [[NSMutableDictionary alloc] init];
    if (!error) {
        self.utmDic[@"$utm_source"] = params[@"utm_source"];
        self.utmDic[@"$utm_medium"] = params[@"utm_medium"];
        self.utmDic[@"$utm_campaign"] = params[@"utm_campaign"];
        self.utmDic[@"$utm_content"] = params[@"utm_content"];
        self.utmDic[@"$utm_term"] = params[@"utm_term"];
        if (params[@"$zg_did"]) {
            self.deviceId = params[@"$zg_did"];
        }
        if (params.allKeys.count > 0) {
            if ([tag isEqualToString: REQ_TAG_REGISTER_INSTALL]) {
                self.utmDic[@"$utm_type"] = @"1";
            }
            if ([tag isEqualToString:@"t_register_open"]) {
                self.utmDic[@"$utm_type"] = @"0";
            }
        }
        else {
            if ([tag isEqualToString: REQ_TAG_REGISTER_INSTALL]) {
                self.utmDic[@"$utm_type"] = @"3";
            }
            if ([tag isEqualToString:@"t_register_open"]) {
                self.utmDic[@"$utm_type"] = @"2";
            }
        }
        
        if ([tag isEqualToString:REQ_TAG_REGISTER_INSTALL]) {
            ZGLogInfo(@"安装进来的");
        }
        if ([tag isEqualToString:@"t_register_open"]) {
            ZGLogInfo(@"打开进来的");
        }
        
        if ([self.delegate respondsToSelector:@selector(zgOnInappDataReturned:withError:)]) {
            [self.delegate zgOnInappDataReturned:self.utmDic withError:error];
        }
    } else {
        ZGLogError(@"DeepShare init error id: %ld %@",error.code, error);
    }
    
    self.flushBool = YES;
    
    if (self.archiveEventQueue.count>0) {
        NSMutableArray * flushAry = [NSMutableArray array];
        for (NSDictionary * dic in self.archiveEventQueue) {
            [dic[@"pr"] addEntriesFromDictionary:self.utmDic];
            [flushAry addObject:dic];
        }
        dispatch_async(self.serialQueue, ^{
            [self flushQueue: flushAry];
            self.archiveEventQueue = [NSMutableArray array];
        });
    }
}
+ (BOOL)handleURL:(NSURL *)url {
    return [DeepShare handleURL:url];
}
+ (BOOL)continueUserActivity:(NSUserActivity *)userActivity {
    return [DeepShare continueUserActivity:userActivity];
}

#pragma mark - 诸葛配置
- (void)setUtm:(nonnull NSDictionary *)utmInfo {
    if(!utmInfo){
        return;
    }
    if (!self.utmDic) {
        self.utmDic = [[NSMutableDictionary alloc] init];
    }
    if ([utmInfo objectForKey:@"utm_source"]) {
        [self.utmDic setValue:utmInfo[@"utm_source"] forKey:@"$utm_source"];
    }
    if ([utmInfo objectForKey:@"utm_medium"]) {
        [self.utmDic setValue:utmInfo[@"utm_medium"] forKey:@"$utm_medium"];
    }
    if ([utmInfo objectForKey:@"utm_campaign"]) {
        [self.utmDic setValue:utmInfo[@"utm_campaign"] forKey:@"$utm_campaign"];
    }
    if ([utmInfo objectForKey:@"utm_content"]) {
        [self.utmDic setValue:utmInfo[@"utm_content"] forKey:@"$utm_content"];
    }
    if ([utmInfo objectForKey:@"utm_term"]) {
        [self.utmDic setValue:utmInfo[@"utm_term"] forKey:@"$utm_term"];
    }
}

- (void)setUploadURL:(NSString *)url andBackupUrl:(NSString *)backupUrl{
    if (url && url.length>0) {
        self.apiURL = [ZGUtils parseUrl: url];
        self.backupURL = backupUrl;
    }else{
        ZGLogError(@"传入的url不合法，请检查:%@",url);
    }
}


- (void)setSuperProperty:(NSDictionary *)info{

    if (!self.envInfo) {
        self.envInfo = [[NSMutableDictionary alloc] init];
    }
    self.envInfo[@"event"] = info;
}

- (void)enabelDurationOnPage {
    
    self.viewDidAppearIsHook  = self.viewDidAppearIsHook ? YES : NO;
    self.viewDidDisappearIsHook = self.viewDidDisappearIsHook ? YES : NO;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //$AppViewScreen
        if (!self.viewDidAppearIsHook) {
            [UIViewController za_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(za_autotrack_viewDidAppear:) error:NULL];
            self.viewDidAppearIsHook = YES;
        }
        
        if (!self.viewDidDisappearIsHook) {
            [UIViewController za_swizzleMethod:@selector(viewDidDisappear:) withMethod:@selector(za_autotrack_viewDidDisappear:) error:NULL];
            self.viewDidDisappearIsHook = YES;
        }
        
    });
    
    [self.config setIsEnableDurationOnPage:YES];
}

- (void)enableAutoTrack{
    
    self.viewDidAppearIsHook  = self.viewDidAppearIsHook ? YES : NO;
    
    static dispatch_once_t once;
    dispatch_once(&once, ^ {
        NSError *error = NULL;
        
        //$AppViewScreen
        if (!self.viewDidAppearIsHook) {
            [UIViewController za_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(za_autotrack_viewDidAppear:) error:NULL];
            self.viewDidAppearIsHook = YES;
        }
        
        
        //$AppClick
        // Actions & Events
        [UIApplication zhuge_swizzleMethod:@selector(sendAction:to:from:forEvent:)
                                withMethod:@selector(zhuge_sendAction:to:from:forEvent:)
                                     error:&error];
        if (error) {
            ZGLogError(@"swizzle application action failed ,%@",error);
            error = NULL;
        }
        [UITapGestureRecognizer zhuge_swizzleMethod:@selector(addTarget:action:)
                                         withMethod:@selector(zhuge_addTarget:action:)
                                              error:&error];
        
        [UITapGestureRecognizer zhuge_swizzleMethod:@selector(initWithTarget:action:)
                                         withMethod:@selector(zhuge_initWithTarget:action:)
                                              error:&error];
        
        [UILongPressGestureRecognizer zhuge_swizzleMethod:@selector(addTarget:action:)
                                               withMethod:@selector(zhuge_addTarget:action:)
                                                    error:&error];
        
        [UILongPressGestureRecognizer zhuge_swizzleMethod:@selector(initWithTarget:action:)
                                               withMethod:@selector(zhuge_initWithTarget:action:)
                                                    error:&error];
        if (error) {
            ZGLogError(@"swizzle tap gesture action failed ,%@",error);
            error = NULL;
        }
        
        SEL selector = NSSelectorFromString(@"zhugeio_setDelegate:");
        [UITableView za_swizzleMethod:@selector(setDelegate:) withMethod:selector error:NULL];
        [UICollectionView za_swizzleMethod:@selector(setDelegate:) withMethod:selector error:NULL];
        
        
    });
    
    [self.config setAutoTrackEnable:YES];
}

- (void)enableZGSee {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.viewDidAppearIsHook  = self.viewDidAppearIsHook ? YES : NO;
        // $ZGSee
        [UIApplication za_swizzleMethod:@selector(sendEvent:) withMethod:@selector(za_sendEvent:) error:NULL];

        if (!self.viewDidAppearIsHook) {
            [UIViewController za_swizzleClassMethod:@selector(viewDidAppear:) withClassMethod:@selector(za_autotrack_viewDidAppear:) error:NULL];
            self.viewDidAppearIsHook = YES;
        }
        
    });
    
    [self.config setZgSeeEnable:YES];
}

- (void)enableExpTrack {
    
    self.viewDidAppearIsHook  = self.viewDidAppearIsHook ? YES : NO;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (!self.viewDidAppearIsHook) {
            
            [UIViewController za_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(za_autotrack_viewDidAppear:) error:NULL];

            self.viewDidAppearIsHook = YES;
        }
        
        [UIView za_swizzleMethod:@selector(layoutSubviews) withMethod:@selector(za_layoutSubviews) error:NULL];
    });
    
    [self.config setIsEnableExpTrack:YES];
}

- (void)setPlatform:(NSDictionary *)info{
    if (!self.envInfo) {
        self.envInfo = [NSMutableDictionary dictionary];
    }
    self.envInfo[@"device"] = info;
}

- (NSString *)getDid {
    if (!self.deviceId) {
        self.deviceId = [ZADeviceId getZADeviceId];
    }
    
    return self.deviceId;
}
- (NSString *)getSid{
    
    if (!self.sessionId) {
        self.lastSessionId = [[NSUserDefaults standardUserDefaults] objectForKey:ZG_LAST_SESSIONID];
        return [NSString stringWithFormat:@"%@", self.lastSessionId];
    }
    return [NSString stringWithFormat:@"%@", self.sessionId] ;
}
// 监听网络状态和应用生命周期
- (void)setupListeners{
    BOOL reachabilityOk = NO;
    if ((_reachability = SCNetworkReachabilityCreateWithName(NULL, "www.baidu.com")) != NULL) {
        SCNetworkReachabilityContext context = {0, (__bridge void*)self, NULL, NULL, NULL};
        if (SCNetworkReachabilitySetCallback(_reachability, ZhugeReachabilityCallback, &context)) {
            if (SCNetworkReachabilitySetDispatchQueue(_reachability, self.serialQueue)) {
                reachabilityOk = YES;
            } else {
                SCNetworkReachabilitySetCallback(_reachability, NULL, NULL);
            }
        }
    }
    if (!reachabilityOk) {
        ZGLogError(@"failed to set up reachability callback: %s", SCErrorString(SCError()));
    }
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    // 网络制式(GRPS,WCDMA,LTE,...),IOS7以上版本才支持
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        [self setCurrentRadio];
        [notificationCenter addObserver:self
                               selector:@selector(setCurrentRadio)
                                   name:CTRadioAccessTechnologyDidChangeNotification
                                    object:nil];
    }
#endif
    
    // 应用生命周期通知
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminate:)
                               name:UIApplicationWillTerminateNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
}
// 处理接收到的消息
- (void)handleRemoteNotification:(NSDictionary *)userInfo {
    [self trackPush:userInfo type:@"msgrecv"];
}

#pragma mark - 应用生命周期
// 程序进入前台并处于活动状态时调用
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    @try {
        self.isForeground = YES;
        if (!self.sessionId) {
            [self sessionStart];
        }

        if ([self.config isSeeEnable]) {
            [self zgSeeStart];
        }
        [self uploadDeviceInfo];
//        [self startFlushTimer];
        if (self.config.enableCodeless) {
            [self checkForDecideResponseWithCompletion:^( NSSet *eventBindings) {
                
                dispatch_sync(dispatch_get_main_queue(), ^(){
                    for (ZGEventBinding *binding in eventBindings) {
                        [binding execute];
                    }
                });
                
            } useCathe:NO];
        }
        
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"applicationDidBecomeActive exception %@",exception);
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    @try {
        self.isForeground = NO;
        [self sessionEnd];
//        [self stopFlushTimer];
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"applicationWillResignActive exception %@",exception);
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    @try {
       
        self.taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:self.taskId];
            self.taskId = UIBackgroundTaskInvalid;
        }];
        
        [self flush];
        //进入到后台以后再去上传数据  sid已经为空
//        [self zgSeeUpLoadNumData:50 cacheBool:NO];

        dispatch_async(self.serialQueue, ^{
            [self archive];
            if (self.taskId != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:self.taskId];
                self.taskId = UIBackgroundTaskInvalid;
            }
        });
    }
    @catch (NSException *exception) {
        ZGLogError(@"applicationDidEnterBackground exception %@",exception);
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    @try {
        
        dispatch_async(self.serialQueue, ^{
            [self archive];
        });
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"applicationWillTerminate exception %@",exception);
    }
}

#pragma mark - 设备状态
// 运营商
- (NSString *)carrier {
    CTCarrier *carrier =[self.telephonyInfo subscriberCellularProvider];
    if (carrier != nil) {
        NSString *mcc =[carrier mobileCountryCode];
        NSString *mnc =[carrier mobileNetworkCode];
        return [NSString stringWithFormat:@"%@%@", mcc, mnc];
    }
    return @"(null)(null)";
}

// 更新网络指示器
//- (void)updateNetworkActivityIndicator:(BOOL)on {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [UIApplication sharedApplication].networkActivityIndicatorVisible = on;
//    });
//}

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags {
    if (flags & kSCNetworkReachabilityFlagsReachable) {
        if (flags & kSCNetworkReachabilityFlagsIsWWAN) {
            self.net = @"0";//2G/3G/4G
        } else {
            self.net = @"4";//WIFI
        }
    } else {
        self.net = @"-1";//未知
    }
    ZGLogDebug(@"联网状态: %@", [@"-1" isEqualToString:self.net]?@"未知":[@"0" isEqualToString:self.net]?@"移动网络":@"WIFI");
}

// 网络制式(GPRS,WCDMA,LTE,...)
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
- (void)setCurrentRadio {
    dispatch_async(self.serialQueue, ^(){
        self.radio = [self currentRadio];
    });
}

- (NSString *)currentRadio {
    NSString *radio = self.telephonyInfo.currentRadioAccessTechnology;
    if (!radio) {
        radio = @"None";
    } else if ([radio hasPrefix:@"CTRadioAccessTechnology"]) {
        radio = [radio substringFromIndex:23];
    }
    return radio;
}
#endif

#pragma mark - 生成事件
/**
 共同的环境信息
 @return 可变的环境信息Dictionary
 */
-(NSMutableDictionary *)buildCommonData {
    NSMutableDictionary *common;
    if (self.utmDic) {
        common = [NSMutableDictionary dictionaryWithDictionary:self.utmDic];
    } else {
        common = [[NSMutableDictionary alloc] init];
    }
    if (self.userId.length > 0) {
        common[@"$cuid"] = self.userId;
    }
    common[@"$cr"]  = self.cr;
    //毫秒偏移量
    common[@"$ct"] = [NSNumber numberWithUnsignedLongLong:[[NSDate date] timeIntervalSince1970] *1000];
    common[@"$tz"] = [NSNumber numberWithInteger:[[NSTimeZone localTimeZone] secondsFromGMT]*1000];//取毫秒偏移量
    common[@"$os"] = @"iOS";

    //DeepShare 信息
    [common addEntriesFromDictionary:self.utmDic];
    return common;
}

// 会话开始
- (void)sessionStart {
    @try {
        if (!self.sessionId) {
            //毫秒偏移量
            self.sessionCount = 0;
            self.seeCount = 0;
            self.sessionId = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] *1000];
            self.lastSessionId = self.sessionId;
            [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@",self.lastSessionId] forKey:ZG_LAST_SESSIONID];
            ZGLogDebug(@"会话开始(ID:%@)", self.sessionId);
            if (self.config.sessionEnable) {
                NSMutableDictionary *e = [NSMutableDictionary dictionary];
                e[@"dt"] = @"ss";
                NSMutableDictionary *pr = [self buildCommonData];
                pr[@"$an"] = self.config.appName;
                pr[@"$cn"]  = self.config.channel;
                pr[@"$net"] = self.net;
                pr[@"$mnet"]= self.radio;
                pr[@"$ov"] = [[UIDevice currentDevice] systemVersion];
                pr[@"$sid"] = self.sessionId;
                pr[@"$vn"] = self.config.appVersion;
                pr[@"$sc"]= @0;
                e[@"pr"] = pr;
                [self enqueueEvent:e];
            }
        }
    }
    @catch (NSException *exception) {
        ZGLogError(@"sessionStart exception %@",exception);
    }
}

// 会话结束
- (void)sessionEnd {
    @try {
        ZGLogDebug(@"会话结束(ID:%@)", self.sessionId);
        if (self.sessionId) {
            if (self.config.sessionEnable) {
                NSMutableDictionary *e = [NSMutableDictionary dictionary];
                e[@"dt"] = @"se";
                NSMutableDictionary *pr = [self buildCommonData];
                int32_t value =  OSAtomicIncrement32(&_sessionCount);
                NSNumber *ts = pr[@"$ct"];
                NSNumber *dru = @([ts unsignedLongLongValue] - [self.sessionId unsignedLongLongValue]);
                pr[@"$an"] = self.config.appName;
                pr[@"$cn"]  = self.config.channel;
                pr[@"$dru"] = dru;
                pr[@"$net"] = self.net;
                pr[@"$mnet"]= self.radio;
                pr[@"$sid"] = self.sessionId;
                pr[@"$vn"] = self.config.appVersion;
                pr[@"$ov"] = [[UIDevice currentDevice] systemVersion];
                pr[@"$sc"] = [NSNumber numberWithInt:value];
                e[@"pr"] = pr;
                [self enqueueEvent:e];
            }
            self.sessionId = nil;
        }
    }
    @catch (NSException *exception) {
        ZGLogError(@"sessionEnd exception %@",exception);
    }
}

// 上报设备信息
- (void)uploadDeviceInfo {
    [self trackDeviceInfo];

    @try {
        NSNumber *zgInfoUploadTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"zgInfoUploadTime"];
        NSNumber *ts = @(round([[NSDate date] timeIntervalSince1970]));
        if (zgInfoUploadTime == nil ||[ts longValue] > [zgInfoUploadTime longValue] + 86400) {
            [self trackDeviceInfo];
            [[NSUserDefaults standardUserDefaults] setObject:ts forKey:@"zgInfoUploadTime"];
        }
    }
    @catch (NSException *exception) {
        ZGLogError(@"uploadDeviceInfo exception %@",exception);
    }
}

- (void)autoTrack:(NSDictionary *)info{
    if (![info objectForKey:@"$eid"]) {
        ZGLogDebug(@"auto track with illegal content %@",info);
        return;
    }
    if (!self.sessionId) {
        [self sessionStart];
    }
    dispatch_async(self.serialQueue, ^{
        @try {
            NSMutableDictionary *data = [NSMutableDictionary dictionaryWithCapacity:2];
            NSMutableDictionary *pr = [self eventData];
            if (self.envInfo) {
                NSMutableDictionary *data = [self addSymbloToDic:[self.envInfo objectForKey:@"event"]];
                [pr addEntriesFromDictionary:data];
            }
            
            [pr addEntriesFromDictionary:info];
            [data setObject:pr forKey:@"pr"];
            [data setObject:@"abp" forKey:@"dt"];
            [self enqueueEvent:data];
        }
        @catch (NSException *exception) {
            ZGLogError(@"start track properties exception %@",exception);
        }
    });
    
}

- (void)startTrack:(NSString *)eventName{
    @try {
        if (!eventName) {
            ZGLogDebug(@"startTrack event name must not be nil.");
            return;
        }
        dispatch_async(self.serialQueue, ^{
            NSNumber *ts = @([[NSDate date] timeIntervalSince1970]);
            ZGLogDebug(@"startTrack %@ at time : %@",eventName,ts);
            [self.eventTimeDic setValue:ts forKey:eventName];
        });
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"start track properties exception %@",exception);
    }
}

- (void)endTrack:(NSString *)eventName properties:(NSDictionary*)properties{
    @try {
        dispatch_async(self.serialQueue, ^{
            NSNumber *start = [self.eventTimeDic objectForKey:eventName];
            if (!start) {
                ZGLogDebug(@"end track event name not found ,have you called startTrack already?");
                return;
            }
            if (!self.sessionId) {
                [self sessionStart];
            }
            [self.eventTimeDic removeObjectForKey:eventName];
            NSNumber *end = @([[NSDate date] timeIntervalSince1970]);
            ZGLogDebug(@"endTrack %@ at time : %@",eventName,end);
            NSMutableDictionary *dic = properties?[self addSymbloToDic:properties]:[NSMutableDictionary dictionary];
            dic[@"$dru"] = [NSNumber numberWithUnsignedLongLong:(end.doubleValue - start.doubleValue)*1000];
            dic[@"$eid"] = eventName;
            int32_t value =  OSAtomicIncrement32(&self->_sessionCount);
            dic[@"$sc"] = [NSNumber numberWithInt:value];
            [dic addEntriesFromDictionary:[self eventData]];
            if (self.envInfo) {
                NSDictionary *info = [self.envInfo objectForKey:@"event"];
                if (info) {
                    NSMutableDictionary *data = [self addSymbloToDic:info];
                    [dic addEntriesFromDictionary:data];
                }
            }
            NSMutableDictionary *e = [NSMutableDictionary dictionaryWithCapacity:2];
            [e setObject:dic forKey:@"pr"];
            [e setObject:@"evt" forKey:@"dt"];
            [self enqueueEvent:e];
        });
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"end track properties exception %@",exception);
    }
}

- (void)track:(NSString *)event {
    [self track:event properties:nil];
}

- (void)trackRevenue:(NSDictionary *)properties {
    
    NSMutableDictionary *tempDic = [[NSMutableDictionary alloc] initWithDictionary:properties];
    NSString *price = [NSString stringWithFormat:@"%@",properties[ZhugeEventRevenuePrice]];
    NSString *number = [NSString stringWithFormat:@"%@",properties[ZhugeEventRevenueProductQuantity]];
    //price转化成NSDecimalNumber
    NSDecimalNumber *priceDec = [NSDecimalNumber decimalNumberWithString:price];
    //number转化成NSDecimalNumber
    NSDecimalNumber *numberDec = [NSDecimalNumber decimalNumberWithString:number];
    //两个数相乘
    NSDecimalNumber *totalDec = [priceDec decimalNumberByMultiplyingBy:numberDec];
    
    [tempDic setObject:priceDec forKey:ZhugeEventRevenuePrice];
    [tempDic setObject:numberDec forKey:ZhugeEventRevenueProductQuantity];
    [tempDic setObject:totalDec forKey:ZhugeEventRevenueTotalPrice];
    [self trackRevenue:@"revenue" properties:tempDic];
}

- (void)trackRevenue:(NSString *)event properties:(NSMutableDictionary *)properties {
    @try {
        if (event == nil || [event length] == 0) {
            ZGLogDebug(@"事件名不能为空");
            return;
        }
        
        if (!self.sessionId) {
            [self sessionStart];
        }
        NSMutableDictionary *pr = [self eventData];
        if (properties) {
            [pr addEntriesFromDictionary:[self conversionRevenuePropertiesKey:properties]];
        }
        if (self.envInfo) {
            NSDictionary *info = [self.envInfo objectForKey:@"event"];
            if (info) {
                NSMutableDictionary *dic = [self addSymbloToDic:info];
                [pr addEntriesFromDictionary:dic];
            }
        }
        pr[@"$eid"] = event;
        int32_t value =  OSAtomicIncrement32(&_sessionCount);
        pr[@"$sc"] = [NSNumber numberWithInt:value];
        NSMutableDictionary *e = [NSMutableDictionary dictionary];
        e[@"dt"] = @"abp";
        e[@"pr"] = pr;
        [self enqueueEvent:e];
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"track properties exception %@",exception);
    }
}

- (NSMutableDictionary *)conversionRevenuePropertiesKey:(NSDictionary *)dic{
    __block NSMutableDictionary *copy = [NSMutableDictionary dictionaryWithCapacity:[dic count]];
    for (NSString *key in dic) {
        id value = dic[key];
        NSString *newKey = [NSString stringWithFormat:@"$%@",key];
        [copy setValue:value forKey:newKey];
    }
    
    return copy;
}

- (void)track:(NSString *)event properties:(NSMutableDictionary *)properties {
    @try {
        if (event == nil || [event length] == 0) {
            ZGLogDebug(@"事件名不能为空");
            return;
        }
        
        if (!self.sessionId) {
            [self sessionStart];
        }
        NSMutableDictionary *pr = [self eventData];
        if (properties) {
            [pr addEntriesFromDictionary:[self addSymbloToDic:properties]];
        }
        if (self.envInfo) {
            NSDictionary *info = [self.envInfo objectForKey:@"event"];
            if (info) {
                NSMutableDictionary *dic = [self addSymbloToDic:info];
                [pr addEntriesFromDictionary:dic];
            }
        }
        pr[@"$eid"] = event;
        int32_t value =  OSAtomicIncrement32(&_sessionCount);
        pr[@"$sc"] = [NSNumber numberWithInt:value];
        NSMutableDictionary *e = [NSMutableDictionary dictionary];
        e[@"dt"] = @"evt";
        e[@"pr"] = pr;
        [self enqueueEvent:e];
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"track properties exception %@",exception);
    }
}

- (NSMutableDictionary *)eventData{
    NSMutableDictionary *pr = [self buildCommonData];
    pr[@"$an"] = self.config.appName;
    pr[@"$cn"]  = self.config.channel;
    pr[@"$mnet"]= self.radio;
    pr[@"$net"] = self.net;
    pr[@"$ov"] = [[UIDevice currentDevice] systemVersion];
    pr[@"$sid"] = self.sessionId;
    pr[@"$vn"] = self.config.appVersion;
    return pr;
}

- (void)identify:(NSString *)userId properties:(NSDictionary *)properties {
    @try {
        if (userId == nil || userId.length == 0) {
            ZGLogDebug(@"用户ID不能为空");
            return;
        }
        if (!self.sessionId) {
            [self sessionStart];
        }
        self.userId = userId;
        NSMutableDictionary *e = [NSMutableDictionary dictionary];
        e[@"dt"] = @"usr";
        NSMutableDictionary *pr = [self buildCommonData];
        if (properties) {
            NSDictionary *dic = [self addSymbloToDic:properties];
            [pr addEntriesFromDictionary:dic];
        }
        pr[@"$an"] = self.config.appName;
        pr[@"$cuid"] = userId;
        pr[@"$vn"] = self.config.appVersion;
        pr[@"$cn"]  = self.config.channel;
        e[@"pr"] = pr;
        [self enqueueEvent:e];
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"identify exception %@",exception);
    }
}

- (void)updateIdentify: (NSDictionary *)properties {
    if (!self.userId.length) {
        ZGLogDebug(@"未进行identify,仅传入属性是错误的。");
        return;
    }
    [self identify:self.userId properties:properties];
}

- (void)trackDeviceInfo {
    @try {
        NSMutableDictionary *e = [NSMutableDictionary dictionary];
        e[@"dt"] = @"pl";
        NSMutableDictionary *pr = [self buildCommonData];
        // 设备
//        pr[@"$dv"] = [self getSysInfoByName:"hw.machine"];
        pr[@"$dv"] = [ZGDeviceInfo getDeviceModel];
        // 是否越狱
        pr[@"$jail"] =[ZGDeviceInfo isJailBroken] ? @1 : @0;
        // 语言
        pr[@"$lang"] = [[NSLocale preferredLanguages] objectAtIndex:0];
        // 制造商
        pr[@"$mkr"] = @"Apple";
        // 系统
        pr[@"$os"] = @"iOS";
        pr[@"$zs"] = self.localZhugeSeeState?@"1":@"";
        // 是否破解
        pr[@"$private"] =[ZGDeviceInfo isPirated] ? @1 : @0;
        //分辨率
        pr[@"$rs"] = [ZGDeviceInfo resolution];
        if (self.envInfo) {
            NSDictionary *info = [self.envInfo objectForKey:@"device"];
            if (info) {
                NSMutableDictionary *dic = [self addSymbloToDic:info];
                [pr addEntriesFromDictionary:dic];
            }
        }
        e[@"pr"] = pr;
        [self enqueueEvent:e];
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"trackDeviceInfo exception, %@",exception);
    }
}

- (void)trackDurationOnPage:(NSDictionary *)properties {
    
    if (!self.sessionId) {
        [self sessionStart];
    }
    
    NSMutableDictionary *dic = properties?[self addSymbloToDic:properties]:[NSMutableDictionary dictionary];
    int32_t value =  OSAtomicIncrement32(&self->_sessionCount);
    dic[@"$sc"] = [NSNumber numberWithInt:value];
    [dic addEntriesFromDictionary:[self eventData]];
    
    if (self.envInfo) {
        NSDictionary *info = [self.envInfo objectForKey:@"event"];
        if (info) {
            NSMutableDictionary *data = [self addSymbloToDic:info];
            [dic addEntriesFromDictionary:data];
        }
    }
    NSMutableDictionary *e = [NSMutableDictionary dictionaryWithCapacity:2];
    [e setObject:dic forKey:@"pr"];
    [e setObject:@"abp" forKey:@"dt"];
    [self enqueueEvent:e];
}


#pragma mark --- 采集开始会话数据
- (void)zgSeeStart {
    //保存到本地  --  当然你可以在下次启动的时候，上传这个log
    NSMutableArray * dataArray = [NSMutableArray array];
    NSMutableDictionary * prDic = [NSMutableDictionary dictionary];
    if (self.userId.length > 0) {
        prDic[@"$cuid"] = self.userId;
    }
    self.screenShotTime = nil;
    prDic[@"$ct"] = [NSNumber numberWithUnsignedInteger:[[NSDate date] timeIntervalSince1970] *1000];
    prDic[@"$sid"] = [NSString stringWithFormat:@"%@",self.sessionId];
    prDic[@"$net"] = self.net;
    prDic[@"$os"] = @"iOS";
    prDic[@"$ov"] = [[UIDevice currentDevice] systemVersion];;
//    prDic[@"$dv"] = [self getSysInfoByName:"hw.machine"];
    prDic[@"$dv"] = [ZGDeviceInfo getDeviceModel];
    prDic[@"$br"] = @"Apple";
    prDic[@"$av"] = self.config.appVersion;
    prDic[@"Ssc"] = @0;
    OSAtomicIncrement32(&self->_seeCount);
    prDic[@"$cr"] = self.cr;
    
    NSMutableDictionary * sqlDic = [NSMutableDictionary dictionary];
    NSMutableDictionary * dataDic = [NSMutableDictionary dictionary];
    dataDic[@"pr"] = prDic;
    dataDic[@"dt"] = @"ss";
//    dataDic[@"key"] = @"";
    
    //数据库存储
    sqlDic[@"sid"] = self.sessionId;
    sqlDic[@"data"] = [ZGUtils dictionaryToJson:dataDic];
    
    
    //实时上传操作 把数据放置Array
    [dataArray addObject:dataDic];
    NSMutableDictionary *aryDic = [self wrapEvents:dataArray];
    //对整体数据进行压缩编码
    NSString * str = [[[[self encodeAPIData:aryDic] dataUsingEncoding:NSUTF8StringEncoding] zgZlibDeflate] zgBase64EncodedString];
    NSString *dicStr = [NSString stringWithFormat: @"event=%@",str];
    
    // 判断sid是否为空
    if (self.sessionId != nil) {
        //判断是否打开开关
        if (self.zhugeSeeReal == 0 && ([self.zhugeSeeNet isEqualToString:self.net] || [self.zhugeSeeNet isEqualToString:@"1"])) {
            // 判断是否需要实时上传
            [ZGHttpHelper post:[ZGUtils getZGSeeUploadUrl:self.apiURL] RequestStr:dicStr FinishBlock:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                 NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                 if (httpResponse.statusCode == 200) {
                     ZGLogDebug(@"zgSeeEnd --- 数据上传成功");
                 } else {
                     ZGLogDebug(@"zgSeeEnd --- 数据上传失败  %@",connectionError);
                 }
             }];
        } else {
//            NSInteger dicNumber = 999;
//            BOOL addBool = [[ZGSqliteManager shareManager] addZGSeeCoreDataDic:sqlDic dicNumber:dicNumber];
//            if (addBool == YES) {
//                ZGLogDebug(@"zgSeeEnd --- 添加至数据库成功");
//            } else {
//                ZGLogDebug(@"zgSeeEnd --- 添加至数据库失败");
//            }
        }
    }
}
#pragma mark --- 上传zhugesee数据
- (void)zgSeeBool {
    //是否开启ZGSee
    NSString *url = [ZGUtils getZGSeePolicyUrl:self.apiURL appkey:self.appKey];
    __block NSDictionary * dic = nil;
    __block NSNumber *policy = nil;
    __block NSNumber * real = nil;
    __weak typeof(self) weakSelf = self;
    [ZGHttpHelper sendRequestForUrl:url FinishBlock:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        ZGLogDebug(@"请求 ZGSee 服务器 == %@ StatusCode == %ld",url,httpResponse.statusCode);
        if (httpResponse.statusCode == 200 && data){
            dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            if (dic == nil) {
                NSLog(@"check appsee error. Data will be lose.");
                return;
            }
            policy = [dic objectForKey:@"policy"];
            if (policy == nil) {
                strongSelf.config.serverPolicy = -1;
            }else{
                strongSelf.config.serverPolicy = [policy integerValue];
            }
            real = [dic objectForKey:@"real"];
            strongSelf.zhugeSeeReal = [real integerValue];
            strongSelf.zhugeSeeNet = [NSString stringWithFormat:@"%@", [dic objectForKey:@"net"]];
            strongSelf.ZGPublicKey = [dic objectForKey:@"rsa-public"];
            strongSelf.ZGPublicMD5 = [dic objectForKey:@"rsa-md5"];
        } else {
            ZGLogDebug(@"zgSee --- 出现异常 %@",connectionError);
        }
    }];
}
- (void)zgSeeUpLoadNumData:(NSInteger)numData cacheBool:(BOOL)cacheBool {
    //如果打开开关 则先把库存数据上传
    NSMutableArray * ary = [[ZGSqliteManager shareManager] uploaddataStoredNumData:numData];
    //如果CoreData没有数据 则结束上传缓存数据
    if (ary.count < 1) {
        return;
    }
    
    NSMutableArray * dataArray = [NSMutableArray array];
    NSString * sid = @"";
    for (NSMutableDictionary * dic in ary) {
        NSMutableDictionary * data = [NSMutableDictionary dictionary];
        data = [self dictionaryWithJsonString:dic[@"data"]];
        sid = dic[@"sid"];
        [dataArray addObject:data];
    }
    
    if (![[NSString stringWithFormat:@"%@",sid] isEqualToString:[NSString stringWithFormat:@"%@",self.sessionId]]) {
        NSMutableDictionary * dic = [NSMutableDictionary dictionary];
        dic = [self wrapEvents:dataArray];
        //对整体数据进行压缩编码
        NSString * dicStr = [[[[self encodeAPIData:dic] dataUsingEncoding:NSUTF8StringEncoding] zgZlibDeflate] zgBase64EncodedString];
        if ([self.zhugeSeeNet isEqualToString:self.net] || [self.zhugeSeeNet isEqualToString:@"1"]) {
            [ZGHttpHelper post:[ZGUtils getZGSeeUploadUrl:self.apiURL] RequestStr:dicStr FinishBlock:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                 NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                 if (httpResponse.statusCode == 200) {
                     ZGLogDebug(@"ZGSee --- 数据上传成功");
                     [[ZGSqliteManager shareManager] deletezgSeeCoreDataSid:sid];
//                     [self zgSeeUpLoadNumData:numData cacheBool:cacheBool];
                     
                 } else {
                     ZGLogDebug(@"ZGSee --- 数据上传失败  %@",connectionError);
                 }
             }];
        }
    }
}

#pragma mark 诸葛see 数据采集
- (void)setZhuGeSeeEvent:(NSMutableDictionary *)seeData {
    if (!self.sessionId) {
        return;
    }
    if (!self.localZhugeSeeState) {
        self.localZhugeSeeState = YES;
        [self trackDeviceInfo];
        dispatch_async(self.serialQueue, ^{
            [self archiveSeeState];
        });
    }
    @try {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            //子线程中开始网络请求数据
            NSMutableArray * dataArray = [NSMutableArray array];
            //更新数据模型
            NSMutableDictionary * prDic = seeData;
            
            prDic[@"$ival"] = @([self getCurrentIval]);
            if (self.userId.length > 0) {
                prDic[@"$cuid"] = self.userId;
            }
            prDic[@"$ct"] = [NSNumber numberWithUnsignedInteger:[[NSDate date] timeIntervalSince1970] *1000];
            prDic[@"$sid"] = self.sessionId;
            prDic[@"$net"] = self.net;
            prDic[@"$os"] = @"iOS";
            prDic[@"$sc"] =[NSNumber numberWithInt:self.seeCount];
            OSAtomicIncrement32(&self->_seeCount);
            prDic[@"$ov"] = [[UIDevice currentDevice] systemVersion];;
            prDic[@"$av"] = self.config.appVersion;
            prDic[@"$cr"]  = self.cr;
//            prDic[@"$dv"] = [self getSysInfoByName:"hw.machine"];
            prDic[@"$dv"] = [ZGDeviceInfo getDeviceModel];
            prDic[@"$br"] = @"Apple";
            prDic[@"$dru"] = @([[ZGSharedDur shareInstance] durInterval]);
            NSString *pixD =[seeData[@"$pix"] zgBase64EncodedString];
            prDic[@"$pix"] = pixD;

            
            NSData *prData =  [NSJSONSerialization dataWithJSONObject:prDic options:0 error:nil];

            NSString * aesKeyData = [ZGUtils random128BitAESKey];
            //生成秘钥
            NSString * aesKey = [ZGUtil encryptString:aesKeyData publicKey:self.ZGPublicKey];
            //压缩并且加密数据
            NSString *event = [ZGUtil AES128Encrypt:[prData zgZlibDeflate] sesKey:aesKeyData];
            
            //整理数据
            NSMutableDictionary * dataDic = [NSMutableDictionary dictionary];
            dataDic[@"key"] = aesKey;
            dataDic[@"dt"] = @"zgsee";
            dataDic[@"rsa-md5"] = self.ZGPublicMD5;
            dataDic[@"pr"] = event;
            
            //存储数据库
            NSMutableDictionary * sqlDic = [NSMutableDictionary dictionary];
            sqlDic[@"sid"] = self.sessionId;
            sqlDic[@"data"] = [ZGUtils dictionaryToJson:dataDic];
            
            
            [dataArray addObject:dataDic];
            NSMutableDictionary *wrappedDic =  [self wrapEvents:dataArray];
            NSData *wrappedData =  [NSJSONSerialization dataWithJSONObject:wrappedDic options:0 error:nil];
            NSString * str = [[wrappedData zgZlibDeflate]zgBase64EncodedString];

            //对整体数据进行压缩编码
            NSString *dicStr = [NSString stringWithFormat: @"event=%@",str];

            dispatch_sync(dispatch_get_main_queue(), ^{
                // 判断sid是否为空
                if (self.sessionId != nil) {
                    //判断是否打开开关
                    if (self.zhugeSeeReal == 0 && ([self.zhugeSeeNet isEqualToString:self.net] || [self.zhugeSeeNet isEqualToString:@"1"])) {
                        // 判断是否需要实时上传
                        [ZGHttpHelper post:[ZGUtils getZGSeeUploadUrl:self.apiURL] RequestStr:dicStr FinishBlock:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                             NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                             if (httpResponse.statusCode == 200) {
                                 ZGLogDebug(@"ZGSee --- 数据上传成功");
                             } else {
                                 ZGLogDebug(@"ZGSee --- 数据上传失败  %@",connectionError);
                             }
                         }];
                    } else {
//                        NSInteger dicNumber = 999;
//
//                        BOOL addBool = [[ZGSqliteManager shareManager] addZGSeeCoreDataDic:sqlDic dicNumber:dicNumber];
//                        if (addBool == YES) {
//                            ZGLogDebug(@"zgSee --- 添加至数据库成功");
//                        } else {
//                            ZGLogDebug(@"zgSee --- 添加至数据库失败");
//                        }
                    }
                }
            });
        });
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"trackDeviceInfo exception, %@",exception);
    }
    
}
- (CGFloat)getCurrentIval{
    if (!self.screenShotTime) {
        self.screenShotTime = [NSDate date];
        return 0;
    }
    CGFloat ival = [[NSDate date] timeIntervalSinceDate:self.screenShotTime];
    return ival;
}

#pragma mark - 推送信息
// 上报推送已读
- (void)trackPush:(NSDictionary *)userInfo type:(NSString *) type {
    
    @try {
        ZGLogDebug(@"push payload: %@", userInfo);
        if (userInfo && userInfo[@"mid"]) {
            NSMutableDictionary *e = [NSMutableDictionary dictionary];
            e[@"$mid"] = userInfo[@"mid"];
            e[@"$ct"] = [NSNumber numberWithUnsignedLongLong:[[NSDate date] timeIntervalSince1970] *1000];
            e[@"$tz"] = [NSNumber numberWithInteger:[[NSTimeZone localTimeZone] secondsFromGMT]*1000];//取毫秒偏移量
            e[@"$channel"] = @"";
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            dic[@"dt"] = type;
            dic[@"pr"]  = e;
            [self enqueueEvent:dic];
            [self flush]; 
        }
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"trackPush exception %@",exception);
    }
}

// 设置第三方推送用户ID
- (void)setThirdPartyPushUserId:(NSString *)userId forChannel:(ZGPushChannel) channel {
    @try {
        if (userId == nil || [userId length] == 0) {
            ZGLogDebug(@"userId不能为空");
            return;
        }
        
        NSMutableDictionary *pr = [NSMutableDictionary dictionary];
        pr[@"$push_ch"] = [self nameForChannel:channel];
        pr[@"$push_id"] = userId;
        //取毫秒偏移量
        pr[@"$tz"]    = [NSNumber numberWithInteger:[[NSTimeZone localTimeZone] secondsFromGMT]*1000];
        pr[@"$ct"]  =  [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] *1000];
        NSMutableDictionary *e = [NSMutableDictionary dictionary];
        e[@"dt"] = @"um";
        e[@"pr"] = pr;
        
        [self enqueueEvent:e];
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"track properties exception %@",exception);
    }
}

- (NSString *)nameForChannel:(ZGPushChannel) channel {
    switch (channel) {
        case ZG_PUSH_CHANNEL_XIAOMI:
            return @"xiaomi";
        case ZG_PUSH_CHANNEL_JPUSH:
            return @"jpush";
        case ZG_PUSH_CHANNEL_UMENG:
            return @"umeng";
        case ZG_PUSH_CHANNEL_BAIDU:
            return @"baidu";
        case ZG_PUSH_CHANNEL_XINGE:
            return @"xinge";
        case ZG_PUSH_CHANNEL_GETUI:
            return @"getui";
        default:
            return @"";
    }
}

 // 上传之前包装数据
- (NSMutableDictionary *)wrapEvents:(NSArray *)events{
    NSMutableDictionary *batch = [NSMutableDictionary dictionary];
    batch[@"ak"]    = self.appKey;
    batch[@"debug"] = self.config.debug?@1:@0;
    batch[@"sln"]   = @"itn";
    batch[@"owner"] = @"zg";
    batch[@"pl"]    = @"ios";
    batch[@"sdk"]   = @"zg-ios";
    batch[@"sdkv"]  = self.config.sdkVersion;
    NSDictionary *dic = @{@"did":[self getDid]};
    batch[@"usr"]   = dic;
    batch[@"ut"]    = [ZGUtils currentDate];
    //取毫秒偏移量
    batch[@"tz"]    = [NSNumber numberWithInteger:[[NSTimeZone localTimeZone] secondsFromGMT]*1000];
    batch[@"data"]  = events;
    return batch;
}
#pragma mark - 编码&解码
- (NSMutableDictionary *)addSymbloToDic:(NSDictionary *)dic{
    NSMutableDictionary *copy = [NSMutableDictionary dictionaryWithCapacity:[dic count]];
    for (NSString *key in dic) {
        id value = dic[key];
        if ([key containsString:@"$"]) {
            [copy setValue:value forKey:key];
        } else {
            NSString *newKey = [NSString stringWithFormat:@"_%@",key];
            [copy setValue:value forKey:newKey];
        }
        
    }
    return copy;
}

// JSON序列化
- (NSData *)JSONSerializeObject:(id)obj {
    id coercedObj = [self JSONSerializableObjectForObject:obj];
    NSError *error = nil;
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:coercedObj options:0 error:&error];
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"%@ exception encoding api data: %@", self, exception);
    }
    if (error) {
        ZGLogDebug(@"%@ error encoding api data: %@", self, error);
        
    }
    return data;
}
// JSON序列化
- (id)JSONSerializableObjectForObject:(id)obj {
    // valid json types
    if ([obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSNumber class]] ||
        [obj isKindOfClass:[NSNull class]]) {
        return obj;
    }
    // recurse on containers
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *a = [NSMutableArray array];
        for (id i in obj) {
            [a addObject:[self JSONSerializableObjectForObject:i]];
        }
        return [NSArray arrayWithArray:a];
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        for (id key in obj) {
            NSString *stringKey;
            if (![key isKindOfClass:[NSString class]]) {
                stringKey = [key description];
            } else {
                stringKey = [NSString stringWithString:key];
            }
            id v = [self JSONSerializableObjectForObject:obj[key]];
            d[stringKey] = v;
        }
        return [NSDictionary dictionaryWithDictionary:d];
    }
    
    // default to sending the object's description
    NSString *s = [obj description];
    return s;
}

// API数据编码
- (NSString *)encodeAPIData:(NSMutableDictionary *) batch {
    NSData *data = [self JSONSerializeObject:batch];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

// json格式字符串转字典：
- (NSMutableDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *err;
    
    NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                
                                                               options:NSJSONReadingMutableContainers
                                
                                                                 error:&err];
    
    if(err) {
        
        ZGLogDebug(@"json解析失败：%@",err);
        
        return nil;
        
    }
    
    return dic;
}

#pragma mark - 上报策略
// 启动事件发送定时器
- (void)startFlushTimer {
    [self stopFlushTimer];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.config.sendInterval > 0) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:self.config.sendInterval
                                                          target:self
                                                        selector:@selector(flush)
                                                        userInfo:nil
                                                         repeats:YES];
            
            ZGLogDebug(@"启动事件发送定时器");
        }
    });
}

// 关闭事件发送定时器
- (void)stopFlushTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer) {
            [self.timer invalidate];
            ZGLogDebug(@"关闭事件发送定时器");
        }
        self.timer = nil;
    });
}

#pragma mark - 事件上报
// 事件加入待发队列
- (void)enqueueEvent:(NSMutableDictionary *)event {
    if (!self.isInitSDK) {
        ZGLogWarning(@"初始化 SDK 之后才能开始统计数据");
        return;
    }
    dispatch_async(self.serialQueue, ^{
        [self syncEnqueueEvent:event];
    });
}

- (void)syncEnqueueEvent:(NSMutableDictionary *)event {
    ZGLogDebug(@"产生事件: %@", event);
    
    if (self.flushBool == YES) {
        [self.eventsQueue addObject:event];
        if ([self.eventsQueue count] > self.config.cacheMaxSize) {
            [self.eventsQueue removeObjectAtIndex:0];
        }
        [self flush];
    } else {
        [self.eventsQueue addObject:event];
        if ([self.eventsQueue count] > self.config.cacheMaxSize) {
            [self.eventsQueue removeObjectAtIndex:0];
        }
        [self flush];
    }
    
}

- (void)flush {
    dispatch_async(self.serialQueue, ^{
        [self flushQueue: self->_eventsQueue];
    });
}

- (void)flushQueue:(NSMutableArray *)queue {
    @try {
        while ([queue count] > 0) {
            if (self.sendCount >= self.config.sendMaxSizePerDay) {
                ZGLogDebug(@"超过每天限额，不发送。(今天已经发送:%lu, 限额:%lu, 队列库存数: %lu)", (unsigned long)self.sendCount, (unsigned long)self.config.sendMaxSizePerDay, (unsigned long)[queue count]);
                return;
            }
            
            NSUInteger sendBatchSize = ([queue count] > 50) ? 50 : [queue count];
            if (self.sendCount + sendBatchSize >= self.config.sendMaxSizePerDay) {
                sendBatchSize = self.config.sendMaxSizePerDay - self.sendCount;
            }
            
            NSArray *events = [queue subarrayWithRange:NSMakeRange(0, sendBatchSize)];
            ZGLogDebug(@"开始上报事件(本次上报事件数:%lu, 队列内事件总数:%lu, 今天已经发送:%lu, 限额:%lu)", (unsigned long)[events count], (unsigned long)[queue count], (unsigned long)self.sendCount, (unsigned long)self.config.sendMaxSizePerDay);
            
            NSString *eventData = [self encodeAPIData:[self wrapEvents:events]];
            ZGLogDebug(@"上传事件：%@",eventData);
            NSData *eventDataBefore = [eventData dataUsingEncoding:NSUTF8StringEncoding];
            NSData *zlibedData = [eventDataBefore zgZlibDeflate];
            NSString *event = [zlibedData zgBase64EncodedString];
            NSString *result = [[event stringByReplacingOccurrencesOfString:@"\r" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            
            NSString *requestData = [NSString stringWithFormat:@"method=event_statis_srv.upload&compress=1&event=%@", result];
            
            BOOL success = [self request:@"/APIPOOL/" WithData:requestData andError:nil];

            if (success) {
                ZGLogDebug(@"上传事件成功");
                self.sendCount += sendBatchSize;
                [queue removeObjectsInArray:events];
            } else {
                ZGLogDebug(@"上传事件失败");
                break;
            }
        }
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"flushQueue exception %@",exception);
    }
}

- (BOOL)request:(NSString *)endpoint WithData:(NSString *)requestData andError:(NSError *)error {
    __block BOOL success = NO;
    __block int  retry = 0;
    while (!success && retry < 3) {
        NSURL *URL = nil;
        if (retry > 0 && self.backupURL) {
            URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/apipool/",self.backupURL]];
        }else{
            URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",self.apiURL,endpoint]];
        }
        ZGLogDebug(@"api request url = %@ , retry = %d",URL,retry);
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [request setHTTPMethod:@"POST"];
        NSString * bodyString = [requestData stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"#%<>[\\]^`{|}\"]+"].invertedSet];
        [request setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];

        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [[[ZGRequestManager sharedURLSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable responseData, NSURLResponse * _Nullable urlResponse, NSError * _Nullable error) {
                          
            success = [self handleResponseData:responseData withHttpResponse:(NSHTTPURLResponse *)urlResponse withError:error];
            
            if (!success || error) {
                ZGLogDebug(@"%@ Network Request Fail %@",self,error);
                retry ++;
            } else {
                NSString *response = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                ZGLogDebug(@"API响应: %@",response);
            }
            
            dispatch_semaphore_signal(semaphore);
        }] resume];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        return success? YES : NO;
        
    }
    
    return success;
}

- (BOOL)handleResponseData:(NSData *)responseData withHttpResponse:(NSHTTPURLResponse *)httpResponse withError:(NSError *)error {

    NSInteger statusCode = 0;
    NSInteger responseCode = 0;
    
    if (httpResponse) {
        statusCode = [httpResponse statusCode];
    }
    
    if (responseData) {
        NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&error];
        responseCode = [responseObject[@"return_code"] intValue];
    }
    
    if (statusCode == 200 && responseCode == 0) {
        return YES;
    }
    
    return NO;
}


#pragma  mark - 持久化
// 文件根路径
- (NSString *)filePathForData:(NSString *)data {
    NSString *filename = [NSString stringWithFormat:@"zhuge-%@-%@.plist", self.appKey, data];
    return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
            stringByAppendingPathComponent:filename];
}
// 环境信息
-(NSString *)environmentInfoFilePath{
    return [self filePathForData:@"environment"];
}
// 事件路径
- (NSString *)eventsFilePath {
    return [self filePathForData:@"events"];
}
// 属性路径
- (NSString *)propertiesFilePath {
    return [self filePathForData:@"properties"];
}
// 属性路径
- (NSString *)seeStateFilePath {
    return [self filePathForData:@"see-state"];
}

- (void)archive {
    @try {
        [self archiveEvents];
        [self archiveProperties];
        [self archiveEnvironmentInfo];
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"archive exception %@",exception);
    }
}
- (void)archiveEvents {
    NSString *filePath = [self eventsFilePath];
    NSMutableArray *eventsQueueCopy = [NSMutableArray arrayWithArray:[self.eventsQueue copy]];
    ZGLogDebug(@"保存事件到 %@",filePath);
    if (![NSKeyedArchiver archiveRootObject:eventsQueueCopy toFile:filePath]) {
        ZGLogDebug(@"事件保存失败");
    }
}
- (void)archiveProperties {
    NSString *filePath = [self propertiesFilePath];
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    [p setValue:self.userId forKey:@"userId"];
    [p setValue:self.deviceId forKey:@"deviceId"];
    [p setValue:self.sessionId forKey:@"sessionId"];
    NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
    [DateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *today = [DateFormatter stringFromDate:[NSDate date]];
    [p setValue:[NSString stringWithFormat:@"%lu",(unsigned long)self.sendCount] forKey:[NSString stringWithFormat:@"sendCount-%@", today]];
    
    ZGLogDebug(@"保存属性到 %@: %@",  filePath, p);
    if (![NSKeyedArchiver archiveRootObject:p toFile:filePath]) {
        ZGLogDebug(@"属性保存失败");
    }
}
- (void)archiveSeeState{
    @try{
        NSString *filePath = [self seeStateFilePath];
        if (![NSKeyedArchiver archiveRootObject:@"YES" toFile:filePath]) {
            ZGLogDebug(@"zhuge see state保存失败");
        }
    }@catch (NSException *e){
        ZGLogDebug(@"保存see state失败.%@",e);
    }
}
- (void)archiveEnvironmentInfo{
    if (!self.envInfo) {
        return;
    }
    NSString *filePath = [self environmentInfoFilePath];
    NSMutableDictionary *dic = [self.envInfo copy];
    if (![NSKeyedArchiver archiveRootObject:dic toFile:filePath]) {
        ZGLogDebug(@"自定义环境信息保存失败");
    }
}

- (void)unarchive {
    @try {
        [self unarchiveEvents];
        [self unarchiveProperties];
        [self unarchiveSeeState];
        [self unarchiveEnvironmentInfo];
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"unarchive exception %@",exception);
    }
}
- (id)unarchiveFromFile:(NSString *)filePath deleteFile:(BOOL) delete{
    id unarchivedData = nil;
    @try {
        unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"恢复数据失败");
        unarchivedData = nil;
    }
    if (delete && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError *error;
        BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (!removed) {
            ZGLogDebug(@"删除数据失败 %@", error);
        }else{
            ZGLogDebug(@"删除缓存数据 %@",filePath);
        }
    }
    return unarchivedData;
}
- (void)unarchiveEnvironmentInfo{
    self.envInfo = (NSMutableDictionary *)[[self unarchiveFromFile:[self environmentInfoFilePath] deleteFile:NO] mutableCopy];
    if (self.envInfo) {
        if([self.envInfo objectForKey:@"event"]){
            ZGLogDebug(@"全局自定义事件信息：%@",self.envInfo[@"event"]);
        }
        if ([self.envInfo objectForKey:@"device"]) {
            ZGLogDebug(@"自定义设备信息：%@",self.envInfo[@"device"]);        }
    }
}
- (void)unarchiveEvents {
    self.eventsQueue = (NSMutableArray *)[[self unarchiveFromFile:[self eventsFilePath] deleteFile:YES] mutableCopy];
    if (!self.eventsQueue) {
        self.eventsQueue = [NSMutableArray array];
    }
}
- (void)unarchiveProperties {
    NSDictionary *properties = (NSDictionary *)[self unarchiveFromFile:[self propertiesFilePath] deleteFile:NO];
    if (properties) {
        self.userId = properties[@"userId"] ? properties[@"userId"] : @"";
        if (!self.deviceId) {
            self.deviceId = properties[@"deviceId"] ? properties[@"deviceId"] : [ZADeviceId getZADeviceId];
        }

        self.sessionId = [properties[@"sessionId"] integerValue] > 0? properties[@"sessionId"] : nil;
        NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
        [DateFormatter setDateFormat:@"yyyyMMdd"];
        NSString *today = [DateFormatter stringFromDate:[NSDate date]];
        NSString *sendCountKey = [NSString stringWithFormat:@"sendCount-%@", today];
        self.sendCount = properties[sendCountKey] ? [properties[sendCountKey] intValue] : 0;
    }
}
- (void)unarchiveSeeState{
    NSString *seeState = (NSString *)[self unarchiveFromFile:[self seeStateFilePath] deleteFile:NO];
    if (seeState) {
        self.localZhugeSeeState = YES;
    }
}

#pragma mark - RNAutoTrack
- (void)ignoreViewType:(Class)aClass {
    [self.ignoredViewTypeList addObject:aClass];
}
- (BOOL)isViewTypeIgnored:(Class)aClass {
    for (Class obj in self.ignoredViewTypeList) {
        if ([aClass isSubclassOfClass:obj]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark - Codeless
+ (UIApplication *)sharedUIApplication {
    if ([[UIApplication class] respondsToSelector:@selector(sharedApplication)]) {
        return [[UIApplication class] performSelector:@selector(sharedApplication)];
    }
    return nil;
}
- (void)onShakeGestureDo {
    [self connectToWebSocket];
}
- (void)setupCodelessWebsocketUrl:(NSString *)url {
    if (url && url.length > 0) {
        self.websocketUrl = url;
    } else {
        ZGLogDebug(@"传入的url不合法，请检查:%@",url);
    }
}
- (void)setupCodelessEventsUrl:(NSString *)url {
    if (url && url.length > 0) {
        self.codelessEventsUrl = url;
    } else {
        ZGLogDebug(@"传入的url不合法，请检查:%@",url);
    }
}
- (void)connectToWebSocket {
    [self connectToABTestDesigner:NO];
}
- (void)connectToABTestDesigner:(BOOL)reconnect {
    
    if (self.config.enableCodeless == NO) { return; }
    
//        NSString *designerURLString = @"wss://switchboard.mixpanel.com/connect?key=ac42f38893a82565a3e55a86321be361&type=device";
//    NSString *designerURLString = [NSString stringWithFormat:@"%@/codeless/connect?ctype=client&platform=ios&appkey=%@", self.websocketUrl, self.appKey];
    NSString *designerURLString = [NSString stringWithFormat:@"%@/connect?ctype=client&platform=ios&appkey=%@", self.websocketUrl, self.appKey];
    NSURL *designerURL = [NSURL URLWithString:designerURLString];
    ZGLogDebug(@"Websocket url == %@", designerURLString);
    __weak Zhuge *weakSelf = self;
    void (^connectCallback)(void) = ^{
        __strong Zhuge *strongSelf = weakSelf;
    
        [Zhuge sharedUIApplication].idleTimerDisabled = YES;
        if (strongSelf) {
            for (ZGVariant *variant in self.variants) {
                [variant stop];
            }
            for (ZGEventBinding *binding in self.eventBindings) {
                [binding stop];
            }
            ZGABTestDesignerConnection *connection = strongSelf.abtestDesignerConnection;
            void (^block)(id, SEL, NSString*, id) = ^(id obj, SEL sel, NSString *event_name, id params) {
                MPDesignerTrackMessage *message = [MPDesignerTrackMessage messageWithPayload:@{@"event_name": event_name}];
                [connection sendMessage:message];
            };

            [MPSwizzler swizzleSelector:@selector(track:properties:) onClass:[Zhuge class] withBlock:block named:@"track_properties"];
        }
    };
    void (^disconnectCallback)(void) = ^{
        __strong Zhuge *strongSelf = weakSelf;
        
        [Zhuge sharedUIApplication].idleTimerDisabled = NO;
        if (strongSelf) {
            for (ZGVariant *variant in self.variants) {
                [variant execute];
            }
            for (ZGEventBinding *binding in self.eventBindings) {
                [binding execute];
            }
            [MPSwizzler unswizzleSelector:@selector(track:properties:) onClass:[Zhuge class] named:@"track_properties"];
        }
    };
    self.abtestDesignerConnection = [[ZGABTestDesignerConnection alloc] initWithURL:designerURL
                                                                         keepTrying:reconnect
                                                                    connectCallback:connectCallback
                                                                 disconnectCallback:disconnectCallback];
}
- (void)checkForDecideResponseWithCompletion:(void (^)(NSSet *eventBinding))completion useCathe:(BOOL)useCache{
    dispatch_async(self.serialQueue, ^{
        
        if (!useCache) {
            NSString* urlString = [NSString stringWithFormat:@"%@/v1/events/codeless/appkey/%@/platform/2?app_version=%@&updateTimeId=%@",self.codelessEventsUrl,self.appKey,self.config.appVersion,@"0"];
            ZGLogDebug(@"%@请求远程事件: %@",self,urlString);
            
            NSURL *URL = [NSURL URLWithString:urlString];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
            [[[ZGRequestManager sharedURLSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable responseData, NSURLResponse * _Nullable urlResponse, NSError * _Nullable error) {
                       
                if (responseData) {
                    
                    NSDictionary *object = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
                    
                    if (error) {
                        ZGLogDebug(@"%@ decide check json error: %@, data: %@", self, error, [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                        return;
                    }
                    
                    NSArray *eventInfos = object[@"event_infos"];
                    NSMutableArray *rawEventBindings = [NSMutableArray array];
                    
                    if (eventInfos&&eventInfos.count>0) {
                        for (id  eventInfo in eventInfos) {
                            NSDictionary * info = eventInfo[@"eventJson"];
                            [rawEventBindings addObject:info];
                        }
                    }
                    NSMutableSet *parsedEventBindings = [NSMutableSet set];
                    if (rawEventBindings && [rawEventBindings isKindOfClass:[NSArray class]]&& rawEventBindings.count > 0) {
                        for (NSString *obj in rawEventBindings) {
                            NSData *data = [obj dataUsingEncoding:NSUTF8StringEncoding];
                            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                            ZGEventBinding *binder = [ZGEventBinding bindingWithJSONObject:json];
                            if (binder) {
                                [parsedEventBindings addObject:binder];
                            }
                        }
                    } else {
                        ZGLogDebug(@"%@ tracking events check response format error: %@", self, object);
                        return;
                    }
                    
                    // Finished bindings are those which should no longer be run.
                    NSMutableSet *finishedEventBindings = [NSMutableSet setWithSet:self.eventBindings];
                    [finishedEventBindings minusSet:parsedEventBindings];
                    [finishedEventBindings makeObjectsPerformSelector:NSSelectorFromString(@"stop")];
                    
                    self.eventBindings = [parsedEventBindings copy];
                    
                    ZGLogDebug(@"%@ 获得 %lu 个追踪事件: %@", self, (unsigned long)[self.eventBindings count], self.eventBindings);
                    
                    if (completion) {
                        completion(self.eventBindings);
                    }
                    
                } else {
                    ZGLogDebug(@"%@ https error: %@", self, error);
                    return;
                }
                
            }] resume];
    
        } else {
            ZGLogDebug(@"%@ decide cache found, skipping network request", self);
        }
        
    });
}

#pragma mark - WKWebView 数据打通
- (void)swizzleWebViewMethod {
    static dispatch_once_t onceTokenWebView;
    dispatch_once(&onceTokenWebView, ^{
        NSError *error = NULL;

        [WKWebView za_swizzleMethod:@selector(loadRequest:)
                         withMethod:@selector(zhugeio_loadRequest:)
                              error:&error];

        [WKWebView za_swizzleMethod:@selector(loadHTMLString:baseURL:)
                         withMethod:@selector(zhugeio_loadHTMLString:baseURL:)
                              error:&error];

        if (@available(iOS 9.0, *)) {
            [WKWebView za_swizzleMethod:@selector(loadFileURL:allowingReadAccessToURL:)
                             withMethod:@selector(zhugeio_loadFileURL:allowingReadAccessToURL:)
                                  error:&error];

            [WKWebView za_swizzleMethod:@selector(loadData:MIMEType:characterEncodingName:baseURL:)
                             withMethod:@selector(zhugeio_loadData:MIMEType:characterEncodingName:baseURL:)
                                  error:&error];
        }

        if (error) {
            ZGLogError(@"Failed to swizzle on WKWebView. Details: %@", error);
            error = NULL;
        }
    });
}

- (void)addScriptMessageHandlerWithWebView:(WKWebView *)webView {
    NSAssert([webView isKindOfClass:[WKWebView class]], @"此注入方案只支持 WKWebView！❌");
    if (![webView isKindOfClass:[WKWebView class]]) {
        return;
    }

    @try {
        
        if (self.config.enableJavaScriptBridge) {
            //获取当前 WebView 的 WKUserContentController
            WKUserContentController *contentController = webView.configuration.userContentController;

            //给 WKUserContentController 设置一个js脚本控制器 
            [contentController removeScriptMessageHandlerForName:ZA_SCRIPT_MESSAGE_HANDLER_NAME];
            [contentController addScriptMessageHandler:[[ZhugeJS alloc]init] name:ZA_SCRIPT_MESSAGE_HANDLER_NAME];
        }

    } @catch (NSException *exception) {
        ZGLogError(@"%@ error: %@", self, exception);
    }
}

@end
