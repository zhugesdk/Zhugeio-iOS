//
//  UIViewController+AutoTrack.h
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/6/11.
//

#import <UIKit/UIKit.h>



@interface UIViewController (ZGAutoTrack)

- (NSString *)zhugeScreenName;

- (NSString *)zhugeScreenTitle;

- (void)za_autotrack_viewDidAppear:(BOOL)animated;

- (void)za_autotrack_viewDidDisappear:(BOOL)animated;

@end



@interface UIViewController (ZAAttibutes)

// 手动标识该vc的附加属性  该值可被子节点继承
@property (nonatomic, copy)NSString *zhugeioAttributesInfo;

// 手动标识该页面的标题，必须在该UIViewController显示之前设置
@property (nonatomic, copy)NSString *zhugeioAttributesPageName;

// 手动标识该ViewController的附加属性
// 在全埋点中，该属性会自动合并到该 VC 下的 pv（页面浏览）、click（点击）、dr（页面时长）事件中
// 合并规则：View 自身的 zhugeioAttributesVariable 优先级高于 ViewController（同 key 时 View 覆盖 VC）
// 自定义属性的 key 在上报时会被自动加上 '_' 前缀，例如 @{@"orderId": @"456"} 上报时 key 为 "_orderId"
@property (nonatomic, strong)NSDictionary *zhugeioAttributesVariable;

@end

