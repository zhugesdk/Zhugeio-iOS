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
#import <AdServices/AdServices.h>
//#import "GMSm4Utils.h"
//#import "GMSm2Utils.h"
//#import "GMSm2Bio.h"
//#import "GMUtils.h"

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
- (ZhugeConfig *)config {
    return _config;
}

- (void)startWithConfig:(ZhugeConfig *)config andDid:(NSString *)did launchOptions:(NSDictionary *)launchOptions{
    if (!deviceId || deviceId.length == 0) {
        deviceId = did;
    }
    [self initWithConfig:config launchOptions:launchOptions withDelegate:nil];
}

- (void)startWithConfig:(ZhugeConfig *)config {
    [self initWithConfig:config launchOptions:nil withDelegate:nil];
}

- (void)startWithConfig:(ZhugeConfig *)config launchOptions:(NSDictionary *)launchOptions {
    [self initWithConfig:config launchOptions:launchOptions withDelegate:nil];
}

// 需要DeepShare时，调用此 star 方法
- (void)startWithConfig:(ZhugeConfig *)config launchOptions:(NSDictionary *)launchOptions delegate:(id)delegate {
    [self initWithConfig:config launchOptions:launchOptions withDelegate:delegate];
}

- (void)startWithConfig:(ZhugeConfig *)config andDid:(NSString *)did launchOptions:(NSDictionary *)launchOptions withDelegate:(id)delegate {
    if (!deviceId || deviceId.length == 0) {
        deviceId = did;
    }
    [self initWithConfig:config launchOptions:launchOptions withDelegate:delegate];
}

- (void)initWithConfig:(ZhugeConfig *)config launchOptions:(NSDictionary *)launchOptions withDelegate:(id)delegate{
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
        self.flushBool = NO;
        self.userId = @"";
        self.sessionId = nil;
        self.net = @"";
        self.radio = @"";
        self.telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
        self.taskId = UIBackgroundTaskInvalid;
        NSString *label = [NSString stringWithFormat:@"io.zhuge.%@.%p", config.appKey, self];
        self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        self.eventsQueue = [[NSMutableArray alloc] init];
        self.archiveEventQueue = [[NSMutableArray alloc] init];
//        self.ignoredViewTypeList = [[NSMutableArray alloc] init];
        self.variants = [NSSet set];
        self.eventBindings = [NSSet set];
        self.cr = [self carrier];
        

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
        [self unarchive];
        if (launchOptions && launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
            [self trackPush:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] type:@"launch"];
        }
        
        if (!deviceId) {
            deviceId = [ZADeviceId getZADeviceId];
        }
        if (self.config.exceptionTrack) {
            previousHandler = NSGetUncaughtExceptionHandler();
            NSSetUncaughtExceptionHandler(&ZhugeUncaughtExceptionHandler);
        }
        
//        if (self.config.enableCodeless) {
//#if TARGET_IPHONE_SIMULATOR
//            [self connectToWebSocket];
//#else
//            self.shakeGesture = [[ShakeGesture alloc] init];
//            self.shakeGesture.delegate = self;
//            [self.shakeGesture startShakeGesture];
//#endif
//        }
        
        if(self.config.enableVisualization){
            [visualInstance addObject:self];
            [self enableAutoTrack];
            static dispatch_once_t once;
            dispatch_once(&once, ^ {
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
        if (!self.sessionId) {
            [self sessionStart];
        }
        
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

//    ZGLogInfo(@"上传崩溃事件：%@",eventData);
    
    if (self.config.enableEncrypt && self.config.encryptType == 1) {
        ZGLogDebug(@"启用了AES+RSA加密方式");
        ///对数据进行AES加密
        NSString *key = [RSA_AES randomly16BitString];
        
        NSString *en = [RSA_AES AES256Encrypt:eventData key:key];

        ///对key进行RSA加密
        NSString *rsaKeyIV = [RSA_AES encryptUseRSA:[NSString stringWithFormat:@"%@,%@", key,key] pubkey:self.config.uploadPubkey];

//        ZGLogDebug(@"加密前数据: %@ \n 加密前key: %@ \n加密后key: %@ \n加密后数据: %@", eventData, [NSString stringWithFormat:@"%@,%@",key,iv], rsaKeyIV, en);

        
        NSString *requestData = [NSString stringWithFormat:@"method=event_statis_srv.upload&compress=1&encrypt=1&type=1&key=%@&event=%@", rsaKeyIV,en];
        BOOL success = [self request:@"/APIPOOL/" WithData:requestData andError:nil];
        
        success ? ZGLogDebug(@"上传崩溃事件成功") : ZGLogDebug(@"上传崩溃事件失败");
        
    }else if (self.config.enableEncrypt && self.config.encryptType == 2) {
        //        国密算法对应关系：AES --> SM4，RSA --> SM2
                ZGLogDebug(@"启用了SM4+SM2加密方式");
        // 生成 SM4 密钥。返回值：长度为 32 字节 Hex 编码格式字符串密钥
//        NSString * key = [GMSm4Utils createSm4Key];    //类似:F51397DEC6ABD9EE0295F473F880B8A3
//        // SM4 加密数据
//        NSString *en = [GMSm4Utils ecbDefaultEncryptText:eventData key:key];
//        // SM2 公钥获取ASN1格式的
//        NSString * pub = self.config.uploadSM2Pubkey;
//        if([pub containsString:@"-----BEGIN PUBLIC KEY-----"]){
//            pub = [GMSm2Bio readPublicKeyFromPemString:self.config.uploadSM2Pubkey];
//        }
//        // 对key进行SM2非对称加密
//        NSString *sm2KeyIV = [ZGGMSm2Utils encryptText:[NSString stringWithFormat:@"%@,%@",key, key] publicKey:pub];
//        // asn1解码上传
//        sm2KeyIV = [ZGGMSm2Utils asn1DecodeToC1C3C2:sm2KeyIV];
        
        /*
            处理pem格式密钥
            NSString * pri = @"-----BEGIN PRIVATE KEY-----\nMIGTAgEAMBMGByqGSM49AgEGCCqBHM9VAYItBHkwdwIBAQQgzZEKbKY0/AOXrNdVhL9Hge2FO9DnXfOHCjx2LqRKqO+gCgYIKoEcz1UBgi2hRANCAASEJNjsoXh31/P1edLNlBrmGiy99ImcgMtkiGjlWSNT1czMjVQxI5X0gvzcm2iunFzgFRmse2s6cKdUM9sxm3BF\n-----END PRIVATE KEY-----";//  @"A0F8FE45F006F3CE258DC93E27351768DDA8D33C073CD7D7CC82F8A2ED7F20D9";
           将pem私钥进行ASN.1解码,得到ASN.1私钥字符串
            pri = [GMSm2Bio readPrivateKeyFromPemString:pri];
         */
        /*
            验证解密
            NSString * pri = @"00a3562aa22fee343b31ce90c0abc36cd7373bd231fbe754d0aeb02c471d48e7f2";
            sm2KeyIV = [ZGGMSm2Utils asn1EncodeWithC1C3C2:sm2KeyIV];
            NSString * deSm2KeyIV = [ZGGMSm2Utils decryptToText:sm2KeyIV privateKey:pri];
            NSString * deKey1 = [deSm2KeyIV componentsSeparatedByString:@","].firstObject;
            NSString * deEventData = [GMSm4Utils ecbDefaultDecryptText:en key:deKey1];
         */
    
//        NSString *requestData = [NSString stringWithFormat:@"method=event_statis_srv.upload&compress=1&encrypt=1&type=2&key=%@&event=%@", sm2KeyIV,en];
//        BOOL success = [self request:@"/APIPOOL/" WithData:requestData andError:nil];
//        
//        success ? ZGLogDebug(@"上传崩溃事件成功") : ZGLogDebug(@"上传崩溃事件失败");
        
    } else {
        NSData *eventDataBefore = [eventData dataUsingEncoding:NSUTF8StringEncoding];
        NSData *zlibedData = [eventDataBefore zgZlibDeflate];
        NSString *event = [zlibedData zgBase64EncodedString];
        NSString *result = [[event stringByReplacingOccurrencesOfString:@"\r" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        NSString *requestData = [NSString stringWithFormat:@"method=event_statis_srv.upload&compress=1&encrypt=0&event=%@", result];

        BOOL success = [self request:@"/APIPOOL/" WithData:requestData andError:nil];
        
        success ? ZGLogDebug(@"上传崩溃事件成功") : ZGLogDebug(@"上传崩溃事件失败");
    }
    
    
    if (previousHandler) {
        previousHandler(exception);
    }
}
// 出现崩溃时的回调函数
void ZhugeUncaughtExceptionHandler(NSException * exception){
    NSArray *array = [instanceDic allValues];
    for (Zhuge *sdk in array) {
        [sdk trackException:exception];
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

//- (void)setUploadURL:(NSString *)url andBackupUrl:(NSString *)backupUrl{
//    if (url && url.length>0) {
//        self.apiURL = [ZGUtils parseUrl: url];
//        self.backupURL = backupUrl;
//    }else{
//        ZGLogError(@"传入的url不合法，请检查:%@",url);
//    }
//}


- (void)setSuperProperty:(NSDictionary *)info{
    dispatch_async(self.serialQueue, ^{
        if (!self.envInfo) {
            self.envInfo = [[NSMutableDictionary alloc] init];
        }
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:info];
        self.envInfo[@"event"] = dic;
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
    });
}

-(void)deleteSuperPropertyWithKey:(NSString *)key{
    if (!self.envInfo) {
        self.envInfo = [[NSMutableDictionary alloc] init];
        return;
    }
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *event = [self mutableEventDictionaryCreatingIfNeeded:NO];
        [event removeObjectForKey:key];
        self.envInfo[@"event"] = event;
    });
}
-(void)addSuperProperty:(NSDictionary *)info{
    if (!self.envInfo) {
        self.envInfo = [[NSMutableDictionary alloc] init];
        return;
    }
    if (![info isKindOfClass:[NSDictionary class]]) return;
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *event = [self mutableEventDictionaryCreatingIfNeeded:YES];
        [event addEntriesFromDictionary:info];
        self.envInfo[@"event"] = event;
    });
}

-(void)addSuperPropertyWithKey:(NSString *)key value:(NSString *)value{
    if (!value) {
        [self deleteSuperPropertyWithKey:key];
        return;
    }
    dispatch_async(self.serialQueue, ^{
       if (!value) {
           NSMutableDictionary *event = [self mutableEventDictionaryCreatingIfNeeded:NO];
           [event removeObjectForKey:key];
           self.envInfo[@"event"] = event;
       } else {
           NSMutableDictionary *event = [self mutableEventDictionaryCreatingIfNeeded:YES];
           [event setObject:value forKey:key];
           self.envInfo[@"event"] = event;
       }
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
    static dispatch_once_t once;
    dispatch_once(&once, ^ {
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
    //不管是打开全埋点还是打开了可视化埋点.均要开启全埋点
    [self.config setAutoTrackEnable:YES];
}

- (void)enableExpTrack {
    if (![exposeInstance containsObject:self]) {
        [exposeInstance addObject:self];
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (!viewDidAppearIsHook) {
            
            [UIViewController za_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(za_autotrack_viewDidAppear:) error:NULL];

            viewDidAppearIsHook = YES;
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

/**
 * 配置加密的rsa公钥
 */
- (void)setUploadRsaPubKey:(nonnull NSString*)pubKey {
    if (pubKey && pubKey.length>0) {
        self.config.uploadPubkey = pubKey;
    }else{
        ZGLogError(@"传入的公钥不合法，请检查:%@",pubKey);
    }
}

/**
 * 配置加密的sm2公钥
    
 */
- (void)setUploadSM2PubKey:(nonnull NSString*)pubSM2Key{
    if (pubSM2Key && pubSM2Key.length>0) {
        self.config.uploadSM2Pubkey = pubSM2Key;
    }else{
        ZGLogError(@"传入的SM2公钥不合法，请检查:%@",pubSM2Key);
    }
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
        [self checkAdService];
        [self uploadDeviceInfo];
        [self startFlushTimer];
//        if (self.config.enableCodeless) {
//            [self checkForDecideResponseWithCompletion:^( NSSet *eventBindings) {
//                
//                dispatch_sync(dispatch_get_main_queue(), ^(){
//                    for (ZGEventBinding *binding in eventBindings) {
//                        [binding execute];
//                    }
//                });
//                
//            } useCathe:NO];
//        }
        
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"applicationDidBecomeActive exception %@",exception);
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    @try {
        self.isForeground = NO;
        [self sessionEnd];
        [self stopFlushTimer];
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
        if (self.sessionId) {
            [self sessionEnd];
        }
        [self forceFlush];
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
        NSError *error;
        NSString *token = [AAAttribution attributionTokenWithError:&error];
        if (token != nil) {
            dispatch_async(self.serialQueue, ^{
                [self checkUseADServiceWithToken:token];
            });
        } else {
            if(error){
                ZGLogWarning(@"request ad token error , %d",error);
            }
        }
    }
}

-(void)checkUseADServiceWithToken:(NSString *)token{
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
            return;
        }
        NSError *resError;
        NSMutableDictionary *resDic = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&resError];
        BOOL value = [[resDic valueForKey:@"attribution"] boolValue];
        if(value){
            [self buildADData:resDic];
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
                if(idfaCollect){
                    NSString *idfaString = [ZGIDFAUtil idfa];
                    if(!idfaString){
                        idfaString = @"";
                    }
                    pr[@"$idfa"] = idfaString;
                }
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

/// 可视化埋点上报
/// - Parameter properties: 上报数据
- (void)zgVisualizationTrack:(nonnull NSDictionary *)properties{
    if (![properties objectForKey:@"eventName"]) {
        ZGLogDebug(@"visualization track with illegal content %@",properties);
        return;
    }
    [self track:properties[@"eventName"] properties:properties];
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
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            NSNumber *dru = [NSNumber numberWithUnsignedLongLong:(end.doubleValue - start.doubleValue)*1000];
            dic[@"$dru"] = dru;
            dic[@"_$duration$_"] = dru;
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
            if ([properties isKindOfClass: [NSDictionary class]]) {
                NSDictionary *copy = [self addSymbloToDic:properties];
                [dic addEntriesFromDictionary:copy];
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
    @try {
        if (event == nil || [event length] == 0) {
            ZGLogDebug(@"事件名不能为空");
            return;
        }
        
        if (!self.sessionId) {
            [self sessionStart];
        }
        NSMutableDictionary *pr = [self eventData];
        if (self.envInfo) {
            NSDictionary *info = [self.envInfo objectForKey:@"event"];
            if (info) {
                NSMutableDictionary *dic = [self addSymbloToDic:info];
                [pr addEntriesFromDictionary:dic];
            }
        }
        if (properties) {
            [pr addEntriesFromDictionary:[self conversionRevenuePropertiesKey:properties]];
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
        if (self.envInfo) {
            NSDictionary *info = [self.envInfo objectForKey:@"event"];
            if (info) {
                NSMutableDictionary *dic = [self addSymbloToDic:info];
                [pr addEntriesFromDictionary:dic];
            }
        }
        if (properties) {
            [pr addEntriesFromDictionary:[self addSymbloToDic:properties]];
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
    [self enqueueEvent:e];
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
    if (self.eventsQueue.count < self.config.limitCount) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
        [self flushQueue: self->_eventsQueue];
    });
}
- (void)forceFlush {
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
            
            NSUInteger sendBatchSize = ([queue count] > 25) ? 25 : [queue count];
            if (self.sendCount + sendBatchSize >= self.config.sendMaxSizePerDay) {
                sendBatchSize = self.config.sendMaxSizePerDay - self.sendCount;
            }
            
            NSArray *events = [queue subarrayWithRange:NSMakeRange(0, sendBatchSize)];
            ZGLogDebug(@"开始上报事件(本次上报事件数:%lu, 队列内事件总数:%lu, 今天已经发送:%lu, 限额:%lu)", (unsigned long)[events count], (unsigned long)[queue count], (unsigned long)self.sendCount, (unsigned long)self.config.sendMaxSizePerDay);
            
            NSString *eventData = [self encodeAPIData:[self wrapEvents:events]];
//            ZGLogDebug(@"上传事件：%@",eventData);
            
            if (self.config.enableEncrypt && self.config.encryptType == 1) {
                ZGLogDebug(@"启用了AES+RSA加密方式");
                ///对数据进行AES加密
                NSString *key = [RSA_AES randomly16BitString];
                

                NSString *en = [RSA_AES AES256Encrypt:eventData key:key];
                
                ///对key进行RSA加密
                NSString *rsaKeyIV = [RSA_AES encryptUseRSA:[NSString stringWithFormat:@"%@,%@",key, key] pubkey:self.config.uploadPubkey];

                ZGLogDebug(@"加密前数据: %@ \n 加密前key: %@ \n加密后key: %@ \n加密后数据: %@", eventData, key, rsaKeyIV, en);
                

                NSString *requestData = [NSString stringWithFormat:@"method=event_statis_srv.upload&compress=1&encrypt=1&type=1&key=%@&event=%@", rsaKeyIV,en];
                ZGLogDebug(@"上传数据==%@", requestData);
                BOOL success = [self request:@"/APIPOOL/" WithData:requestData andError:nil];
                if (success) {
                    ZGLogDebug(@"上传事件成功");
                    self.sendCount += sendBatchSize;
                    [queue removeObjectsInArray:events];
                } else {
                    ZGLogDebug(@"上传事件失败");
                    break;
                }
                                
            }else if (self.config.enableEncrypt && self.config.encryptType == 2){
                //        国密算法对应关系：AES --> SM4，RSA --> SM2
                ZGLogDebug(@"启用国密 , 但是sdk未支持。请更换国密版本sdk");
                // 生成 SM4 密钥。返回值：长度为 32 字节 Hex 编码格式字符串密钥
//                NSString * key = [GMSm4Utils createSm4Key];    //类似:F51397DEC6ABD9EE0295F473F880B8A3
//                // SM4 加密数据
//                NSString *en = [GMSm4Utils ecbDefaultEncryptText:eventData key:key];
//                // SM2 公钥获取ASN1格式的
//                NSString * pub = self.config.uploadSM2Pubkey;
//                if([pub containsString:@"-----BEGIN PUBLIC KEY-----"]){
//                    pub = [GMSm2Bio readPublicKeyFromPemString:self.config.uploadSM2Pubkey];
//                }
//                // 对key进行SM2非对称加密
//                NSString *sm2KeyIV = [GMSm2Utils encryptText:[NSString stringWithFormat:@"%@,%@",key, key] publicKey:pub];
//                // asn1解码上传
//                sm2KeyIV = [GMSm2Utils asn1DecodeToC1C3C2:sm2KeyIV];                
                /*
                    处理pem格式密钥
                    NSString * pri = @"-----BEGIN PRIVATE KEY-----\nMIGTAgEAMBMGByqGSM49AgEGCCqBHM9VAYItBHkwdwIBAQQgzZEKbKY0/AOXrNdVhL9Hge2FO9DnXfOHCjx2LqRKqO+gCgYIKoEcz1UBgi2hRANCAASEJNjsoXh31/P1edLNlBrmGiy99ImcgMtkiGjlWSNT1czMjVQxI5X0gvzcm2iunFzgFRmse2s6cKdUM9sxm3BF\n-----END PRIVATE KEY-----";//  @"A0F8FE45F006F3CE258DC93E27351768DDA8D33C073CD7D7CC82F8A2ED7F20D9";
                   将pem私钥进行ASN.1解码,得到ASN.1私钥字符串
                    pri = [GMSm2Bio readPrivateKeyFromPemString:pri];
                 */
                /*
                    验证解密
                    NSString * pri = @"00a3562aa22fee343b31ce90c0abc36cd7373bd231fbe754d0aeb02c471d48e7f2";
                    sm2KeyIV = [ZGGMSm2Utils asn1EncodeWithC1C3C2:sm2KeyIV];
                    NSString * deSm2KeyIV = [ZGGMSm2Utils decryptToText:sm2KeyIV privateKey:pri];
                    NSString * deKey1 = [deSm2KeyIV componentsSeparatedByString:@","].firstObject;
                    NSString * deEventData = [GMSm4Utils ecbDefaultDecryptText:en key:deKey1];
                 */
            
//                NSString *requestData = [NSString stringWithFormat:@"method=event_statis_srv.upload&compress=1&encrypt=1&type=2&key=%@&event=%@", sm2KeyIV,en];
//                ZGLogDebug(@"上传数据==%@", requestData);
//                BOOL success = [self request:@"/APIPOOL/" WithData:requestData andError:nil];
//                if (success) {
//                    ZGLogDebug(@"上传事件成功");
//                    self.sendCount += sendBatchSize;
//                    [queue removeObjectsInArray:events];
//                } else {
//                    ZGLogDebug(@"上传事件失败");
//                    break;
//                }
                        
            }else {
                NSData *eventDataBefore = [eventData dataUsingEncoding:NSUTF8StringEncoding];
                NSData *zlibedData = [eventDataBefore zgZlibDeflate];
                NSString *event = [zlibedData zgBase64EncodedString];
                NSString *result = [[event stringByReplacingOccurrencesOfString:@"\r" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                NSString *requestData = [NSString stringWithFormat:@"method=event_statis_srv.upload&compress=1&encrypt=0&event=%@", result];
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
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"flushQueue exception %@",exception);
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
        [self archiveEvents];
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
    [p setValue:deviceId forKey:@"deviceId"];
    [p setValue:self.sessionId forKey:@"sessionId"];
    if(self.lastUploadAdInfoAppVersion){
        [p setValue:self.lastUploadAdInfoAppVersion forKey:@"lastUploadAdAppVersion"];
    }
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
        if (!deviceId) {
            deviceId = properties[@"deviceId"] ? properties[@"deviceId"] : [ZADeviceId getZADeviceId];
        }
        self.lastUploadAdInfoAppVersion = properties[@"lastUploadAdAppVersion"] ? properties[@"lastUploadAdAppVersion"]:@"";

        self.sessionId = [properties[@"sessionId"] integerValue] > 0? properties[@"sessionId"] : nil;
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

- (void)checkForDecideResponseWithCompletion:(void (^)(NSSet *eventBinding))completion useCathe:(BOOL)useCache{
    dispatch_async(self.serialQueue, ^{
        
        if (!useCache) {
            NSString *codelessUrl = self.config.visualEventUrl;
            NSString* urlString = [NSString stringWithFormat:@"%@/v1/events/codeless/appkey/%@/platform/2?app_version=%@&updateTimeId=%@",codelessUrl,self.config.appKey,self.config.appVersion,@"0"];
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

+ (void)addScriptMessageHandlerWithWebView:(WKWebView *)webView {
    NSAssert([webView isKindOfClass:[WKWebView class]], @"此注入方案只支持 WKWebView！❌");
    if (![webView isKindOfClass:[WKWebView class]]) {
        return;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @try {
            //获取当前 WebView 的 WKUserContentController
            WKUserContentController *contentController = webView.configuration.userContentController;

            //给 WKUserContentController 设置一个js脚本控制器
            [contentController removeScriptMessageHandlerForName:ZA_SCRIPT_MESSAGE_HANDLER_NAME];
            if (@available(iOS 14.0, *)) {
                [contentController addScriptMessageHandlerWithReply:[[ZhugeJS alloc]init] contentWorld: [WKContentWorld pageWorld] name:ZA_SCRIPT_MESSAGE_HANDLER_NAME];
            } else {
                [contentController addScriptMessageHandler:[[ZhugeJS alloc]init] name:ZA_SCRIPT_MESSAGE_HANDLER_NAME];
            }
        
        } @catch (NSException *exception) {
            ZGLogError(@"%@ error: %@", self, exception);
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
        NSLog(@"可视化ws未找到appKey，请联系zhuge！");
        return;
    }
    Zhuge *zhuge = instanceDic[appKey];
    if (!zhuge) {
        NSLog(@"%@对应主体未初始化，请先初始化zhuge",appKey);
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
        NSLog(@"链接为空！");
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
        //整合url及参数
        return params;
    }else if(allElements.count>2) {
        NSLog(@"链接不合法！链接包含多个\"?\"");
        return @{};
    }else{
        NSLog(@"链接不包含参数！");
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
    
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"appKey": self.config.appKey,
        @"endpointType": @5
    }];
    __weak typeof(self) weakSelf = self;
    NSString * allUrl = [NSString stringWithFormat:@"%@/zg/web/v2/tracking/view/app/event/all",self.config.visualEventUrl];
    //@"https://rt2.zhugeio.com/zg/web/v2/tracking/view/app/event/all";
    [ZGHttpHelper post:allUrl RequestParams:dic FinishBlock:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
         if (httpResponse.statusCode == 200) {
             NSString *result =[[ NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             NSDictionary * resultDict = [ZGVisualizationManager getDictWithPageData:result];
             NSString * code = resultDict[@"code"];
             NSArray * dataArr = resultDict[@"data"];
             if([code isEqualToString:@"109000"] && [dataArr isKindOfClass:[NSArray class]]){
                  ZGLogDebug(@"zg获取可视化数据成功--%@",dataArr);
                  NSArray * visualizationDatas = dataArr;
                  [weakSelf archiveVisualization:visualizationDatas];
                  [ZGVisualizationManager.shareCustomerManger.compareDic setObject:visualizationDatas forKey:self.config.appKey];
             }
         } else {
             ZGLogDebug(@"zg获取可视化数据失败--%@",connectionError);
         }
     }];
}

@end
