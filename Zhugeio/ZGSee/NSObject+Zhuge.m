//
//  NSObject+Zhuge.m
//  HelloZhuge
//
//  Created by jiaokang on 2018/9/5.
//  Copyright © 2018年 37degree. All rights reserved.
//
#import "NSObject+Zhuge.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "Zhuge.h"
#import "ZGSharedDur.h"

static NSData *_imageData;

static NSMutableDictionary *_dataDic;

@implementation NSObject (Zhuge)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
//        scrollViewWillBeginDragging
        SEL beginDeceleratingOrigila_SEL = @selector(scrollViewWillBeginDragging:);
        
        SEL beginDeceleratingHook_SEL = @selector(gc_scrollViewWillBeginDragging:);
        
        Method beginDeceleratingOrigilal_Method = class_getInstanceMethod(self, beginDeceleratingOrigila_SEL);
        
        Method beginDeceleratingHook_Method = class_getInstanceMethod(self, beginDeceleratingHook_SEL);
        
        class_addMethod(self,
                        beginDeceleratingOrigila_SEL,
                        class_getMethodImplementation(self, beginDeceleratingOrigila_SEL),
                        method_getTypeEncoding(beginDeceleratingOrigilal_Method));
        
        class_addMethod(self,
                        beginDeceleratingHook_SEL,
                        class_getMethodImplementation(self, beginDeceleratingHook_SEL),
                        method_getTypeEncoding(beginDeceleratingHook_Method));
        
        method_exchangeImplementations(class_getInstanceMethod(self, beginDeceleratingOrigila_SEL), class_getInstanceMethod(self, beginDeceleratingHook_SEL));
        
        
        SEL origilaSEL = @selector(scrollViewDidEndDecelerating:);
        
        SEL hook_SEL = @selector(gc_scrollViewDidEndDecelerating:);
        
        //交换方法
        Method origilalMethod = class_getInstanceMethod(self, origilaSEL);
        
        
        Method hook_method = class_getInstanceMethod(self, hook_SEL);
        
        
        class_addMethod(self,
                        origilaSEL,
                        class_getMethodImplementation(self, origilaSEL),
                        method_getTypeEncoding(origilalMethod));
        
        class_addMethod(self,
                        hook_SEL,
                        class_getMethodImplementation(self, hook_SEL),
                        method_getTypeEncoding(hook_method));
        
        method_exchangeImplementations(class_getInstanceMethod(self, origilaSEL), class_getInstanceMethod(self, hook_SEL));
        
        
        SEL draOrigilaSEL = @selector(scrollViewDidEndDragging: willDecelerate:);
        
        SEL draHook_SEL = @selector(gc_scrollViewDidEndDragging: willDecelerate:);
        
        //交换方法
        Method draOrigilalMethod = class_getInstanceMethod(self, draOrigilaSEL);
        
        
        Method draHook_method = class_getInstanceMethod(self, draHook_SEL);
        
        
        class_addMethod(self,
                        draOrigilaSEL,
                        class_getMethodImplementation(self, draOrigilaSEL),
                        method_getTypeEncoding(draOrigilalMethod));
        
        class_addMethod(self,
                        draHook_SEL,
                        class_getMethodImplementation(self, draHook_SEL),
                        method_getTypeEncoding(draHook_method));
        
        method_exchangeImplementations(class_getInstanceMethod(self, draOrigilaSEL), class_getInstanceMethod(self, draHook_SEL));
    });
    
}

- (void)gc_scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//    Zhuge * zhuge = [Zhuge sharedInstance];
//    if ([zhuge.config isSeeEnable]) {
//        _imageData = [[ZGSharedDur shareInstance] pixData];
//        [self taskData:[[ZGSharedDur shareInstance] getViewToPath:scrollView] eid:@"zgsee-scroll" viewController:[[ZGSharedDur shareInstance]viewControllerToView:scrollView]];
//    }
}

- (void)gc_scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    Zhuge * zhuge = [Zhuge sharedInstance];
    if ([zhuge.config isSeeEnable]) {
        _imageData = [[ZGSharedDur shareInstance] pixData];
        //滑动结束
        [self taskData:[[ZGSharedDur shareInstance] getViewToPath:scrollView] eid:@"zgsee-scroll" viewController:[[ZGSharedDur shareInstance]viewControllerToView:scrollView]];
    }
}

- (void)gc_scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    Zhuge * zhuge = [Zhuge sharedInstance];
    if ([zhuge.config isSeeEnable] && decelerate == NO) {
        
        _imageData = [[ZGSharedDur shareInstance] pixData];
        //拖动结束
        [self taskData:[[ZGSharedDur shareInstance] getViewToPath:scrollView] eid:@"zgsee-scroll" viewController:[[ZGSharedDur shareInstance]viewControllerToView:scrollView]];
    }else{
        NSLog(@"gc_scrollViewDidEndDragging see is close");
    }
    
}


//整理并上传数据
- (void)taskData:(NSString *)viewPath eid:(NSString *)eid viewController:(UIViewController *)viewController {
    
    if (!_dataDic) {
        _dataDic = [[NSMutableDictionary alloc] init];
    }
    _dataDic[@"$pix"] = _imageData;
    _dataDic[@"$page"] = viewPath;
    _dataDic[@"$pel"] = @[];
    _dataDic[@"$eid"] = eid;
    [[ZGSharedDur shareInstance] getCurrentGap];
    [[ZGSharedDur shareInstance] updateCommanGapData];
    _dataDic[@"$gap"] = [[ZGSharedDur shareInstance] getCurrentGap];
    _dataDic[@"$rd"] = @(0);
    _dataDic[@"$pn"] = NSStringFromClass([viewController class]);
    _dataDic[@"$wh"] = @[@([UIScreen mainScreen ].bounds.size.width),@([UIScreen mainScreen ].bounds.size.height)];
//    NSLog(@"_dataDic == %@",_dataDic);
    [[Zhuge sharedInstance] setZhuGeSeeEvent:_dataDic];

}
@end
