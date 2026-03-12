//
//  ZAAutoTrackProperty.h
//  Pods
//
//  Created by Good_Morning_ on 2021/4/15.
//

#import <Foundation/Foundation.h>

#pragma mark - ZAAutoTrackViewControllerProperty
@protocol ZAAutoTrackViewControllerProperty <NSObject>
@property (nonatomic, readonly) BOOL zhugeio_isIgnored;
@property (nonatomic, copy, readonly) NSString *zhugeio_screenName;
@property (nonatomic, copy, readonly) NSString *zhugeio_title;
@end

#pragma mark - ZAAutoTrackViewProperty

@protocol ZAAutoTrackViewProperty <NSObject>
@property (nonatomic, readonly) BOOL zhugeio_isIgnored;
/// 记录上次触发点击事件的开机时间
@property (nonatomic, assign) NSTimeInterval zhugeio_timeIntervalForLastAppClick;

@property (nonatomic, copy, readonly) NSString *zhugeio_elementType;
@property (nonatomic, copy, readonly) NSString *zhugeio_elementContent;
@property (nonatomic, copy, readonly) NSString *zhugeio_elementId;

/// 元素位置，UISegmentedControl 中返回选中的 index，
@property (nonatomic, copy, readonly) NSString *zhugeio_elementPosition;

/// 获取 view 所在的 viewController，或者当前的 viewController
//@property (nonatomic, readonly) UIViewController<ZAAutoTrackViewControllerProperty> *zhugeio_viewController;

@end


#pragma mark - CELL

@protocol ZAAutoTrackCellProperty <ZAAutoTrackViewProperty>

- (NSString *)zhugeio_elementPositionWithIndexPath:(NSIndexPath *)indexPath;

- (NSString *)zhugeio_itemPathWithIndexPath:(NSIndexPath *)indexPath;

- (NSString *)zhugeio_similarPathWithIndexPath:(NSIndexPath *)indexPath;
/// 遍历查找 cell 所在的 indexPath
@property (nonatomic, strong, readonly) NSIndexPath *zhugeio_IndexPath;

@end
