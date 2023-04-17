//
//  ZGVisualizationManager.h
//  ZGTestDemo
//
//  Created by 范奇 on 2023/2/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGVisualizationManager : NSObject

/// 可视化埋点时.循环上报页面的时间,默认为2s,最小为2s.
@property (nonatomic, assign) NSInteger zg_reportTime;

/// 是否开启App视图调试参考
@property (nonatomic, assign) BOOL zg_hasTestDebug;

/// 新的可视化埋点调试开关 默认 NO, 设置为YES开启后.就会调zg_startVisualizationDebuggingTrack时链接socket上报可响应元素信息
@property (nonatomic, assign) BOOL enableDebugVisualization;

/// websocket是否已链接
@property (nonatomic, assign) BOOL websocketConnent;

/// 比对数组
@property (nonatomic, strong) NSArray * localCompareArr;

/// 页面发生变化时.页面信息回调
@property (nonatomic, copy) void(^pageUpdateBlock)(NSDictionary *jsonDict);

/// 页面发生变化时.页面信息回调
@property (nonatomic, copy) void(^pageCheckBlock)(NSDictionary *jsonDict);

/// 开始与pc端连接,可视化埋点,reportTime为循环上报时间.默认为2s
- (void)zg_startDebuggingTrack;

/// 结束与pc端连接,可视化埋点
- (void)zg_stopDebuggingTrack;

/// 传入一个view.判断该视图是否埋点.若为已埋点的控件.则直接并上报.没有则不处理
- (void)zg_identificationAndUPloadWithView:(UIView *)view;

/// 传入一个vcStr判断该视图是否是可视化页面埋点.若为已埋点的页面.则直接并上报.没有则不处理
/// - Parameters:
///   - vcStr: pageUrl.页面控制器的昵称
///   - info: 可视化页面埋点的数据
- (void)zg_pvUPloadWithVCStr:(NSString *)vcStr info:(NSMutableDictionary *)info;

/// 更新当前可视化页面信息
- (void)updatePageData;

/// 判断当前传入的视图是否是需要可视化识别的添加手势的视图
+ (BOOL)zg_customGestureViewsHasContainCurrentView:(UIView *)currentView;

/// 字典转json字符串
+ (NSString *)getPageData:(NSDictionary *)dic;

/// json字符串转字典
+ (NSDictionary *)getDictWithPageData:(NSString *)jsonString;

/// 单例方法
+ (instancetype)shareCustomerManger;

@end

NS_ASSUME_NONNULL_END
