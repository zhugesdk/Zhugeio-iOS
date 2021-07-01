//
//  NSObject+Zhuge.m
//  HelloZhuge
//
//  Created by Zhugeio on 2018/9/5.
//  Copyright © 2018年 37degree. All rights reserved.
//
#import "NSObject+Zhuge.h"
#import <objc/runtime.h>
//#import <objc/message.h>
#import "Zhuge.h"
#import "ZGSharedDur.h"

static NSData *_imageData;

static NSMutableDictionary *_dataDic;

@implementation NSObject (Zhuge)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
//        scrollViewWillBeginDragging
//        SEL beginDraggingvOrigila_SEL = @selector(scrollViewWillBeginDragging:);
//
//        SEL beginDraggingHook_SEL = @selector(gc_scrollViewWillBeginDragging:);
//
//        Method beginDeceleratingOrigilal_Method = class_getInstanceMethod(self, beginDraggingvOrigila_SEL);
//
//        Method beginDeceleratingHook_Method = class_getInstanceMethod(self, beginDraggingHook_SEL);
//
//        class_addMethod(self,
//                        beginDraggingvOrigila_SEL,
//                        class_getMethodImplementation(self, beginDraggingvOrigila_SEL),
//                        method_getTypeEncoding(beginDeceleratingOrigilal_Method));
//
//        class_addMethod(self,
//                        beginDraggingHook_SEL,
//                        class_getMethodImplementation(self, beginDraggingHook_SEL),
//                        method_getTypeEncoding(beginDeceleratingHook_Method));
//
//        method_exchangeImplementations(class_getInstanceMethod(self, beginDraggingvOrigila_SEL), class_getInstanceMethod(self, beginDraggingHook_SEL));
        
        
        
        SEL didEndDeceleratingOrigilaSEL = @selector(scrollViewDidEndDecelerating:);
        
        SEL didEndDeceleratingHook_SEL = @selector(gc_scrollViewDidEndDecelerating:);
        
//        交换方法
        Method origilalMethod = class_getInstanceMethod(self, didEndDeceleratingOrigilaSEL);
        
        
        Method hook_method = class_getInstanceMethod(self, didEndDeceleratingHook_SEL);
        
        
        class_addMethod(self,
                        didEndDeceleratingOrigilaSEL,
                        class_getMethodImplementation(self, didEndDeceleratingOrigilaSEL),
                        method_getTypeEncoding(origilalMethod));
        
        class_addMethod(self,
                        didEndDeceleratingHook_SEL,
                        class_getMethodImplementation(self, didEndDeceleratingHook_SEL),
                        method_getTypeEncoding(hook_method));
        
        method_exchangeImplementations(class_getInstanceMethod(self, didEndDeceleratingOrigilaSEL), class_getInstanceMethod(self, didEndDeceleratingHook_SEL));
        
        //scrollViewDidEndDragging
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
        
        
        
        // didScroll
        SEL didScrollOrigila_SEL = @selector(scrollViewDidScroll:);
        
        SEL didScrollHook_SEL = @selector(za_scrollViewDidScroll:);
        
        Method beginDeceleratingOrigilal_Method = class_getInstanceMethod(self, didScrollOrigila_SEL);
        
        Method beginDeceleratingHook_Method = class_getInstanceMethod(self, didScrollHook_SEL);
        
        class_addMethod(self,
                        didScrollOrigila_SEL,
                        class_getMethodImplementation(self, didScrollOrigila_SEL),
                        method_getTypeEncoding(beginDeceleratingOrigilal_Method));
        
        class_addMethod(self,
                        didScrollHook_SEL,
                        class_getMethodImplementation(self, didScrollHook_SEL),
                        method_getTypeEncoding(beginDeceleratingHook_Method));
        
        method_exchangeImplementations(class_getInstanceMethod(self, didScrollOrigila_SEL), class_getInstanceMethod(self, didScrollHook_SEL));
        
//        [self za_swizzleMethod:@selector(scrollViewDidScroll:) withMethod:@selector(za_scrollViewDidScroll:) error:NULL];
        
    });
    
}

- (void)za_scrollViewDidScroll:(UIScrollView *)scrollView {
//    UITableView *tableView = (UITableView *)scrollView;
//    NSArray *cells = [tableView visibleCells];
//    NSLog(@"cells cells == %@",cells);
}

- (void)gc_scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//    Zhuge * zhuge = [Zhuge sharedInstance];
//    if ([zhuge.config isSeeEnable]) {
//        _imageData = [[ZGSharedDur shareInstance] pixData];
//        [self taskData:[[ZGSharedDur shareInstance] getViewToPath:scrollView] eid:@"zgsee-scroll" viewController:[[ZGSharedDur shareInstance]viewControllerToView:scrollView]];
//    }
}

- (void)gc_scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

    if ([[Zhuge sharedInstance].config isSeeEnable] &&
        [Zhuge sharedInstance].config.zgSeeEnable == YES) {
        _imageData = [[ZGSharedDur shareInstance] pixData];
        //滑动结束
        [self taskData:[[ZGSharedDur shareInstance] getViewToPath:scrollView] eid:@"zgsee-scroll" viewController:[[ZGSharedDur shareInstance]viewControllerToView:scrollView]];
    }
    
    
    if ([Zhuge sharedInstance].config.isEnableExpTrack) {
        
        if ([scrollView isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)scrollView;
            NSArray *cells = [tableView visibleCells];
            if (cells.count > 0) {
                [self checkoutScrollViewCells:cells];
            }
        }
        
        if ([scrollView isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = (UICollectionView *)scrollView;
            NSArray *cells = [collectionView visibleCells];
            if (cells.count > 0) {
                [self checkoutScrollViewCells:cells];
            }
        }
    }
}

- (void)gc_scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    Zhuge * zhuge = [Zhuge sharedInstance];
    if ([zhuge.config isSeeEnable] &&
        decelerate == NO &&
        [Zhuge sharedInstance].config.zgSeeEnable == YES) {
        _imageData = [[ZGSharedDur shareInstance] pixData];
        //拖动结束
        [self taskData:[[ZGSharedDur shareInstance] getViewToPath:scrollView] eid:@"zgsee-scroll" viewController:[[ZGSharedDur shareInstance]viewControllerToView:scrollView]];
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
    [[Zhuge sharedInstance] setZhuGeSeeEvent:_dataDic];

}


- (void)checkoutScrollViewCells:(NSArray *)views {
    
    [views enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull view, NSUInteger index, BOOL * _Nonnull stop) {
       
        if (view.zhugeioAttributesValue && !view.zhugeioAttributesDonotTrackExp) {
            [self trackExpEvent:view.zhugeioAttributesValue properties:view.zhugeioAttributesVariable];
        }
//        
//        if (view.subviews.count > 0) {
//            [self checkoutScrollViewCells:view.subviews];
//        }
        
    }];
}

- (void)trackExpEvent:(NSString *)eid properties:(NSDictionary *)pro {
    [[Zhuge sharedInstance] track:eid properties:pro];
}

@end
