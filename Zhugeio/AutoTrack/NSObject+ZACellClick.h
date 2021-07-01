//
//  NSObject+ZACellClick.h
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/4/13.
//


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ZACellClick)

/// 用于记录创建子类时的原始父类名称
@property (nonatomic, copy, nullable) NSString *zhugeio_className;

/// 注册一个操作,在对象释放时调用; 重复调用该方法时,只有第一次调用时的 block 生效
/// @param deallocBlock 操作
- (void)zhugeio_registerDeallocBlock:(void (^)(void))deallocBlock;

@end

NS_ASSUME_NONNULL_END
