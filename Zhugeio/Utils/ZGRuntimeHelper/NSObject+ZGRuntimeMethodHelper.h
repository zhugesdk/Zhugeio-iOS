//
//  NSObject+ZGRuntimeMethodHelper.h
//  HelloZhuge
//
//  Created by Good_Morning_ on 2020/1/3.
//  Copyright © 2020 37degree. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ZGRuntimeMethodHelper)

- (BOOL)class_addMethod:(Class)class selector:(SEL)selector imp:(IMP)imp types:(const char *)types;

- (void)sel_exchangeFirstSel:(SEL)sel1 secondSel:(SEL)sel2;

- (void)sel_exchangeClass:(Class)class FirstSel:(SEL)sel1 secondSel:(SEL)sel2;

- (IMP)method_getImplementation:(Method)method;

- (Method)class_getInstanceMethod:(Class)class selector:(SEL)selector;

- (BOOL)isContainSel:(SEL)sel inClass:(Class)class;

- (void)log_class_copyMethodList:(Class)class;

@end

NS_ASSUME_NONNULL_END
