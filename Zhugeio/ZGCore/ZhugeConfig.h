//
//  ZhugeConfig.h
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>

/* SDK版本 */
#define ZG_SDK_VERSION @"3.4.23"

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
// 两次会话时间间隔(默认:30秒)
@property (nonatomic, assign) NSUInteger sessionInterval;

#pragma mark - 发送策略
// 上报时间间隔(默认:10秒)
@property  NSUInteger sendInterval;
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
 * 追踪级别
 * 默认 0 关闭
 * setTrackerLevel: 1 只追踪用户行为事件
 * setTrackerLevel: 2 追踪设备信息 + 用户行为事件
 * 预留配置，暂时没用
 */
//@property (nonatomic,assign) NSInteger trackerLevel;


/**
 * 用户是否开启ZGSee
 * 默认 NO
 */
@property (nonatomic,assign) BOOL zgSeeEnable;

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
@property (nonatomic, assign) BOOL isEnableRNAutoTrack;

/**
 * 可视化埋点开关
 * 默认 NO
 */
@property (nonatomic, assign) BOOL enableCodeless;

/**
 * 开启 WebView Track
 * 默认NO
 */
@property (nonatomic, assign) BOOL enableJavaScriptBridge;

/**
 * log 日志 开关  （ 请在debug 模式下 使用 ！！！！）
 */
@property (nonatomic, assign) BOOL enableLoger;


//服务端策略
@property (nonatomic, assign) NSInteger serverPolicy;

// 是否推送到生产环境，默认YES(推送时指定deviceToken上传到开发环境或生产环境)
@property (nonatomic, assign) BOOL apsProduction;

-(BOOL)isSeeEnable;
@end
