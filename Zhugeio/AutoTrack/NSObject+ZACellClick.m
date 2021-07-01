//
//  NSObject+ZACellClick.m
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/4/13.
//

#import "NSObject+ZACellClick.h"
#import <objc/runtime.h>

@interface ZADelegateProxyParasite : NSObject

@property (nonatomic, copy) void(^deallocBlock)(void);

@end

@implementation ZADelegateProxyParasite

- (void)dealloc {
    !self.deallocBlock ?: self.deallocBlock();
}

@end


static void *const kZADelegateProxyParasiteName = (void *)&kZADelegateProxyParasiteName;
static void *const kZADelegateProxyClassName = (void *)&kZADelegateProxyClassName;

@interface NSObject (SACellClick)

@property (nonatomic, strong) ZADelegateProxyParasite *zhugeio_parasite;

@end

@implementation NSObject (ZACellClick)

- (ZADelegateProxyParasite *)zhugeio_parasite {
    return objc_getAssociatedObject(self, kZADelegateProxyParasiteName);
}

- (void)setZhugeio_parasite:(ZADelegateProxyParasite *)zhugeio_parasite {
    objc_setAssociatedObject(self, kZADelegateProxyParasiteName, zhugeio_parasite, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)zhugeio_className {
    return objc_getAssociatedObject(self, kZADelegateProxyClassName);
}

- (void)setZhugeio_className:(NSString *)zhugeio_className {
    objc_setAssociatedObject(self, kZADelegateProxyClassName, zhugeio_className, OBJC_ASSOCIATION_COPY);
}

- (void)zhugeio_registerDeallocBlock:(void (^)(void))deallocBlock {
    if (!self.zhugeio_parasite) {
        self.zhugeio_parasite = [[ZADelegateProxyParasite alloc] init];
        self.zhugeio_parasite.deallocBlock = deallocBlock;
    }
}

@end
