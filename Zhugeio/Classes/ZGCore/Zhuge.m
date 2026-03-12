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
#import "ZGVisualizationManager.h"
#import "UIControl+ZGClick.h"
#import "ZGVisualizationSocketMessage.h"
#import "ZGIDFAUtil.h"
#import "ZGPrivacyManager.h"

static NSMutableDictionary *instanceDic;
static NSMutableArray *autoTrackInstance;
static NSMutableArray *durationInstance;
static NSMutableArray *exposeInstance;
static NSMutableArray *visualInstance;
static NSArray *customGestureViewArray;
static NSString *deviceId;
static BOOL idfaCollect;
// 判断 viewDidAppear 是否已经被 hook
static BOOL viewDidAppearIsHook;
// 判断 viewDidDisappear 是否已经被 hook
static BOOL viewDidDisappearIsHook;
static BOOL logEnable;

@implementation Zhuge

+(void)initialize{
    instanceDic = [[NSMutableDictionary alloc]init];
    autoTrackInstance = [[NSMutableArray alloc] init];
    durationInstance = [[NSMutableArray alloc] init];
    exposeInstance = [[NSMutableArray alloc] init];
    visualInstance = [[NSMutableArray alloc] init];
    customGestureViewArray = [NSArray array];
    deviceId = nil;
    idfaCollect = NO;
    viewDidAppearIsHook = NO;
    viewDidDisappearIsHook = NO;
}

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
+(Zhuge *)newInstance{
    Zhuge *instance = [[[self class] alloc] init];
    instance.config = [[ZhugeConfig alloc] init];
    instance.eventTimeDic = [[NSMutableDictionary alloc] init];
    return instance;
}

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

+(void)enableIDFACollect{
    idfaCollect = YES;
}
+(BOOL)isIDFAEnable{
    return idfaCollect;
}
+(NSArray *)allInstance{
    return [instanceDic allValues];
}
+(NSArray *)durationOnPageInstance{
    return durationInstance;
}
+(NSArray *)exposeInstance{
    return exposeInstance;
}
+(NSArray *)autoTrackInstance{
    return autoTrackInstance;
}
+(NSArray *)visualInstance{
    return visualInstance;
}
+(void)setCustomGestureViews:(NSArray *)views{
    customGestureViewArray = views;
}
+(NSArray *)getCustomGestureViews{
    return customGestureViewArray;
}
+(Zhuge *)getInstanceForKey:(NSString *)appkey{
    return [instanceDic objectForKey:appkey];
}
+(void)openLog{
    logEnable = YES;
}
+ (BOOL)isLogEnable{
    return logEnable;
}
+(void)setPrivacyAgree:(BOOL)agree{
    [[ZGPrivacyManager sharedManager] setUserAgreed:agree];
}
+(void)setPrivacyControl:(BOOL)enable{
    [[ZGPrivacyManager sharedManager] setPrivacyControl:enable];
}
- (ZhugeConfig *)config {
    return _config;
}

- (void)startWithConfig:(ZhugeConfig *)config andDid:(NSString *)did launchOptions:(NSDictionary *)launchOptions{
    if (!deviceId || deviceId.length == 0) {
        deviceId = [did copy];
    }
    [self initWithConfig:config launchOptions:launchOptions];
}

- (void)startWithConfig:(ZhugeConfig *)config {
    [self initWithConfig:config launchOptions:nil];
}

- (void)startWithConfig:(ZhugeConfig *)config launchOptions:(NSDictionary *)launchOptions {
    [self initWithConfig:config launchOptions:launchOptions];
}

- (void)initWithConfig:(ZhugeConfig *)config launchOptions:(NSDictionary *)launchOptions{
    @try {
        if (self.isInitSDK) {
            ZGLogError(@"已经初始化完成。");
            return;
        }
        if (config.appKey == nil || [config.appKey length] == 0) {
            ZGLogError(@"appKey不能为空。");
            return;
        }
        self.config = config;
        self.userId = @"";
        self.sessionId = nil;
        self.net = @"";
        self.radio = @"";
        self.telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
        self.taskId = UIBackgroundTaskInvalid;
        NSString *label = [NSString stringWithFormat:@"io.zhuge.%@", config.appKey];
        self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        NSString *uploadLabel = [NSString stringWithFormat:@"io.zhuge.upload.%@", config.appKey];
        self.uploadQueue = dispatch_queue_create([uploadLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        self.cr = [self carrier];

        // 耗时操作放入串行队列，避免阻塞主线程
        dispatch_async(self.serialQueue, ^{
            // 初始化数据库
            self.dbAdapter = [[ZhugeDbAdapter alloc] initWithAppKey:config.appKey];
            
            // 恢复旧版数据（如果有）
            [self unarchive];
            
            // 迁移旧数据：如果从文件恢复了事件，将其全部迁移到数据库
            if (self.eventsQueue.count > 0) {
                //确保迁移的数据都是字典类型
                NSPredicate *dictPredicate = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bind) {
                    return [obj isKindOfClass:[NSDictionary class]];
                }];
                NSArray *validEvents = [self.eventsQueue filteredArrayUsingPredicate:dictPredicate];
                if (validEvents.count > 0) {
                    ZGLogInfo(@"迁移旧版文件缓存数据 %lu 条到数据库", (unsigned long)validEvents.count);
                    [self.dbAdapter addAllEvent:validEvents];
                }
                [self.eventsQueue removeAllObjects];
            }
        });

        if (self.config.isEnableDurationOnPage) {
            [self enabelDurationOnPage];
        }
        
        if (self.config.enableJavaScriptBridge) {
            [self swizzleWebViewMethod];
        }
        if (self.config.autoTrackEnable) {
            [self enableAutoTrack];
        }
        if (self.config.isEnableExpTrack) {
            [self enableExpTrack];
        }
        // SDK配置
        if(self.config) {
            ZGLogInfo(@"SDK appkey %@", self.config.appKey);
            ZGLogInfo(@"SDK系统配置: %@", self.config);
        }
        if (self.config.debug) {
            [self.config setSendInterval:2];
        }

        [self setupListeners];
        self.allowUplode = YES;
        
        if (launchOptions && launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
            [self trackPush:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] type:@"launch"];
        }
        static dispatch_once_t exceptionOnce;
        dispatch_once(&exceptionOnce, ^{
            previousHandler = NSGetUncaughtExceptionHandler();
            NSSetUncaughtExceptionHandler(&ZhugeUncaughtExceptionHandler);
        });
        
        if(self.config.enableVisualization){
            [visualInstance addObject:self];
            [self hookAutoTrack];
            static dispatch_once_t visualOnce;
            dispatch_once(&visualOnce, ^ {
                NSError *error = NULL;
                [UIControl zhuge_swizzleMethod:@selector(addTarget:action:forControlEvents:)
                                    withMethod:@selector(zg_addTarget:action:forControlEvents:)
                                             error:&error];
                if (error) {
                    ZGLogError(@"swizzle application action failed ,%@",error);
                    error = NULL;
                }
            });
            //请求可视化事件列表数据
            [self requestVisualizationPageTrackDatas];
        }
        
        self.isInitSDK = YES;
        [instanceDic setObject:self forKey:self.config.appKey];
        
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"startWithAppKey exception %@",exception);
    }
}

- (void)trackException:(NSException *) exception{
    if (![[ZGPrivacyManager sharedManager] isUserAgreed]) {
        return;
    }
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
    NSString *requestData = [self getUploadData:eventData];
    BOOL success = [self request:@"/APIPOOL/" WithData:requestData andError:nil];
    
    success ? ZGLogDebug(@"上传崩溃事件成功") : ZGLogDebug(@"上传崩溃事件失败");
}
// 出现崩溃时的回调函数
void ZhugeUncaughtExceptionHandler(NSException * exception){
    NSArray *array = [instanceDic allValues];
    for (Zhuge *sdk in array) {
        [sdk applicationWillTerminate:nil];
        if (sdk.config.exceptionTrack) {
            [sdk trackException:exception];
        }
    }
    if (previousHandler) {
        previousHandler(exception);
    }
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



- (void)setSuperProperty:(NSDictionary *)info{
    NSDictionary *infoCopy = [info copy];
    dispatch_async(self.serialQueue, ^{
        if (!self.envInfo) {
            self.envInfo = [[NSMutableDictionary alloc] init];
        }
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:infoCopy];
        self.envInfo[@"event"] = dic;
        // 实时持久化环境信息
        [self archiveEnvironmentInfo];
    });

}
-(NSDictionary *)getSuperProperties{
    if (!self.envInfo) {
        return [NSDictionary dictionary];
    }
    NSMutableDictionary *event = [self mutableEventDictionaryCreatingIfNeeded:YES];
    return event;

}

-(void)clearSuperProperty{
    if (!self.envInfo) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
        [self.envInfo removeObjectForKey:@"event"];
        // 实时持久化环境信息
        [self archiveEnvironmentInfo];
    });
}

-(void)deleteSuperPropertyWithKey:(NSString *)key{
    if (!self.envInfo) {
        self.envInfo = [[NSMutableDictionary alloc] init];
        return;
    }
    NSString *keyCopy = [key copy];
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *event = [self mutableEventDictionaryCreatingIfNeeded:NO];
        [event removeObjectForKey:keyCopy];
        self.envInfo[@"event"] = event;
        // 实时持久化环境信息
        [self archiveEnvironmentInfo];
    });
}
-(void)addSuperProperty:(NSDictionary *)info{
    if (!self.envInfo) {
        self.envInfo = [[NSMutableDictionary alloc] init];
        return;
    }
    if (![info isKindOfClass:[NSDictionary class]]) return;
    NSDictionary *infoCopy = [info copy];
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *event = [self mutableEventDictionaryCreatingIfNeeded:YES];
        [event addEntriesFromDictionary:infoCopy];
        self.envInfo[@"event"] = event;
        // 实时持久化环境信息
        [self archiveEnvironmentInfo];
    });
}

-(void)addSuperPropertyWithKey:(NSString *)key value:(NSString *)value{
    if (!value) {
        [self deleteSuperPropertyWithKey:key];
        return;
    }
    NSString *keyCopy = [key copy];
    NSString *valueCopy = [value copy];
    dispatch_async(self.serialQueue, ^{
       if (!valueCopy) {
           NSMutableDictionary *event = [self mutableEventDictionaryCreatingIfNeeded:NO];
           [event removeObjectForKey:keyCopy];
           self.envInfo[@"event"] = event;
       } else {
           NSMutableDictionary *event = [self mutableEventDictionaryCreatingIfNeeded:YES];
           [event setObject:valueCopy forKey:keyCopy];
           self.envInfo[@"event"] = event;
       }
       // 实时持久化环境信息
       [self archiveEnvironmentInfo];
    });
}

- (void)enabelDurationOnPage {
    if (![durationInstance containsObject:self]) {
        [durationInstance addObject:self];
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //$AppViewScreen
        if (!viewDidAppearIsHook) {
            [UIViewController za_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(za_autotrack_viewDidAppear:) error:NULL];
            viewDidAppearIsHook = YES;
        }
        
        if (!viewDidDisappearIsHook) {
            [UIViewController za_swizzleMethod:@selector(viewDidDisappear:) withMethod:@selector(za_autotrack_viewDidDisappear:) error:NULL];
            viewDidDisappearIsHook = YES;
        }
        
    });
}
- (void)enableAutoTrack{
    if (![autoTrackInstance containsObject:self]) {
        [autoTrackInstance addObject:self];
    }
    [self hookAutoTrack];
    [self.config setAutoTrackEnable:YES];
}

-(void)hookAutoTrack{
    static dispatch_once_t autoOnce;
    dispatch_once(&autoOnce, ^ {
        NSError *error = NULL;
        
        //$AppViewScreen
        if (!viewDidAppearIsHook) {
            [UIViewController za_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(za_autotrack_viewDidAppear:) error:NULL];
            viewDidAppearIsHook = YES;
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
}

- (void)enableExpTrack {
    if (![exposeInstance containsObject:self]) {
        [exposeInstance addObject:self];
    }
    static dispatch_once_t expOnce;
    dispatch_once(&expOnce, ^{
        
        if (!viewDidAppearIsHook) {
            
            [UIViewController za_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(za_autotrack_viewDidAppear:) error:NULL];

            viewDidAppearIsHook = YES;
        }
        
        [UIView za_swizzleMethod:@selector(layoutSubviews) withMethod:@selector(za_layoutSubviews) error:NULL];
    });
    
    [self.config setIsEnableExpTrack:YES];
}

- (void)setPlatform:(NSDictionary *)info{
    NSDictionary *infoCopy = [info copy];
    dispatch_async(self.serialQueue, ^{
        if (!self.envInfo) {
            self.envInfo = [NSMutableDictionary dictionary];
        }
        self.envInfo[@"device"] = infoCopy;
        // 实时持久化环境信息
        [self archiveEnvironmentInfo];
    });
}


/**
 * 开启加密上传和加密策略
 */
- (void)enableEncryptUpload:(BOOL)encrypt CryptoType:(int)cryptoType {
    self.config.enableEncrypt = encrypt;
    self.config.encryptType = cryptoType;
}

+ (NSString *)getDid {
    if (!deviceId) {
        deviceId = [ZADeviceId getZADeviceId];
    }
    
    return deviceId;
}
- (NSString *)getSid{
    
    if (!self.sessionId) {
        return @"";
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

    // iOS 13+ 使用 Scene 生命周期通知
    if (@available(iOS 13.0, *)) {
        [notificationCenter addObserver:self
                               selector:@selector(sceneDidActivate:)
                                   name:UISceneDidActivateNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(sceneDidEnterBackground:)
                                   name:UISceneDidEnterBackgroundNotification
                                 object:nil];
    }

    // Application 通知作为兜底（iOS 12 及以下，或 Scene 未正确配置时）
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

#pragma mark Scene 生命周期 (iOS 13+)

/// Scene 进入前台活跃状态
- (void)sceneDidActivate:(NSNotification *)notification API_AVAILABLE(ios(13.0)) {
    @try {
        NSLog(@"sceneDidActivate %@",notification.object);
        UIScene *scene = notification.object;
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            return;
        }

        UIWindowScene *windowScene = (UIWindowScene *)scene;
        if (windowScene.activationState != UISceneActivationStateForegroundActive) {
            return;
        }

        // 只有从无前台 Scene 变为有前台 Scene 时才处理
        if (!self.isForeground) {
            ZGLogDebug(@"sceneDidActivate: first scene became active");
            [self handleAppDidBecomeActive];
        }
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"sceneDidActivate exception %@", exception);
    }
}

/// Scene 进入后台状态
- (void)sceneDidEnterBackground:(NSNotification *)notification API_AVAILABLE(ios(13.0)) {
    @try {
        NSLog(@"sceneDidEnterBackground %@",notification.object);
        UIScene *scene = notification.object;
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            return;
        }

        // 延迟检查，确保 Scene 状态已更新
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            // 只有所有 Scene 都进入后台时才处理
            if (self.isForeground && ![ZGUtils hasAnyForegroundScene]) {
                ZGLogDebug(@"sceneDidEnterBackground: all scenes in background");
                [self handleAppDidEnterBackground];
            }
        });
    }
    @catch (NSException *exception) {
        ZGLogError(@"sceneDidEnterBackground exception %@", exception);
    }
}

#pragma mark 前后台公共处理逻辑

/// 应用进入前台的公共处理逻辑
- (void)handleAppDidBecomeActive {
    // 主线程同步设置标志位，防止竞态条件
    self.isForeground = YES;
    NSLog(@"handleAppDidBecomeActive");

    [self safeEndBackgroundTaskForId:self.taskId];
    // 主线程捕获时间戳
    NSNumber *nowTime = [NSNumber numberWithUnsignedLongLong:[[NSDate date] timeIntervalSince1970] * 1000];

    dispatch_async(self.serialQueue, ^{
        self.allowUplode = YES;
        // 使用捕获的时间戳进行校验
        [self checkStartNewsSession:nowTime];
        [self checkAdService];
        [self startFlushTimer];
    });
}

/// 应用进入后台的公共处理逻辑
- (void)handleAppDidEnterBackground {
    // 主线程同步设置标志位，防止竞态条件
    self.isForeground = NO;

    NSLog(@"handleAppDidEnterBackground");

    // 如果已有任务，先清理
    [self safeEndBackgroundTaskForId:self.taskId];

    __block UIBackgroundTaskIdentifier bgTask = UIBackgroundTaskInvalid;
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        self.allowUplode = NO;
        ZGLogInfo(@"BackgroundTaskWithExpirationHandler called, taskId = %lu", (unsigned long)bgTask);
        [self safeEndBackgroundTaskForId:bgTask];
    }];
    self.taskId = bgTask;

    [self stopFlushTimer];
    // 主线程捕获时间戳
    NSNumber *nowTime = [NSNumber numberWithUnsignedLongLong:[[NSDate date] timeIntervalSince1970] * 1000];

    dispatch_async(self.serialQueue, ^{
        // 使用捕获的时间戳
        [self updateSessionActiveTime:nowTime];
        // 确保入库
        [self flushAndPersistIfNeeded];
        [self forceFlush];

        // 将结束任务排在上传队列末尾，以尽量多地在后台上传数据
        dispatch_async(self.uploadQueue, ^{
            [self safeEndBackgroundTaskForId:bgTask];
        });
    });
}

#pragma mark Application 生命周期（兜底）

// 程序进入前台并处于活动状态时调用
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    @try {
        NSLog(@"applicationDidBecomeActive %@",notification.object);
        if (![notification.object isKindOfClass:[UIApplication class]]) {
            return;
        }

        UIApplication *application = (UIApplication *)notification.object;
        if (application.applicationState != UIApplicationStateActive) {
            return;
        }

        // iOS 13+ 由 Scene 通知处理，这里仅作为兜底
        if (@available(iOS 13.0, *)) {
            // 如果已经由 Scene 通知处理过，跳过
            if (self.isForeground) {
                return;
            }
            // 检查是否真的有前台 Scene（兜底逻辑）
            if (![ZGUtils hasAnyForegroundScene]) {
                return;
            }
        }

        [self handleAppDidBecomeActive];
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"applicationDidBecomeActive exception %@", exception);
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    @try {
        NSLog(@"applicationDidEnterBackground %@",notification.object);
        if (![notification.object isKindOfClass:[UIApplication class]]) {
            return;
        }

        UIApplication *application = (UIApplication *)notification.object;
        if (application.applicationState != UIApplicationStateBackground) {
            return;
        }

        // iOS 13+ 由 Scene 通知处理，这里仅作为兜底
        if (@available(iOS 13.0, *)) {
            // 如果已经由 Scene 通知处理过，跳过
            if (!self.isForeground) {
                return;
            }
            // 检查是否还有前台 Scene（兜底逻辑）
            if ([ZGUtils hasAnyForegroundScene]) {
                return;
            }
        }

        [self handleAppDidEnterBackground];
    }
    @catch (NSException *exception) {
        ZGLogError(@"applicationDidEnterBackground exception %@", exception);
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    @try {
        [self stopFlushTimer];
        self.allowUplode = NO;
        
        // 进程终止前同步刷盘
        [self.dbAdapter handleWillTerminate];
        [self archive];
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"applicationWillTerminate exception %@",exception);
    }
}

- (void)flushAndPersistIfNeeded {
    if (!self.isForeground) {
        [self.dbAdapter handleWillTerminate];
        [self archive];
    }
}

- (void)safeEndBackgroundTaskForId:(UIBackgroundTaskIdentifier)taskId {
    if (taskId == UIBackgroundTaskInvalid) {
        return;
    }
    @synchronized (self) {
        if (taskId != UIBackgroundTaskInvalid && taskId == self.taskId) {
            ZGLogDebug(@"safeEndBackgroundTask for id = %lu", (unsigned long)taskId);
            [[UIApplication sharedApplication] endBackgroundTask:taskId];
            self.taskId = UIBackgroundTaskInvalid;
        }
    }
}


#pragma mark - 设备状态
// 运营商
- (NSString *)carrier {
    if (![[ZGPrivacyManager sharedManager] isUserAgreed]) {
        return nil;
    }
    if (@available(iOS 12.0, *)) {
        NSDictionary<NSString *, CTCarrier *> *carriers =
            self.telephonyInfo.serviceSubscriberCellularProviders;

        for (CTCarrier *carrier in carriers.allValues) {
            NSString *mcc = carrier.mobileCountryCode;
            NSString *mnc = carrier.mobileNetworkCode;
            if (mcc.length && mnc.length) {
                return [NSString stringWithFormat:@"%@%@", mcc, mnc];
            }
        }
        return nil;
    } else {
        CTCarrier *carrier = self.telephonyInfo.subscriberCellularProvider;
        if (carrier != nil) {
            NSString *mcc =[carrier mobileCountryCode];
            NSString *mnc =[carrier mobileNetworkCode];
            if (mcc.length && mnc.length) {
                return [NSString stringWithFormat:@"%@%@", mcc, mnc];
            }
        }
        return nil;
    }
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

#pragma mark -广告归因
-(void) checkAdService{
    if(!idfaCollect){
        return;
    }
    if(self.lastUploadAdInfoAppVersion && [self.config.appVersion isEqualToString:self.lastUploadAdInfoAppVersion]){
        //当前版本已上传过归因数据，不再上传
        return;
    }
    if (@available(iOS 14.3, *)) {
        dispatch_async(self.uploadQueue, ^{
            NSString *token = [ZGIDFAUtil getAdToken];
            ZGLogInfo(@"get ad token %@",token);
            if (token) {
                [self checkUseADServiceWithToken:token];
            }
        });
    }
}

-(void)checkUseADServiceWithToken:(NSString *)token{
    if (token.length == 0) return;
    // 发送POST请求归因数据
    NSString *urlString = @"https://api-adservices.apple.com/api/v1/";
    NSURL *URL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request addValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    NSData* postData = [token dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:postData];
    [[[ZGRequestManager defaultURLSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable responseData, NSURLResponse * _Nullable urlResponse, NSError * _Nullable error) {
        if(!responseData){
            if (error) {
                ZGLogError(@"checkUseADServiceWithToken error :%@",error);
            }
            return;
        }
        NSError *resError;
        id jsonObj = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&resError];
        NSMutableDictionary *resDic = nil;
        if ([jsonObj isKindOfClass:[NSDictionary class]]) {
            resDic = [jsonObj mutableCopy];
        } else if(resError){
            NSString *strResponse = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            ZGLogError(@"checkUseADServiceWithToken Parse error %@ , string is %@",resError, strResponse);
        }
        ZGLogInfo(@"checkUseADServiceWithToken get response %@",resDic);
        if (resDic) {
            BOOL value = [[resDic objectForKey:@"attribution"] boolValue];
            if(value){
                [self buildADData:resDic];
            }
        }
          
    }] resume];
}

-(void)buildADData:(NSDictionary*) adData{
    NSMutableDictionary *e = [NSMutableDictionary dictionary];
    e[@"dt"] = @"adtf";
    NSMutableDictionary *pr = [self buildCommonData];
    pr[@"$channel_type"] = @5;
    NSError *error;
    
    NSData *jsonData = [self JSONSerializeObject:adData];
    if (jsonData) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        pr[@"$apple_ad"] = jsonString;
    }
    NSString *idfaString = [ZGIDFAUtil idfa];
    if(!idfaString){
        idfaString = @"";
    }
    pr[@"$idfa"] = idfaString;
    pr[@"$sl"] = @"zh";
    e[@"pr"] = pr;
    [self enqueueEvent:e];
    self.lastUploadAdInfoAppVersion = self.config.appVersion;
}

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
    if (!self.cr) {
        self.cr = [self carrier];
    }
    common[@"$cr"]  = self.cr?:@"(null)(null)";
    //毫秒偏移量
    common[@"$ct"] = [NSNumber numberWithUnsignedLongLong:[[NSDate date] timeIntervalSince1970] *1000];
    common[@"$tz"] = [NSNumber numberWithInteger:[[NSTimeZone localTimeZone] secondsFromGMT]*1000];//取毫秒偏移量
    common[@"$os"] = @"iOS";

    //DeepShare 信息
    [common addEntriesFromDictionary:self.utmDic];
    return common;
}


-(void)checkStartNewsSession{
    [self checkStartNewsSession:nil];
}

-(void)checkStartNewsSession:(NSNumber *)customTime{
    BOOL expired = YES;
    if (self.lastSessionActiveTime) {
        expired = [self isSessionExpired:self.lastSessionActiveTime currentTime:customTime];
    }
    ZGLogInfo(@"expired is %@ , lastTime is %llu",expired?@"Yes":@"No",[self.lastSessionActiveTime unsignedLongLongValue]);
    if (expired) {
        [self sessionEnd];
        [self sessionStartWithTime:customTime];
    } else {
        [self updateSessionActiveTime:customTime];
    }
}

-(void) updateSessionActiveTime:(NSNumber *)customTime{
    NSNumber *nowTime = customTime;
    if (!nowTime) {
        nowTime = [NSNumber numberWithUnsignedLongLong:[[NSDate date] timeIntervalSince1970] *1000];
    }
    self.lastSessionActiveTime = nowTime;
    uint64_t sessionIdValue = self.sessionId ? [self.sessionId unsignedLongLongValue] : 0;
    uint64_t dur = [self.lastSessionActiveTime unsignedLongLongValue] - sessionIdValue;
    ZGLogInfo(@"更新会话活跃时间：%llu, now dur = %llu", [self.lastSessionActiveTime unsignedLongLongValue], dur);
}

// 辅助方法：判断是否过期，支持自定义当前时间
- (BOOL)isSessionExpired:(NSNumber *)activeTime currentTime:(NSNumber *)customTime {
    if (!activeTime) return YES;
    uint64_t last = [activeTime unsignedLongLongValue];
    uint64_t now;
    if (customTime) {
        now = [customTime unsignedLongLongValue];
    } else {
        now = (uint64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    }
    uint64_t dur = now - last;
    ZGLogInfo(@"isSessionExpired sessionId %llu, activeTime %llu , dur is %llu",[self.sessionId unsignedLongLongValue],[activeTime unsignedLongLongValue] , dur);
    return dur > 30000; // 超过30秒
}


// 会话开始
- (void)sessionStartWithTime:(NSNumber *)customTime {
    @try {
        if (!self.sessionId) {
            //毫秒偏移量
            self.sessionCount = 0;
            if (customTime) {
                self.sessionId = customTime;
            } else {
                self.sessionId = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] *1000];
            }
            [self updateSessionActiveTime:self.sessionId]; // 使用 SessionID 作为活跃时间，确保一致性
            ZGLogDebug(@"会话开始(ID:%@)", self.sessionId);
            if (self.config.sessionEnable) {
                NSMutableDictionary *e = [NSMutableDictionary dictionary];
                e[@"dt"] = @"ss";
                NSMutableDictionary *pr = [self buildCommonData];
                // buildCommonData 内部使用了 [NSDate date]，为了严谨也应该支持传入时间，但 ct 字段通常宽容度较高
                // 这里暂时保持 buildCommonData 使用当前时间，只保证 sessionId 和 session 逻辑的时间准确性
                
                pr[@"$an"] = self.config.appName;
                pr[@"$cn"]  = self.config.channel;
                pr[@"$net"] = self.net;
                pr[@"$mnet"]= self.radio;
                pr[@"$ov"] = [[UIDevice currentDevice] systemVersion];
                pr[@"$sid"] = self.sessionId;
                pr[@"$vn"] = self.config.appVersion;
                pr[@"$sc"]= @0;
                if(idfaCollect){
                    NSString *idfaString = [ZGIDFAUtil idfa];
                    if(!idfaString){
                        idfaString = @"";
                    }
                    pr[@"$idfa"] = idfaString;
                }
                e[@"pr"] = pr;
                [self syncEnqueueEvent:e];
            }
        }
    }
    @catch (NSException *exception) {
        ZGLogError(@"sessionStart exception %@",exception);
    }
    [self uploadDeviceInfo];
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
                NSNumber *dru = @([self.lastSessionActiveTime unsignedLongLongValue] - [self.sessionId unsignedLongLongValue]);
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
                [self syncEnqueueEvent:e];
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
}

- (void)autoTrack:(NSDictionary *)info{
    if (![info objectForKey:@"$eid"]) {
        ZGLogDebug(@"auto track with illegal content %@",info);
        return;
    }
    if (!self.isForeground) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
        @try {
            if (!self.sessionId) {
                [self checkStartNewsSession];
            }
            
            NSMutableDictionary *data = [NSMutableDictionary dictionaryWithCapacity:2];
            NSMutableDictionary *pr = [self eventData];
            if (self.envInfo) {
                NSMutableDictionary *data = [self addSymbloToDic:[self.envInfo objectForKey:@"event"]];
                [pr addEntriesFromDictionary:data];
            }
            
            [pr addEntriesFromDictionary:info];
            [data setObject:pr forKey:@"pr"];
            [data setObject:@"abp" forKey:@"dt"];
            [self syncEnqueueEvent:data];
        }
        @catch (NSException *exception) {
            ZGLogError(@"start track properties exception %@",exception);
        }
    });
}

/// 可视化埋点上报
/// - Parameter properties: 上报数据
- (void)zgVisualizationTrack:(nonnull NSDictionary *)properties{
    if (![properties objectForKey:@"eventName"]) {
        ZGLogDebug(@"visualization track with illegal content %@",properties);
        return;
    }
    NSDictionary *pro = @{@"$from_binding":@"true"};
    [self track:properties[@"eventName"] properties:[NSMutableDictionary dictionaryWithDictionary:pro]];
}

- (void)startTrack:(NSString *)eventName{
    NSString *evtName = [eventName copy];
    @try {
        if (!evtName) {
            ZGLogDebug(@"startTrack event name must not be nil.");
            return;
        }
        dispatch_async(self.serialQueue, ^{
            NSNumber *ts = [NSNumber numberWithUnsignedLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
            ZGLogDebug(@"startTrack %@ at time : %@",evtName,ts);
            [self.eventTimeDic setValue:ts forKey:evtName];
        });
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"start track properties exception %@",exception);
    }
}

- (void)endTrack:(NSString *)eventName properties:(NSDictionary*)properties{
    NSString *evtName = [eventName copy];
    NSDictionary *props = [properties copy];
    @try {
        dispatch_async(self.serialQueue, ^{
            NSNumber *start = [self.eventTimeDic objectForKey:evtName];
            if (!start) {
                ZGLogDebug(@"end track event name not found ,have you called startTrack already?");
                return;
            }
            if (!self.sessionId) {
                [self checkStartNewsSession];
            }
            [self.eventTimeDic removeObjectForKey:evtName];
            uint64_t endTs = (uint64_t)([[NSDate date] timeIntervalSince1970] * 1000);
            uint64_t startTs = [start unsignedLongLongValue];
            uint64_t duration = (endTs > startTs) ? (endTs - startTs) : 0;
            
            ZGLogDebug(@"endTrack %@ at time : %llu, duration : %llu", evtName, endTs, duration);
            
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            NSNumber *dru = [NSNumber numberWithUnsignedLongLong:duration];
            dic[@"$dru"] = dru;
            dic[@"_$duration$_"] = dru;
            dic[@"$eid"] = evtName;
            int32_t value =  OSAtomicIncrement32(&self->_sessionCount);
            dic[@"$sc"] = [NSNumber numberWithInt:value];
            [dic addEntriesFromDictionary:[self eventData]];
            if ([self.envInfo isKindOfClass:[NSDictionary class]]) {
                NSDictionary *envCopy = [self.envInfo copy];
                NSDictionary *info = [envCopy objectForKey:@"event"];
                if ([info isKindOfClass:[NSDictionary class]]) {
                    NSMutableDictionary *data = [self addSymbloToDic:info];
                    [dic addEntriesFromDictionary:data];
                }
            }
            if ([props isKindOfClass: [NSDictionary class]]) {
                NSDictionary *copy = [self addSymbloToDic:props];
                [dic addEntriesFromDictionary:copy];
            }
            NSMutableDictionary *e = [NSMutableDictionary dictionaryWithCapacity:2];
            [e setObject:dic forKey:@"pr"];
            [e setObject:@"evt" forKey:@"dt"];
            [self syncEnqueueEvent:e];
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
    if (price.length == 0 || number.length == 0) {
        ZGLogDebug(@"价格和数量不能为空");
        return;
    }
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
    if (event == nil || [event length] == 0) {
        ZGLogDebug(@"事件名不能为空");
        return;
    }
    
    NSString *eventName = [event copy];
    NSDictionary *props = [properties copy];
    
    dispatch_async(self.serialQueue, ^{
        @try {
            if (!self.sessionId) {
                [self checkStartNewsSession];
            }
            NSMutableDictionary *pr = [self eventData];
            if ([self.envInfo isKindOfClass:[NSDictionary class]]) {
                NSDictionary *envCopy = [self.envInfo copy];
                NSDictionary *info = [envCopy objectForKey:@"event"];
                if ([info isKindOfClass:[NSDictionary class]]) {
                    NSMutableDictionary *dic = [self addSymbloToDic:info];
                    [pr addEntriesFromDictionary:dic];
                }
            }
            if (props) {
                [pr addEntriesFromDictionary:[self conversionRevenuePropertiesKey:props]];
            }
            pr[@"$eid"] = eventName;
            int32_t value =  OSAtomicIncrement32(&_sessionCount);
            pr[@"$sc"] = [NSNumber numberWithInt:value];
            NSMutableDictionary *e = [NSMutableDictionary dictionary];
            e[@"dt"] = @"abp";
            e[@"pr"] = pr;
            [self syncEnqueueEvent:e];
        }
        @catch (NSException *exception) {
            ZGLogDebug(@"track properties exception %@",exception);
        }
    });
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
    if (event == nil || [event length] == 0) {
        ZGLogDebug(@"事件名不能为空");
        return;
    }
    
    NSString *eventName = [event copy];
    NSDictionary *props = [properties copy];
    
    dispatch_async(self.serialQueue, ^{
        @try {
            if (!self.sessionId) {
                [self checkStartNewsSession];
            }
            NSMutableDictionary *pr = [self eventData];
            if ([self.envInfo isKindOfClass:[NSDictionary class]]) {
                NSDictionary *envCopy = [self.envInfo copy];
                NSDictionary *info = [envCopy objectForKey:@"event"];
                if ([info isKindOfClass:[NSDictionary class]]) {
                    NSMutableDictionary *dic = [self addSymbloToDic:info];
                    [pr addEntriesFromDictionary:dic];
                }
            }
            if (props) {
                [pr addEntriesFromDictionary:[self addSymbloToDic:props]];
            }
            pr[@"$eid"] = eventName;
            int32_t value =  OSAtomicIncrement32(&_sessionCount);
            pr[@"$sc"] = [NSNumber numberWithInt:value];
            NSMutableDictionary *e = [NSMutableDictionary dictionary];
            e[@"dt"] = @"evt";
            e[@"pr"] = pr;
            [self syncEnqueueEvent:e];
        }
        @catch (NSException *exception) {
            ZGLogDebug(@"track properties exception %@",exception);
        }
    });
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
    [self updateSessionActiveTime:nil];
    return pr;
}

- (void)identify:(NSString *)userId properties:(NSDictionary *)properties {
    if (userId == nil || userId.length == 0) {
        ZGLogDebug(@"用户ID不能为空");
        return;
    }
    
    NSString *uid = [userId copy];
    NSDictionary *props = [properties copy];
    
    dispatch_async(self.serialQueue, ^{
        @try {
            if (!self.sessionId) {
                [self checkStartNewsSession];
            }
            self.userId = uid;
            // 实时持久化 userId，防止前台 Crash 导致用户身份丢失
            [self archiveProperties];
            
            NSMutableDictionary *e = [NSMutableDictionary dictionary];
            e[@"dt"] = @"usr";
            NSMutableDictionary *pr = [self buildCommonData];
            if (props) {
                NSDictionary *dic = [self addSymbloToDic:props];
                [pr addEntriesFromDictionary:dic];
            }
            pr[@"$an"] = self.config.appName;
            pr[@"$cuid"] = uid;
            pr[@"$vn"] = self.config.appVersion;
            pr[@"$cn"]  = self.config.channel;
            e[@"pr"] = pr;
            [self syncEnqueueEvent:e];
        }
        @catch (NSException *exception) {
            ZGLogDebug(@"identify exception %@",exception);
        }
    });
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
        [self syncEnqueueEvent:e];
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"trackDeviceInfo exception, %@",exception);
    }
}

- (void)trackDurationOnPage:(NSDictionary *)properties {
    if (!self.isForeground) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
        @try {
            if (!self.sessionId) {
                [self checkStartNewsSession];
            }
            
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
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
            if ([properties isKindOfClass: [NSDictionary class]]) {
                NSDictionary *copy = [self addSymbloToDic:properties];
                [dic addEntriesFromDictionary:copy];
            }
            NSMutableDictionary *e = [NSMutableDictionary dictionaryWithCapacity:2];
            [e setObject:dic forKey:@"pr"];
            [e setObject:@"abp" forKey:@"dt"];
            [self syncEnqueueEvent:e];
        } @catch (NSException *exception) {
            ZGLogDebug(@"trackDurationOnPage exception %@",exception);
        }
    });
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
    batch[@"ak"]    = self.config.appKey;
    if (self.config.businessKey.length > 0) {
        batch[@"business"] = self.config.businessKey;
    }
    batch[@"debug"] = self.config.debug?@1:@0;
    batch[@"sln"]   = @"itn";
    batch[@"owner"] = @"zg";
    batch[@"pl"]    = @"ios";
    batch[@"sdk"]   = @"zg-ios";
    batch[@"sdkv"]  = self.config.sdkVersion;
    NSDictionary *dic = @{@"did":[Zhuge getDid]};
    batch[@"usr"]   = dic;
    batch[@"ut"]    = [ZGUtils currentDate];
    //取毫秒偏移量
    batch[@"tz"]    = [NSNumber numberWithInteger:[[NSTimeZone localTimeZone] secondsFromGMT]*1000];
    batch[@"data"]  = events;
    return batch;
}
#pragma mark - 编码&解码
- (NSMutableDictionary *)addSymbloToDic:(NSDictionary *)dic{
    if (!dic) {
        return  [NSMutableDictionary dictionary];
    }
    NSMutableDictionary *copy = [NSMutableDictionary dictionaryWithCapacity:[dic count]];
    for (NSString *key in dic) {
        id value = dic[key];
        if ([key hasPrefix:@"$"] || [key hasPrefix:@"_"]) {
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
    if (self.timer && [self.timer isValid]) {
        return;
    }
    [self stopFlushTimer];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.config.sendInterval > 0) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:self.config.sendInterval
                                                          target:self
                                                        selector:@selector(forceFlush)
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
    ZGLogDebug(@"%@ -产生事件: %@",self.config.appKey, event);
    [self.dbAdapter addEvent:event];
    [self flush];
}

- (void)flush {
    if ([self.dbAdapter eventCount] < self.config.limitCount) {
        return;
    }
    dispatch_async(self.uploadQueue, ^{
        [self flushInternal];
    });
}
- (void)forceFlush {
    dispatch_async(self.uploadQueue, ^{
        [self flushInternal];
    });
}

-(NSString*)getUploadData:(NSString *)eventData{
    NSString *requestData = nil;
    // ========================= 加密逻辑分支 =========================
    if (self.config.enableEncrypt) {
        if (self.config.encryptType == 1) {
            // ---------- AES + RSA ----------
            ZGLogDebug(@"启用了AES+RSA加密方式");
            NSString *key = [RSA_AES randomly16BitString];
            NSString *en = [RSA_AES AES256Encrypt:eventData key:key];
            NSString *rsaKeyIV = [RSA_AES encryptUseRSA:
                                  [NSString stringWithFormat:@"%@,%@", key, key]
                                  pubkey:self.config.uploadPubkey];

            requestData = [NSString stringWithFormat:
                @"method=event_statis_srv.upload&compress=1&encrypt=1&type=1&key=%@&event=%@",
                rsaKeyIV, en];
        }
        else if (self.config.encryptType == 2) {
            // ---------- SM4 + SM2 ----------
#if ZG_HAS_ENCRYPT_MODULE
            ZGLogDebug(@"启用了国密加密(SM4+SM2) , %d",ZG_HAS_ENCRYPT_MODULE);

            NSString *key = [GMSm4Utils createSm4Key];
            NSString *en = [GMSm4Utils ecbDefaultEncryptText:eventData key:key];

            NSString *pub = self.config.uploadSM2Pubkey;
            if ([pub containsString:@"-----BEGIN PUBLIC KEY-----"]) {
                pub = [GMSm2Bio readPublicKeyFromPemString:self.config.uploadSM2Pubkey];
            }

            NSString *sm2KeyIV = [ZGGMSm2Utils encryptText:
                                  [NSString stringWithFormat:@"%@,%@", key, key]
                                  publicKey:pub];
            sm2KeyIV = [ZGGMSm2Utils asn1DecodeToC1C3C2:sm2KeyIV];

            requestData = [NSString stringWithFormat:
                @"method=event_statis_srv.upload&compress=1&encrypt=1&type=2&key=%@&event=%@",
                sm2KeyIV, en];
#else
            ZGLogError(@"⚠️ 开启国密，但未引入国密模块(ZG_HAS_ENCRYPT_MODULE未定义)，取消上传。");
#endif
        }
        else {
            ZGLogError(@"未知加密类型:%lu，请检查配置", (unsigned long)self.config.encryptType);
        }
    }

    // ========================= 非加密逻辑 =========================
    if (!self.config.enableEncrypt) {
        ZGLogDebug(@"使用默认压缩上传");
        NSData *eventDataBefore = [eventData dataUsingEncoding:NSUTF8StringEncoding];
        NSData *zlibedData = [eventDataBefore zgZlibDeflate];
        NSString *event = [[zlibedData zgBase64EncodedString]
                           stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        requestData = [NSString stringWithFormat:
            @"method=event_statis_srv.upload&compress=1&encrypt=0&event=%@", event];
    }
    return requestData;

}

- (void)flushInternal {

    if (![[ZGPrivacyManager sharedManager] isUserAgreed]) {
        ZGLogDebug(@"隐私协议未同意，暂不发送数据。");
        return;
    }
    [self resetIfNotSameDay];
    // 每日发送限额检查
    if (self.sendCount >= self.config.sendMaxSizePerDay) {
        ZGLogDebug(@"超过每天限额，不发送。(今天已发送:%lu, 限额:%lu)",
                   (unsigned long)self.sendCount,
                   (unsigned long)self.config.sendMaxSizePerDay);
        return;
    }
    
    // 循环读取上传
    while (self.allowUplode) {
        @try {
            // 1. 从数据库获取一批事件 (默认25条)
            NSDictionary *eventsResult = [self.dbAdapter getEvents];
            if (!eventsResult || !eventsResult[kZhugeDbData]) {
                return; // 无数据，结束循环
            }
            
            NSArray *events = eventsResult[kZhugeDbData];
            NSNumber *lastId = eventsResult[kZhugeDbLastId];
            

            ZGLogDebug(@"开始上报事件(本次:%lu, 已发送:%lu, 限额:%lu)",
                       (unsigned long)events.count,
                       (unsigned long)self.sendCount,
                       (unsigned long)self.config.sendMaxSizePerDay);

            NSString *eventData = [self encodeAPIData:[self wrapEvents:events]];
            ZGLogDebug(@"上报事件：%@",eventData);
            NSString *requestData = [self getUploadData:eventData];
            
            BOOL success = NO;
            if (requestData) {
                // 网络请求 (这里原有的 request 方法包含重试逻辑)
                success = [self request:@"/APIPOOL/" WithData:requestData andError:nil];
            }
            
            // 3. 处理结果
            if (success) {
                ZGLogDebug(@"上传事件成功");
                self.sendCount += events.count;
                // 从数据库删除已上传的数据
                [self.dbAdapter removeEventsWithLastId:lastId];
            } else {
                ZGLogDebug(@"上传事件失败，中断上传。");
                return; // 失败则退出循环，等待下一次触发
            }
        }
        @catch (NSException *exception) {
            ZGLogDebug(@"flushInternal exception %@", exception);
            return;
        }
    }
}


- (BOOL)request:(NSString *)endpoint WithData:(NSString *)requestData andError:(NSError *)error {
    __block BOOL success = NO;
    __block int  retry = 0;
    NSString *backupUrl = [self.config getUploadBackupUrl];
    NSString *uploadUrl = [self.config getUploadUrl];
    while (!success && retry < 3) {
        NSURL *URL = nil;
        if (retry > 0 && backupUrl) {
            URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@",backupUrl]];
        }else{
            URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@",uploadUrl]];
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
        if (!success) {
            // 指数退避：1s, 2s, 4s
            if (retry < 3) {
                [NSThread sleepForTimeInterval:pow(2, retry - 1)];
            }
        }
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

- (void)resetIfNotSameDay {
    if (!self.uploadDate) {
        self.uploadDate = [NSDate date];
        self.sendCount = 0;
        return;
    }
    if (![ZGUtils isDateToday:self.uploadDate]) {
        self.sendCount = 0;
        self.uploadDate = [NSDate date];
    }
}



#pragma  mark - 持久化
// 文件根路径
- (NSString *)filePathForData:(NSString *)data {
    NSString *filename = [NSString stringWithFormat:@"zhuge-%@-%@.plist", self.config.appKey, data];
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

// 可视化对比路径
- (NSString *)visualizationFilePath {
    return [self filePathForData:@"visualization"];
}

- (void)archive {
    @try {
        [self archiveProperties];
        [self archiveEnvironmentInfo];
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"archive exception %@",exception);
    }
}

- (void)archiveVisualization:(NSArray *)visualizationDatas {
    @try{
        NSString *filePath = [self visualizationFilePath];
        if (![NSKeyedArchiver archiveRootObject:visualizationDatas toFile:filePath]) {
            ZGLogDebug(@"zhuge保存可视化比对数据失败");
        }
    }@catch (NSException *e){
        ZGLogDebug(@"zhuge保存可视化比对数据失败.%@",e);
    }
}

//- (void)archiveEvents {
//    NSString *filePath = [self eventsFilePath];
//    NSMutableArray *eventsQueueCopy = [NSMutableArray arrayWithArray:[self.eventsQueue copy]];
//    ZGLogDebug(@"保存 %lu 事件 到 %@",[self.eventsQueue count],filePath);
//    if (![NSKeyedArchiver archiveRootObject:eventsQueueCopy toFile:filePath]) {
//        ZGLogDebug(@"事件保存失败");
//    }
//}
- (void)archiveProperties {
    NSString *filePath = [self propertiesFilePath];
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    if (self.userId) [p setObject:self.userId forKey:@"userId"];
    if (deviceId) [p setObject:deviceId forKey:@"deviceId"];
    if (self.sessionId) [p setObject:self.sessionId forKey:@"sessionId"];
    if (self.lastSessionActiveTime) [p setObject:self.lastSessionActiveTime forKey:@"lastSessionActiveTime"];
    if (self.lastUploadAdInfoAppVersion) [p setObject:self.lastUploadAdInfoAppVersion forKey:@"lastUploadAdAppVersion"];
    
    NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
    [DateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *today = [DateFormatter stringFromDate:[NSDate date]];
    [p setValue:[NSString stringWithFormat:@"%lu",(unsigned long)self.sendCount] forKey:[NSString stringWithFormat:@"sendCount-%@", today]];
    
    ZGLogDebug(@"保存属性到 %@: %@",  filePath, p);
    if (![NSKeyedArchiver archiveRootObject:p toFile:filePath]) {
        ZGLogDebug(@"属性保存失败");
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
        [self unarchiveEnvironmentInfo];
        [self unarchiveVisualization];
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"unarchive exception %@",exception);
    }
}
- (id)unarchiveFromFile:(NSString *)filePath deleteFile:(BOOL) delete{
    if (!filePath || ![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return nil;
    }

    id unarchivedData = nil;
    @try {
        unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"从文件 %@ 恢复数据失败: %@", filePath, exception);
        unarchivedData = nil;
        // 如果文件损坏，建议直接删除，避免反复失败
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }

    if (delete) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSError *error;
            BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (!removed) {
                ZGLogDebug(@"删除数据失败 %@", error);
            }else{
                ZGLogDebug(@"删除缓存数据 %@",filePath);
            }
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
//兼容性代码，早期sdk使用archive保存数据，现在迁移到database，但仍然需要从旧的用户设备上恢复未上传的数据
- (void)unarchiveEvents {
    NSArray *events = [self unarchiveFromFile:[self eventsFilePath] deleteFile:YES];
    self.eventsQueue = [events isKindOfClass:[NSArray class]] ? [events mutableCopy] : [NSMutableArray array];
}
- (void)unarchiveProperties {
    NSDictionary *properties = (NSDictionary *)[self unarchiveFromFile:[self propertiesFilePath] deleteFile:NO];
    if (properties) {
        self.userId = properties[@"userId"] ? properties[@"userId"] : @"";
        if (!deviceId) {
            deviceId = properties[@"deviceId"] ? properties[@"deviceId"] : nil;
        }
        self.lastUploadAdInfoAppVersion = properties[@"lastUploadAdAppVersion"] ? properties[@"lastUploadAdAppVersion"]:@"";
        NSNumber *sessionIdNumber = properties[@"sessionId"];
        if ([sessionIdNumber longLongValue] > 0) {
            self.sessionId = sessionIdNumber;
        } else {
            self.sessionId = nil;
        }
        NSNumber *lastActiveNumber = properties[@"lastSessionActiveTime"];
        if ([lastActiveNumber longLongValue] > 0) {
            self.lastSessionActiveTime = lastActiveNumber;
        } else {
            self.lastSessionActiveTime = nil;
        }
        NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
        [DateFormatter setDateFormat:@"yyyyMMdd"];
        NSString *today = [DateFormatter stringFromDate:[NSDate date]];
        NSString *sendCountKey = [NSString stringWithFormat:@"sendCount-%@", today];
        self.sendCount = properties[sendCountKey] ? [properties[sendCountKey] intValue] : 0;
    }
}

- (void)unarchiveVisualization{
    NSArray * dataArr = (NSArray *)[self unarchiveFromFile:[self visualizationFilePath] deleteFile:NO];
    if (dataArr && _config.enableVisualization) {
        [[ZGVisualizationManager shareCustomerManger].compareDic setObject:dataArr forKey:self.config.appKey];
    }
}

#pragma mark - RNAutoTrack
//- (void)ignoreViewType:(Class)aClass {
//    [self.ignoredViewTypeList addObject:aClass];
//}
//- (BOOL)isViewTypeIgnored:(Class)aClass {
//    for (Class obj in self.ignoredViewTypeList) {
//        if ([aClass isSubclassOfClass:obj]) {
//            return YES;
//        }
//    }
//    return NO;
//}

- (NSMutableDictionary *)mutableEventDictionaryCreatingIfNeeded:(BOOL)createIfNeeded {
    if (!self.envInfo) {
        self.envInfo = [NSMutableDictionary dictionary];
    }
    id existing = self.envInfo[@"event"];
    if ([existing isKindOfClass:[NSMutableDictionary class]]) {
        return existing;
    } else if ([existing isKindOfClass:[NSDictionary class]]) {
        return [NSMutableDictionary dictionaryWithDictionary:existing];
    } else if (createIfNeeded) {
        return [NSMutableDictionary dictionary];
    } else {
        return nil;
    }
}

#pragma mark - Codeless
+ (UIApplication *)sharedUIApplication {
    if ([[UIApplication class] respondsToSelector:@selector(sharedApplication)]) {
        return [[UIApplication class] performSelector:@selector(sharedApplication)];
    }
    return nil;
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

+ (void)addScriptMessageHandlerWithWebView:(WKWebView *)webView {
    NSAssert([webView isKindOfClass:[WKWebView class]], @"此注入方案只支持 WKWebView！❌");
    if (![webView isKindOfClass:[WKWebView class]]) {
        return;
    }
    // 弱引用记录已注入 webView，避免重复
    static NSHashTable<WKWebView *> *injectedWebViews;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        injectedWebViews = [NSHashTable weakObjectsHashTable];
    });
    
    // 已注入过则直接返回
    if ([injectedWebViews containsObject:webView]) {
        return;
    }
    // 标记已注入
    [injectedWebViews addObject:webView];
    
    // 确保在主线程执行（WKWebView 配置对象不是线程安全的）
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            WKUserContentController *controller = webView.configuration.userContentController;
            NSString *name = ZA_SCRIPT_MESSAGE_HANDLER_NAME;
            
            // iOS 11–13 removeScriptMessageHandlerForName 崩溃保护
            // 这些系统在 handler 不存在时 remove 会 crash
            if (@available(iOS 14.0, *)) {
                [controller removeScriptMessageHandlerForName:name];
            } else {
                @try {
                    [controller removeScriptMessageHandlerForName:name];
                } @catch (NSException *e) {
                    NSLog(@"[Protect] WKWebView remove handler crash avoided: %@", e);
                }
            }
            
            id handler = [[ZhugeJS alloc]init];
            
            // iOS 14+ 使用 addScriptMessageHandlerWithReply（更安全）
            if (@available(iOS 14.0, *)) {
                [controller addScriptMessageHandlerWithReply:handler
                                                contentWorld:WKContentWorld.pageWorld
                                                        name:name];
            } else {
                [controller addScriptMessageHandler:handler name:name];
            }
        } @catch (NSException *exception) {
            ZGLogError(@"JS handler injection error: %@", exception);
        }
    });
}

#pragma mark - 可视化埋点

+(void)zg_startVisualizationDebuggingTrack:(NSURL *)url{
    [ZGVisualizationManager shareCustomerManger].enableDebugVisualization = YES;
    // 获取数据
    NSDictionary * urlDict = [self zg_getParamsWithUrlString:url.absoluteString];
    NSString  *appKey = urlDict[@"appKey"];
    if (!appKey || appKey.length == 0) {
        ZGLogError(@"可视化ws未找到appKey，请联系zhuge！");
        return;
    }
    Zhuge *zhuge = instanceDic[appKey];
    if (!zhuge) {
        ZGLogError(@"%@对应主体未初始化，请先初始化zhuge",appKey);
        return;
    }
    if (!zhuge.config.enableVisualization) {
        ZGLogError(@"%@对应主体未开启可视化埋点",appKey);
        return;
    }
    zhuge.appId = urlDict[@"appId"];
    zhuge.appSocketToken = urlDict[@"token"];
    NSString * websocketUrl = [NSString stringWithFormat:@"%@/eventtracking/ws?socketToken=%@&appId=%@&origin=2",zhuge.config.visualWebsocketUrl,zhuge.appSocketToken,zhuge.appId];
    [ZGVisualizationManager shareCustomerManger].zg_reportTime = zhuge.config.debugVisualizationTime;
    [zhuge zg_updatePageData];
    [zhuge zg_visualizationConnectTestDesigner:websocketUrl];
}
+ (NSDictionary *)zg_getParamsWithUrlString:(NSString*)urlString {
    if(urlString.length==0) {
        ZGLogError(@"链接为空！");
        return @{};
    }
    //先截取问号
    NSArray* allElements = [urlString componentsSeparatedByString:@"?"];
    NSMutableDictionary* params = [NSMutableDictionary dictionary];//待set的参数字典
    
    if(allElements.count == 2) {
        //有参数或者?后面为空
        NSString* paramsString = allElements[1];
        //获取参数对
        NSArray*paramsArray = [paramsString componentsSeparatedByString:@"&"];
        if(paramsArray.count>=2) {
            for(NSInteger i =0; i < paramsArray.count; i++) {
                NSString* singleParamString = paramsArray[i];
                NSArray* singleParamSet = [singleParamString componentsSeparatedByString:@"="];
                if(singleParamSet.count==2) {
                    NSString* key = singleParamSet[0];
                    NSString* value = singleParamSet[1];
                    if(key.length>0|| value.length>0) {
                        [params setObject: value.length>0? value:@"" forKey:key.length>0?key:@""];
                    }
                }
            }
        }else if(paramsArray.count == 1) {//无 &。url只有?后一个参数
            NSString* singleParamString = paramsArray[0];
            
            NSArray* singleParamSet = [singleParamString componentsSeparatedByString:@"="];
            if(singleParamSet.count==2) {
                NSString* key = singleParamSet[0];
                NSString* value = singleParamSet[1];
                if(key.length>0 || value.length>0) {
                    [params setObject:value.length>0?value:@""forKey:key.length>0?key:@""];
                }
            }else{
                //问号后面啥也没有 xxxx?  无需处理
            }
        }
        ZGLogDebug(@"parseUtl get %@",params);
        //整合url及参数
        return params;
    }else if(allElements.count>2) {
        ZGLogError(@"链接不合法！链接包含多个\"?\"");
        return @{};
    }else{
        ZGLogError(@"链接不包含参数！");
        return @{};
    }
}

- (void)zg_visualizationConnectTestDesigner:(NSString *)websocketUrl {
    if ([ZGVisualizationManager shareCustomerManger].enableDebugVisualization == NO) { return; }

    NSString *designerURLString = websocketUrl;
    NSURL *designerURL = [NSURL URLWithString:designerURLString];
    
    ZGLogDebug(@"Websocket url == %@", designerURLString);
    __weak Zhuge *weakSelf = self;
    void (^didOpenCallback)(void) = ^{
        __strong Zhuge *strongSelf = weakSelf;
        [Zhuge sharedUIApplication].idleTimerDisabled = YES;
        //链接上就设置
        [ZGVisualizationManager shareCustomerManger].websocketConnent = YES;
        if (strongSelf) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                [[ZGVisualizationManager shareCustomerManger] zg_startDebuggingTrack];
            });
        }
    };
    void (^messageCallback)(id message) = ^(id message){
        __strong Zhuge *strongSelf = weakSelf;
        if([message isKindOfClass:[NSString class]]){
            NSDictionary * msgDict = [ZGVisualizationManager getDictWithPageData:message];
            NSNumber *type = msgDict[@"type"];
            NSDictionary *dataDict = msgDict[@"data"];
            if(type.intValue == 5){
                NSString *event = dataDict[@"event"];
                if([event isEqualToString:@"update"]){
                    [strongSelf requestVisualizationPageTrackDatas];
                }else if([event isEqualToString:@"fetchPageData"]){
                    //更新当前的页面
                    [ZGVisualizationManager.shareCustomerManger updatePageData];
                }
            }
        }
    };
    void (^disconnectCallback)(void) = ^{
        __strong Zhuge *strongSelf = weakSelf;
        if (strongSelf) {
            [ZGVisualizationManager shareCustomerManger].websocketConnent = NO;
            [Zhuge sharedUIApplication].idleTimerDisabled = NO;
//            [[ZGVisualizationManager shareCustomerManger]zg_stopDebuggingTrack];
        }
    };
    self.abtestDesignerConnection = [[ZGABTestDesignerConnection alloc] initWithURL:designerURL keepTrying:YES connectCallback:nil didOpenCallback:didOpenCallback messageCallback:messageCallback disconnectCallback:disconnectCallback];
}

-(void)zg_updatePageData{
    __weak Zhuge *weakSelf = self;
    [[ZGVisualizationManager shareCustomerManger] setPageUpdateBlock:^(NSDictionary * _Nonnull jsonDict) {
        ZGABTestDesignerConnection *connection = weakSelf.abtestDesignerConnection;
        ZGVisualizationSocketMessage *message = [[ZGVisualizationSocketMessage alloc]initWithType:@"5" otherData:@{@"event": @"pageData"} andPayload:jsonDict];
        [connection sendLoginMessage:message];
    }];
    
    
    [[ZGVisualizationManager shareCustomerManger] setPageCheckBlock:^(NSDictionary * _Nonnull jsonDict) {
        ZGABTestDesignerConnection *connection = weakSelf.abtestDesignerConnection;
        ZGVisualizationSocketMessage *message = [[ZGVisualizationSocketMessage alloc]initWithType:@"5" otherData:@{@"event": @"trigger"} andPayload:jsonDict];
        [connection sendLoginMessage:message];
    }];
    
    
    
}

/// 请求可视化埋点可视化事件列表数据
-(void)requestVisualizationPageTrackDatas{
    
    if(!self.config.appKey){
        return;
    }
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"appKey": self.config.appKey,
        @"endpointType": @5
    }];
    __weak typeof(self) weakSelf = self;

    NSString *allUrl = [NSString stringWithFormat:@"%@/zg/web/v2/tracking/view/app/event/all", self.config.visualEventUrl];
    //@"https://rt2.zhugeio.com/zg/web/v2/tracking/view/app/event/all";

    // 构建 URLRequest
    NSURL *url = [NSURL URLWithString:allUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                    cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    request.HTTPMethod = @"POST";

    // 设置请求体为 JSON
    NSError *jsonError = nil;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&jsonError];
    if (jsonError) {
        ZGLogDebug(@"zg 构建请求体失败: %@", jsonError);
        return;
    }
    request.HTTPBody = bodyData;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    // 使用 ZGRequestManager 发起异步请求
    [[[ZGRequestManager sharedURLSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable responseData, NSURLResponse * _Nullable urlResponse, NSError * _Nullable error) {

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)urlResponse;
        if (httpResponse.statusCode == 200 && responseData) {
            NSString *result = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            NSDictionary *resultDict = [ZGVisualizationManager getDictWithPageData:result];
            ZGLogDebug(@"可视化数据请求结果--%@",result);
            if (resultDict) {
                NSString *code = resultDict[@"code"];
                NSArray *dataArr = resultDict[@"data"];

                if ([code isEqualToString:@"109000"] && [dataArr isKindOfClass:[NSArray class]]) {
                    NSArray *visualizationDatas = dataArr;
                    [weakSelf archiveVisualization:visualizationDatas];
                    [ZGVisualizationManager.shareCustomerManger.compareDic setObject:visualizationDatas forKey:weakSelf.config.appKey];
                }
            }

        } else {
            ZGLogDebug(@"zg获取可视化数据失败--%@", error);
        }

    }] resume];
}

@end
