//
//  UIViewController+Zhuge.m
//  HelloZhuge
//
//  Created by jiaokang on 2018/9/5.
//  Copyright © 2018年 37degree. All rights reserved.
//

#import "UIViewController+Zhuge.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "Zhuge.h"
#import "ZGSharedDur.h"
#import "ZhugeAutoTrackUtils.h"
#import "ZGLog.h"

static NSData *_imageData;
NSString * const gc_VCKey = nil;

@implementation UIViewController (Zhuge)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        SEL origilaSEL = @selector(viewDidAppear:);

        SEL hook_SEL = @selector(gc_viewDidAppear:);

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

    });
    
}
- (void)gc_viewDidAppear:(BOOL)animated{
    Zhuge * zhuge = [Zhuge sharedInstance];
    
    [self checkAutoTrackPageView];
    if ([zhuge.config isSeeEnable] && [[ZGSharedDur shareInstance] permitCreateImage] && [self isKindOfClass:[UIViewController class]] && ![self isKindOfClass:[UITabBarController class]] && ![self isKindOfClass:[UINavigationController class]]){
        //页面变化的时候初始化date
        [ZGSharedDur shareInstance].durDate = [NSDate date];
        _imageData = [[ZGSharedDur shareInstance] pixData];
        [self taskData:[[ZGSharedDur shareInstance] getViewToPath:self.view]];
        [[ZGSharedDur shareInstance] zhugeSetCurrentVC:NSStringFromClass(self.class)];
    }
    
    [self gc_viewDidAppear:animated];
    
}
//整理并上传数据
- (void)taskData:(NSString *)viewPath {
    ZGSharedDur * dur = [ZGSharedDur shareInstance];
    
    NSMutableDictionary * dic = [NSMutableDictionary dictionary];
    dic[@"$pix"] = _imageData;
    dic[@"$page"] = viewPath;
    dic[@"$pel"] = @[];
    NSString *gap = [dur getCurrentGap];
    [dur updateCommanGapData];
    dic[@"$gap"] = gap;
    dic[@"$eid"] = @"zgsee-change";
    dic[@"$rd"] = @(0);
    dic[@"$pn"] = NSStringFromClass([self class]);
    dic[@"$wh"] = @[@([UIScreen mainScreen ].bounds.size.width),@([UIScreen mainScreen ].bounds.size.height)];
    [[Zhuge sharedInstance] setZhuGeSeeEvent:dic];
}
#pragma mark autoTrack
- (void)checkAutoTrackPageView{
    if (![[Zhuge sharedInstance].config autoTrackEnable]) {
        return;
    }
    @try {
        UIViewController *viewController = (UIViewController *)self;
        if (![viewController.parentViewController isKindOfClass:[UIViewController class]] ||
            [viewController.parentViewController isKindOfClass:[UITabBarController class]] ||
            [viewController.parentViewController isKindOfClass:[UINavigationController class]] ||
            [viewController.parentViewController isKindOfClass:[UIPageViewController class]] ||
            [viewController.parentViewController isKindOfClass:[UISplitViewController class]]) {
            [viewController autoTrackPageView];
        }
    }@catch(NSException *ex){
        ZhugeDebug([NSString stringWithFormat:@"controller :%@, error:%@",[self zhugeScreenName],[ex reason] ]);
    }
}
-(void)autoTrackPageView{
    Zhuge * zhuge = [Zhuge sharedInstance];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:@"pv" forKey:@"$eid"];
    [data setObject:[self zhugeScreenName] forKey:@"$url"];
    [data setObject:[self zhugeScreenTitle] forKey:@"$page_title"];
    [zhuge autoTrack:data];
}
- (NSString *)zhugeScreenName {
    return NSStringFromClass([self class]);
}
- (NSString *)zhugeScreenTitle {
    NSString *titleViewContent = [ZhugeAutoTrackUtils zhugeGetViewContent: self.navigationItem.titleView];
    if (titleViewContent && titleViewContent.length > 0) {
        return titleViewContent;
    }
    NSString *controllerTitle = self.navigationItem.title;
    if (controllerTitle.length > 0) {
        return controllerTitle;
    }
    return @"";
}


//- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [super touchesBegan:touches withEvent:event];
//    NSLog(@"%@",@"-=-=-==-begin==-=-=-=-=-=-=");
//}

@end
