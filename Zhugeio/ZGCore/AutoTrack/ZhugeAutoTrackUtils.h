//
//  ZhugeAutoTrackUtils.h
//  HelloZhuge
//
//  Created by Zhugeio on 2019/7/20.
//  Copyright © 2019 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZAAutoTrackProperty.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZhugeAutoTrackUtils : NSObject

+(NSString *)zhugeGetViewContent:(UIView *)view;

+(NSString *)zhugeGetViewPath:(UIView *)view;

+(void)zhugeAutoTrackClick:(UIView *)view withController:(nullable UIViewController *)controller andTag:(NSString*) tag;
/**
 * 根据view找到view所在的直接viewController
 */
+(UIViewController *)zhugeGetViewControllerByView:(UIView *)view;
/**
 如果传入的view是uiTableViewCell或者 UICollectionViewCell，则返回该cell在superView中的一维索引。即不区分section的index。
 如果不是这两种，则返回NSNotFound
 */
+(NSInteger)globalIndexForIfCellView:(UIView *)view;
@end


#pragma mark - Index
@interface ZhugeAutoTrackUtils (IndexPath)

+ (nullable NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIScrollView<ZAAutoTrackViewProperty> *)object didSelectedAtIndexPath:(NSIndexPath *)indexPath;

@end


NS_ASSUME_NONNULL_END
