//
//  ZAClassHelper.m
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/4/13.
//

#import "ZAClassHelper.h"
#import <objc/runtime.h>

@implementation ZAClassHelper

+ (Class _Nullable)allocateClassWithObject:(id)object className:(NSString *)className {
    if (!object || className.length <= 0) {
        return nil;
    }
    Class originalClass = object_getClass(object);
    Class subclass = NSClassFromString(className);
    if (subclass) {
        return nil;
    }
    subclass = objc_allocateClassPair(originalClass, className.UTF8String, 0);
    if (class_getInstanceSize(originalClass) != class_getInstanceSize(subclass)) {
        return nil;
    }
    return subclass;
}

+ (void)registerClass:(Class)cla {
    if (cla) {
        objc_registerClassPair(cla);
    }
}

+ (BOOL)setObject:(id)object toClass:(Class)cla {
    if (cla && object) {
        return object_setClass(object, cla);
    }
    return NO;
}

+ (void)disposeClass:(Class)cla {
    if (cla) {
        objc_disposeClassPair(cla);
    }
}

+ (Class _Nullable)realClassWithObject:(id)object {
    return object_getClass(object);
}

+ (Class _Nullable)realSuperClassWithClass:(Class _Nullable)cla {
    return class_getSuperclass(cla);
}

@end
