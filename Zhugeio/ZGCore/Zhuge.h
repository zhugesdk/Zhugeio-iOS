//
//  Zhuge.h
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZhugeHeaders.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ZGDeepShareDelete <NSObject>

- (void)zgOnInappDataReturned:(nullable NSDictionary *)params withError:(nullable NSError *)error;

@end


@interface Zhuge : NSObject

@property (nonatomic, weak) _Nullable id <ZGDeepShareDelete> delegate;

#pragma mark - DeepShare
/** 处理Apple-registered URL schemes
 * @param url 系统回调传回的URL
 * @return bool URL是否被成功识别处理
 */
+ (BOOL)handleURL:(nullable NSURL *)url;

/**
 * 让DeepShare通过NSUserActivity进行页面转换，成功则返回true，否则返回false
 * @param userActivity userActivity存储了页面跳转的信息，包括来源与目的页面
 */
+ (BOOL)continueUserActivity:(nullable NSUserActivity *)userActivity;

#pragma mark - 获取实例

/**
 * 获取诸葛统计的实例。
 */
+ (nonnull Zhuge*)sharedInstance;

/**
 * 获得诸葛配置实例。
 */
- (nonnull ZhugeConfig *)config;

/**
 * 获得诸葛配置实例。
 */
-(void)setUtm:(nonnull NSDictionary *)utmInfo;

/**
 * 获得诸葛设备ID。
 */
- (nonnull NSString *)getDid;
- (nonnull NSString *)getSid;

#pragma mark - 开启统计
/**
 诸葛上传地址
 */
- (void)setUploadURL:(nonnull NSString*)url andBackupUrl:(nullable NSString *)backupUrl;

/**
 * 自动统计页面停留时长
 */
- (void)enabelDurationOnPage;

/**
 * 开启全埋点采集
 */
- (void)enableAutoTrack;
- (BOOL)isAutoTrackEnable;

/**
 * 开启视屏采集
 */
- (void)enableZGSee;

/**
 * 开启曝光采集 Exposure
 */
- (void)enableExpTrack;


/**
 开启诸葛统计。
 @param appKey 应用Key，网站上注册应用时自动获得
 @param launchOptions 启动项
 */
- (void)startWithAppKey:(nonnull NSString*)appKey launchOptions:(nullable NSDictionary*)launchOptions;

- (void)startWithAppKey:(nonnull NSString *)appKey andDid:(nonnull NSString*)did launchOptions:(nullable NSDictionary *)launchOptions;

// 需要DeepShare时，调用此 star 方法
- (void)startWithAppKey:(nonnull NSString*)appKey launchOptions:(nullable NSDictionary*)launchOptions delegate:(nonnull id)delegate;

- (void)startWithAppKey:(nonnull NSString *)appKey andDid:(nonnull NSString *)did launchOptions:(nullable NSDictionary *)launchOptions withDelegate:(nonnull id)delegate;


#pragma mark - 追踪用户行为
/**
 标识用户。
 @param userId     用户ID
 @param properties 用户属性
 */
- (void)identify:(nonnull NSString*)userId properties:(nullable NSDictionary *)properties;

/**
 userID不变，仅更新用户属性
 @param properties 属性
 */
- (void)updateIdentify:(nonnull NSDictionary *)properties;


/**
 * 设置事件环境信息，通过这个地方存入的信息将会给之后传入的每一个事件添加环境信息
 */
- (void)setSuperProperty:(nonnull NSDictionary *)info;

- (void)setPlatform:(nonnull NSDictionary *)info;

/**
 * 追踪自定义事件。
 * @param event      事件名称
 */
- (void)track:(nonnull NSString *)event;

/**
 * 追踪自定义事件。
 * @param event      事件名称
 * @param properties 事件属性
 */
- (void)track:(nonnull NSString *)event properties:(nullable NSDictionary *)properties;
/**
 开始追踪一个耗时事件，这个借口并不会真正的统计这个事件。当你调用endTrack时，会统计两个接口之间的耗时，
 并作为一个属性添加到事件之中
 @param eventName 事件名称
 */
- (void)startTrack:(nonnull NSString *)eventName;
- (void)endTrack:(nonnull NSString *)eventName properties:(nullable NSDictionary *)properties;


/** 追踪收入事件
 *  @param properties 事件属性
 */
- (void)trackRevenue:(nullable NSDictionary *)properties;

/**
 * @param properties 全埋点属性
 */
- (void)autoTrack:(nonnull NSDictionary *)properties;

/**
 * @param properties 页面时长需携带的属性
 */
- (void)trackDurationOnPage:(NSDictionary *)properties;

/**
 * 向 WKWebView 注入 Message Handler
 * @param webView 需要注入的 wkwebView
*/
- (void)addScriptMessageHandlerWithWebView:(WKWebView *)webView;


// 处理接收到的消息
- (void)handleRemoteNotification:(nonnull NSDictionary *)userInfo;

// 设置第三方推送用户ID
- (void)setThirdPartyPushUserId:(nonnull NSString *)userId forChannel:(ZGPushChannel) channel;

// 处理AppSee数据上传
- (void)setZhuGeSeeEvent:(nonnull NSMutableDictionary *)userInfo;


/**
 * 忽略某一类型的 View
 * @param aClass View 对应的 Class
 */
- (void)ignoreViewType:(Class)aClass;

/**
 * 判断某个 View 类型是否被忽略
 * @param aClass Class View 对应的 Class
 * @return YES:被忽略; NO:没有被忽略
 */
- (BOOL)isViewTypeIgnored:(Class)aClass;


+ (UIApplication *)sharedUIApplication;

/**
 * 私有化部署需手动设置 URL
 *  1. Websocket URL
 *  2. 远程事件 URL
 */
- (void)setupCodelessWebsocketUrl:(NSString *)url;
- (void)setupCodelessEventsUrl:(NSString *)url;

@end


NS_ASSUME_NONNULL_END
