//
//  ZhugeAutoTrackUtils.h
//  HelloZhuge
//
//  Created by jiaokang on 2019/7/20.
//  Copyright © 2019 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>
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
@end

NS_ASSUME_NONNULL_END
