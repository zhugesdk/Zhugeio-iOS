//
//  ZGIDFAUtil.h
//  ZhugeioAnanlytics
//
//  Created by jiaokang on 2022/10/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGIDFAUtil : NSObject
/**
 获取设备的 IDFA
 @return idfa
 */
+ (nullable NSString *)idfa;
@end

NS_ASSUME_NONNULL_END
