//
//  ZADelegageProxy.m
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/4/13.
//

#import "ZADelegateProxy.h"
#import "ZAClassHelper.h"
#import "ZAMethodHelper.h"
#import "ZhugeAutoTrackUtils.h"
#import "NSObject+ZACellClick.h"
#import "ZGLog.h"
#import <objc/message.h>


typedef void (*ZhugeDidSelectImplementation)(id, SEL, UIScrollView *, NSIndexPath *);

@implementation ZADelegateProxy

+ (void)proxyWithDelegate:(id)delegate {
    @try {
        [ZADelegateProxy hookDidSelectMethodWithDelegate:delegate];
    } @catch (NSException *exception) {
        return ZGLogError(@"%@", exception);
    }
}

+ (void)hookDidSelectMethodWithDelegate:(id)delegate {
    // 当前代理对象已经处理过
    if ([delegate zhugeio_className]) {
        return;
    }
    
    SEL tablViewSelector = @selector(tableView:didSelectRowAtIndexPath:);
    SEL collectionViewSelector = @selector(collectionView:didSelectItemAtIndexPath:);
    
    BOOL canResponseTableView = [delegate respondsToSelector:tablViewSelector];
    BOOL canResponseCollectionView = [delegate respondsToSelector:collectionViewSelector];
    
    // 代理对象未实现单元格选中方法, 则不处理
    if (!canResponseTableView && !canResponseCollectionView) {
        return;
    }
    Class proxyClass = [ZADelegateProxy class];
    // KVO 创建子类后会重写 - (Class)class 方法, 直接通过 object.class 无法获取真实的类
    Class realClass = [ZAClassHelper realClassWithObject:delegate];
    // 如果当前代理对象归属为 KVO 创建的类, 则无需新建子类
    if ([ZADelegateProxy isKVOClass:realClass]) {
        // 记录 KVO 的父类(KVO 会重写 class 方法, 返回父类)
        [delegate setZhugeio_className:NSStringFromClass([delegate class])];
        if ([realClass isKindOfClass:[NSObject class]]) {
            // 在移除所有的 KVO 属性监听时, 系统会重置对象的 isa 指针为原有的类; 因此需要在移除监听时, 重新为代理对象设置新的子类, 来采集点击事件
            [ZAMethodHelper addInstanceMethodWithSelector:@selector(removeObserver:forKeyPath:) fromClass:proxyClass toClass:realClass];
        }
        
        // 给 KVO 的类添加 cell 点击方法, 采集点击事件
        [ZAMethodHelper addInstanceMethodWithSelector:tablViewSelector fromClass:proxyClass toClass:realClass];
        [ZAMethodHelper addInstanceMethodWithSelector:collectionViewSelector fromClass:proxyClass toClass:realClass];
        return;
    }
    
    // 创建类
    NSString *dynamicClassName = [ZADelegateProxy generateZhugeClassName:delegate];
    Class dynamicClass = [ZAClassHelper allocateClassWithObject:delegate className:dynamicClassName];
    if (!dynamicClass) {
        return;
    }
    
    // 给新创建的类添加 cell 点击方法, 采集点击事件
    [ZAMethodHelper addInstanceMethodWithSelector:tablViewSelector fromClass:proxyClass toClass:dynamicClass];
    [ZAMethodHelper addInstanceMethodWithSelector:collectionViewSelector fromClass:proxyClass toClass:dynamicClass];

    if ([realClass isKindOfClass:[NSObject class]]) {
        // 新建子类后,需要监听是否添加了 KVO, 因为添加 KVO 属性监听后, KVO 会重写 Class 方法, 导致获取的 Class 为诸葛添加的子类
        [ZAMethodHelper addInstanceMethodWithSelector:@selector(addObserver:forKeyPath:options:context:) fromClass:proxyClass toClass:dynamicClass];
    }
    
    // 记录对象的原始类名 (因为 class 方法需要使用, 所以在重写 class 方法前设置)
    [delegate setZhugeio_className:NSStringFromClass(realClass)];
    // 重写 - (Class)class 方法，隐藏新添加的子类
    [ZAMethodHelper addInstanceMethodWithSelector:@selector(class) fromClass:proxyClass toClass:dynamicClass];
    
    // 使类生效
    [ZAClassHelper registerClass:dynamicClass];
    
    // 替换代理对象所归属的类
    if ([ZAClassHelper setObject:delegate toClass:dynamicClass]) {
        // 在对象释放时, 释放创建的子类
        [delegate zhugeio_registerDeallocBlock:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [ZAClassHelper disposeClass:dynamicClass];
            });
        }];
    }
}

@end

#pragma mark - UITableViewDelegate & UICollectionViewDelegate

@implementation ZADelegateProxy (SubclassMethod)

/// Overridden instance class method
- (Class)class {
    if (self.zhugeio_className) {
        return NSClassFromString(self.zhugeio_className);
    }
    return [super class];
}

+ (void)invokeWithTarget:(NSObject *)target selector:(SEL)selector scrollView:(UIScrollView *)scrollView indexPath:(NSIndexPath *)indexPath {
    Class originalClass = NSClassFromString(target.zhugeio_className) ?: target.superclass;
    struct objc_super targetSuper = {
        .receiver = target,
        .super_class = originalClass
    };
    // 消息转发给原始类
    void (*func)(struct objc_super *, SEL, id, id) = (void *)&objc_msgSendSuper;
    func(&targetSuper, selector, scrollView, indexPath);
    
    // 当 target 和 delegate 不相等时为消息转发, 此时无需重复采集事件
    if (target != scrollView.delegate) {
        return;
    }

    NSMutableDictionary *properties = [ZhugeAutoTrackUtils propertiesWithAutoTrackObject:(UIScrollView<ZAAutoTrackViewProperty> *)scrollView didSelectedAtIndexPath:indexPath];
    if (!properties) {
        return; 
    }
    
    [[Zhuge sharedInstance] autoTrack:properties];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SEL methodSelector = @selector(tableView:didSelectRowAtIndexPath:);
    [ZADelegateProxy invokeWithTarget:self selector:methodSelector scrollView:tableView indexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    SEL methodSelector = @selector(collectionView:didSelectItemAtIndexPath:);
    [ZADelegateProxy invokeWithTarget:self selector:methodSelector scrollView:collectionView indexPath:indexPath];
}

@end

#pragma mark KVO

@implementation ZADelegateProxy (KVO)

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
    if (self.zhugeio_className) {
        // 由于添加了 KVO 属性监听, KVO 会创建子类并重写 Class 方法,返回原始类; 此时的原始类为诸葛添加的子类,因此需要重写 class 方法
        [ZAMethodHelper replaceInstanceMethodWithDestinationSelector:@selector(class) sourceSelector:@selector(class) fromClass:ZADelegateProxy.class toClass:[ZAClassHelper realClassWithObject:self]];
    }
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    // remove 前代理对象是否归属于 KVO 创建的类
    BOOL oldClassIsKVO = [ZADelegateProxy isKVOClass:[ZAClassHelper realClassWithObject:self]];
    [super removeObserver:observer forKeyPath:keyPath];
    // remove 后代理对象是否归属于 KVO 创建的类
    BOOL newClassIsKVO = [ZADelegateProxy isKVOClass:[ZAClassHelper realClassWithObject:self]];
    
    // 有多个属性监听时, 在最后一个监听被移除后, 对象的 isa 发生变化, 需要重新为代理对象添加子类
    if (oldClassIsKVO && !newClassIsKVO) {
        // 清空已经记录的原始类
        self.zhugeio_className = nil;
        [ZADelegateProxy proxyWithDelegate:self];
    }
}

@end


#pragma mark

static NSString *const kZADelegateSuffix = @"__CN.ZHUGEIO";
static NSString *const kZAKVODelegatePrefix = @"KVONotifying_";
static NSString *const kZAClassSeparatedChar = @".";
static long subClassIndex = 0;

@implementation ZADelegateProxy (Utils)

/// 是不是 KVO 创建的类
/// @param cls 类
+ (BOOL)isKVOClass:(Class _Nullable)cls {
    return [NSStringFromClass(cls) containsString:kZAKVODelegatePrefix];
}

/// 是不是诸葛创建的类
/// @param cls 类
+ (BOOL)isZhugeClass:(Class _Nullable)cls {
    return [NSStringFromClass(cls) containsString:kZADelegateSuffix];
}

/// 生成诸葛要创建类的类名
/// @param obj 实例对象
+ (NSString *)generateZhugeClassName:(id)obj {
    Class class = [ZAClassHelper realClassWithObject:obj];
    if ([ZADelegateProxy isZhugeClass:class]) return NSStringFromClass(class);
    return [NSString stringWithFormat:@"%@%@%@%@", NSStringFromClass(class), kZAClassSeparatedChar, @(subClassIndex++), kZADelegateSuffix];
}

@end
