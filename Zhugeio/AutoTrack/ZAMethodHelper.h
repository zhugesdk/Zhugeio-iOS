//
//  ZAMethodHelper.h
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/4/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZAMethodHelper : NSObject

/**
 获取一个类里实例方法的实现

 @param selector 方法名
 @param aClass 方法所在的类
 @return 方法的实现
 */
+ (IMP)implementationOfMethodSelector:(SEL)selector fromClass:(Class)aClass;

/**
 添加实例方法
 将 fromClass 中的 methodSelector 方法复制一个相同的方法到 toClass 中
 在这个方法调用之后，[toClass methodSelector] 和 [fromClass methodSelector] 两个方法运行时是一样的
 如果 toClass 中已经有了 methodSelector 方法，那这个方法将不做任何操作

 @param methodSelector 需要在 toClass 中添加的方法名
 @param fromClass 原始方法所在的类
 @param toClass 需要添加的方法的类
 */
+ (void)addInstanceMethodWithSelector:(SEL)methodSelector fromClass:(Class)fromClass toClass:(Class)toClass;

/**
 添加实例方法
 将 fromClass 中的 sourceSelector 方法复制到 toClass 的 destinationSelector 方法中
 在这个方法调用之后，[toClass destinationSelector] 和 [fromClass sourceSelector] 两个方法运行时是一样的
 如果 toClass 中已经有了 destinationSelector 方法，那这个方法将不做任何操作

 @param destinationSelector 需要在 toClass 中添加的方法名
 @param sourceSelector 原来的 fromClass 中的方法名
 @param fromClass 原始方法所在的类
 @param toClass 需要添加的方法的类
 */
+ (void)addInstanceMethodWithDestinationSelector:(SEL)destinationSelector sourceSelector:(SEL)sourceSelector fromClass:(Class)fromClass toClass:(Class)toClass;

/**
 添加类方法
 将 fromClass 中的 sourceSelector 类方法复制到 toClass 的 destinationSelector 类方法中
 在这个方法调用之后，[toClass destinationSelector] 和 [fromClass sourceSelector] 两个方法运行时是一样的
 如果 toClass 中已经有了 destinationSelector 方法，那这个方法将不做任何操作

 @param destinationSelector 需要在 toClass 中添加的类方法名
 @param sourceSelector 原来的 fromClass 中的类方法名
 @param fromClass 原始方法所在的类
 @param toClass 需要添加的方法的类
 */
+ (void)addClassMethodWithDestinationSelector:(SEL)destinationSelector sourceSelector:(SEL)sourceSelector fromClass:(Class)fromClass toClass:(Class)toClass;

/// 替换实例方法
/// 将 toClass 的 destinationSelector 替换为 fromClass 中的 sourceSelector
///
/// @param destinationSelector 需要在 toClass 中替换的类方法名
/// @param sourceSelector 原来的 fromClass 中的方法名
/// @param fromClass 原始方法所在的类
/// @param toClass 需要替换的方法的类
+ (IMP _Nullable)replaceInstanceMethodWithDestinationSelector:(SEL)destinationSelector sourceSelector:(SEL)sourceSelector fromClass:(Class)fromClass toClass:(Class)toClass;

@end

NS_ASSUME_NONNULL_END
