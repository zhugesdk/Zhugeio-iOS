//
//  UIView+ZGView.h
//  ZGTestDemo
//
//  Created by 范奇 on 2023/2/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (ZGView)
//同级的索引
@property (nonatomic, assign) NSInteger zgSupViewIndex;
//垂直index
@property (nonatomic, assign) NSInteger zgSupViewZIndex;

/// 当前视图对应的控制器
- (UIViewController *)parentController;

/// 判断一个视图是否可见
-(BOOL)zg_isVisible;

// 判断一个 view 是否会触发可视化埋点事件
- (BOOL)zg_isAutoTrackAppClick;

@end

@interface UITableView (ZGElementCell)
- (NSArray *)zg_subElements;
@end

@interface UICollectionView (ZGElementCell)
- (NSArray *)zg_subElements;
@end

NS_ASSUME_NONNULL_END
