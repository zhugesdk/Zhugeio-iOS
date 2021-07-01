//
//  UIViewController+AutoTrack.h
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/6/11.
//

#import <UIKit/UIKit.h>



@interface UIViewController (AutoTrack)

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

// 手动标识该view的附加属性 该字典可被子节点继承
@property (nonatomic, strong)NSDictionary *zhugeioAttributesVariable;

@end

