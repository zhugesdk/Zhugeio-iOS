//
//  ZAClassHelper.h
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/4/13.
//


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZAClassHelper : NSObject

/// 动态创建 Class, 类名为 className, 父类为 delegate 的当前类
/// @param object 实例对象
/// @param className 类名
+ (Class _Nullable)allocateClassWithObject:(id)object className:(NSString *)className;

/// 动态创建类后, 注册类
/// @param cla 待注册的类
+ (void)registerClass:(Class)cla;

/// 把实例对象的类变更为另外的类
/// @param object 实例对象
/// @param cla 要变更的目标类
+ (BOOL)setObject:(id)object toClass:(Class)cla;

/// 释放类
/// @param cla 待释放的类
+ (void)disposeClass:(Class)cla;

/// 获取实例对象的 isa
/// 当类重写了 - (Class)class 方法后, 通过 object.class 方式可能获取不准确
/// @param object 实例对象
+ (Class _Nullable)realClassWithObject:(id)object;

/// 获取 Class 的父类
/// @param cla 类
+ (Class _Nullable)realSuperClassWithClass:(Class _Nullable)cla;

@end

NS_ASSUME_NONNULL_END
