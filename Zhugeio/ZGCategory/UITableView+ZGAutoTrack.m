//
//  UITableView+ZGAutoTrack.m
//  HelloZhuge
//
//  Created by Good_Morning_ on 2020/1/5.
//  Copyright © 2020 37degree. All rights reserved.
//

#import "UITableView+ZGAutoTrack.h"
#import "ZGRuntimeHelper.h"
#import "Zhuge.h"
#import "ZhugeAutoTrackUtils.h"
#import "NSObject+ZGAutoTrack.h"
#import "ZGLog.h"

#define GET_CLASS_CUSTOM_SEL(sel,class)  NSSelectorFromString([NSString stringWithFormat:@"%@_%@",NSStringFromClass(class),NSStringFromSelector(sel)])


@implementation UITableView (ZGAutoTrack)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
    });
}

- (void)zhugeAutoTrack_tableViewDidSelectRowIndexPathInClass:(id)object {
    SEL sel = @selector(tableView:didSelectRowAtIndexPath:);
//    NSSelectorFromString([NSString stringWithFormat:@"%@_%@",NSStringFromClass([self class]),NSStringFromSelector(sel)]);
    // 为每个含tableView的控件 增加swizzle delegate method
    [self class_addMethod:[object class]
                 selector:GET_CLASS_CUSTOM_SEL(sel,[object class])
                      imp:method_getImplementation(class_getInstanceMethod([self class],@selector(zhuge_imp_tableView:didSelectRowAtIndexPath:)))
                    types:"v@:@@"];
    
    // 检查页面是否已经实现了origin delegate method  如果没有手动加一个
    if (![self isContainSel:sel inClass:[object class] ]) {
        [self class_addMethod:[object class]
                     selector:sel
                          imp:nil
                        types:"v@:@@"];
    }
    
    // 将swizzle delegate method 和 origin delegate method 交换
    [self sel_exchangeClass:[object class]
                   FirstSel:sel
                  secondSel:GET_CLASS_CUSTOM_SEL(sel,[object class])];
}

/**
 swizzle method IMP
 */
- (void)zhuge_imp_tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([[Zhuge sharedInstance].config autoTrackEnable]) {
        ZGLog(@"%@ didSelectRowAtIndexPath:%ld:%ld",NSStringFromClass([self class]),(long)indexPath.section,(long)indexPath.row);
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        Zhuge * zhuge = [Zhuge sharedInstance];
        NSString *content = content = [ZhugeAutoTrackUtils zhugeGetViewContent:cell];;
        NSString *path = [ZhugeAutoTrackUtils zhugeGetViewPath:cell];
        NSString *type = @"UITableViewCell";
        
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        NSString *url = NSStringFromClass([self class]);
        NSString *title = @"";
        
        [data setObject:isNil(url) forKey:@"$url"];
        [data setObject:type forKey:@"$element_type"];
        [data setObject:isNil(path) forKey:@"$element_selector"];
        [data setObject:isNil(title) forKey:@"$page_title"];
        [data setObject:isNil(content) forKey:@"$element_content"];
        [data setObject:@"click" forKey:@"$eid"];
        [zhuge autoTrack:data];
        
    }
    
    SEL sel = GET_CLASS_CUSTOM_SEL(@selector(tableView:didSelectRowAtIndexPath:),[self class]);
    if ([self respondsToSelector:sel]) {
        IMP imp = [self methodForSelector:sel];
        void (*func)(id, SEL,id,id) = (void *)imp;
        func(self, sel,tableView,indexPath);
    }
}

- (void)autoTrack:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    
    
}


@end
