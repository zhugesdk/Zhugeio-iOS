//
//  ZhugeConfig.h
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>

/* SDK版本 */
#define ZG_SDK_VERSION @"4.3.1"

/* 默认应用版本 */
#define ZG_APP_VERSION [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]

/*应用名称*/

#define ZG_APP_NAME [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];

/* 渠道 */
#define ZG_CHANNEL @"App Store"

@interface ZhugeConfig : NSObject

#pragma mark - 基本设置
// SDK版本
@property (nonatomic, copy) NSString *sdkVersion;
// 应用版本(默认:info.plist中CFBundleShortVersionString对应的值)
@property (nonatomic, copy) NSString *appVersion;
//应用名称（默认：info.plist中的CFBundleDisplayName）
@property (nonatomic, copy)NSString *appName;
// 渠道(默认:@"App Store")
@property (nonatomic, copy) NSString *channel;

#pragma mark - 发送策略
// 上报时间间隔(默认:10秒)
@property  NSUInteger sendInterval;

//达到该数值开始上报数据
@property NSUInteger limitCount;

// 每天最大上报事件数，超出部分缓存到本地(默认:50000个)
@property (nonatomic, assign) NSUInteger sendMaxSizePerDay;
// 本地缓存事件数(默认:3000个)
@property (nonatomic, assign) NSUInteger cacheMaxSize;

#pragma mark - 日志
// 是否开启会话追踪(默认:开启)
@property (nonatomic, assign) BOOL sessionEnable;

@property (nonatomic, assign) BOOL exceptionTrack;


/**
 * 是否开启实时调试
 * 默认 NO
 */
@property (nonatomic, assign) BOOL debug;


/**
 * 全埋点是否开启
 * 默认NO
 */
@property (nonatomic,assign) BOOL autoTrackEnable;

/**
 * 开启自动统计页面停留时长
 * 默认 NO
 */
@property (nonatomic,assign) BOOL isEnableDurationOnPage;

/**
 * 开启曝光采集 
 * 默认 NO
 */
@property (nonatomic,assign) BOOL isEnableExpTrack;

/**
 * RN 全埋点是否开启
 * 默认NO
 */
//@property (nonatomic, assign) BOOL isEnableRNAutoTrack;


/**
 * 新的可视化埋点开关 默认 NO, 设置为YES开启后,就会上报可视化埋点的埋点事件,设置为YES时也会开启全埋点
 */
@property (nonatomic, assign) BOOL enableVisualization;

/**
 * 新的可视化埋点调试上报时长 默认 2s
 */
@property (nonatomic, assign) NSInteger debugVisualizationTime;


/**
 * 开启 WebView Track 默认NO
 * 预留配置项
 */
@property (nonatomic, assign) BOOL enableJavaScriptBridge;

/**
 是否使用app的全局属性覆盖h5事件的属性。默认情况下，全局属性优先级比传入的事件属性低。但是h5交互时，用户希望使用app的
 全局属性覆盖h5事件的，可以打开这个选项
 */
@property (nonatomic, assign) BOOL overwriteH5ProWithAppSuperPro;



/**
 * 上传数据加密rsa 公钥
 */
@property (nonatomic, copy) NSString *uploadPubkey;

/**
 * 上传数据加密sm2 公钥
 */
@property (nonatomic, copy) NSString *uploadSM2Pubkey;

@property (nonatomic, copy) NSString *businessKey;
/**
 * 上传数据是否加密
 */
@property (nonatomic, assign) BOOL enableEncrypt;

    
/**
 * 上传数据加密策略：1：res加密  2: 国密sm2 sm4
 */
@property (nonatomic, assign) int encryptType;

@property (nonatomic,copy) NSString *appKey;
/// 可视化埋点的socket URL
@property (nonatomic,copy) NSString *visualWebsocketUrl;
/// 可视化埋点获取埋点数据的URL
@property (nonatomic,copy) NSString *visualEventUrl;

// 设置埋点数据上传地址
- (void)setUploadURL:(nonnull NSString*)url andBackupUrl:(nullable NSString *)backupUrl;

- (void)enableEncryptUpload:(BOOL)encrypt CryptoType:(int)cryptoType;
-(NSString*)getUploadUrl;
-(NSString*)getUploadBackupUrl;

@end
