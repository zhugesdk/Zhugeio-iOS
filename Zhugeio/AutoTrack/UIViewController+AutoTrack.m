//
//  UIViewController+AutoTrack.m
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/6/11.
//

#import "UIViewController+AutoTrack.h"
#import <objc/runtime.h>
#import "ZhugeHeaders.h"
#import "ZGLog.h"


static double _diff = 0;
static CFAbsoluteTime _start;
static CFAbsoluteTime _end;

static NSData *_imageData;
NSString * const gc_VCKey = nil;

@implementation UIViewController (AutoTrack)

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

// 页面展示
- (void)za_autotrack_viewDidAppear:(BOOL)animated {
    
    // $AutoTrack
    if ([Zhuge sharedInstance].config.autoTrackEnable && ![self isBlackListViewController:self]) {
        Zhuge * zhuge = [Zhuge sharedInstance];
    //    zhuge.url = NSStringFromClass(self.class);
    //    [_controllers addObject:NSStringFromClass(self.class)];
    //    if (_controllers.count > 1) {
    //        zhuge.ref = _controllers[_controllers.count - 2];
    //    }
        [self checkAutoTrackPageView];
        if ([zhuge.config isSeeEnable] && [[ZGSharedDur shareInstance] permitCreateImage] && [self isKindOfClass:[UIViewController class]] && ![self isKindOfClass:[UITabBarController class]] && ![self isKindOfClass:[UINavigationController class]]){
            //页面变化的时候初始化date
            [ZGSharedDur shareInstance].durDate = [NSDate date];
            _imageData = [[ZGSharedDur shareInstance] pixData];
            [[ZGSharedDur shareInstance] zhugeSetCurrentVC:NSStringFromClass(self.class)];
            [self taskData:[[ZGSharedDur shareInstance] getViewToPath:self.view]];
        }
    }
    
    // $DurationOnPage
    if ([Zhuge sharedInstance].config.isEnableDurationOnPage && ![self isBlackListViewController:self]) {
        @try {
//            UIViewController *viewController = (UIViewController *)self;
            if (![self isKindOfClass:[UIViewController class]] ||
                [self isKindOfClass:[UITabBarController class]] ||
                ![self isKindOfClass:[UINavigationController class]] ||
                [self isKindOfClass:[UIPageViewController class]] ||
                [self isKindOfClass:[UISplitViewController class]]) {
                
                [self starTrackPage:NSStringFromClass([self class])];
            }
            
        } @catch (NSException *exception) {
            // ignore
        }
    }
    
    // $ZAExposure
    if ([Zhuge sharedInstance].config.isEnableExpTrack) {
        if (![self isKindOfClass:[UIViewController class]] ||
            [self isKindOfClass:[UITabBarController class]] ||
            ![self isKindOfClass:[UINavigationController class]] ||
            [self isKindOfClass:[UIPageViewController class]] ||
            [self isKindOfClass:[UISplitViewController class]]) {

            if (self.view.subviews.count > 0) {
                [self checkoutSubviews:self.view];
            }
        }
    }
    
    //调用的是原来的实现，所以不会导致死循环
    [self za_autotrack_viewDidAppear:animated];
}


// 页面消失
- (void)za_autotrack_viewDidDisappear:(BOOL)animated {
    
    if ([Zhuge sharedInstance].config.isEnableDurationOnPage && ![self isBlackListViewController:self]) {
        if (![self isKindOfClass:[UIViewController class]] ||
            [self isKindOfClass:[UITabBarController class]] ||
            ![self isKindOfClass:[UINavigationController class]] ||
            [self isKindOfClass:[UIPageViewController class]] ||
            [self isKindOfClass:[UISplitViewController class]]) {

            [self endTrackPage:NSStringFromClass([self class])];
        }
    }
     
    [self za_autotrack_viewDidDisappear:animated];
}

- (void)starTrackPage:(NSString *)pageName {
    @try {
        if (!pageName) {
            ZGLogDebug(@"startTrack event name must not be nil.");
            return;
        }
        
        NSNumber *ts = @([[NSDate date] timeIntervalSince1970]);
        _start = CFAbsoluteTimeGetCurrent();
        ZGLogDebug(@"startTrack %@ at time : %@",pageName,ts);
        
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"start track properties exception %@",exception);
    }
}

- (void)endTrackPage:(NSString *)pageName {
    @try {
        _end = CFAbsoluteTimeGetCurrent();
        _diff = _end - _start;
//        _diff = _end - _start > 0 ? _end - _start : 1;

        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        properties[@"$dr"] = [NSNumber numberWithDouble:_diff * 1000];
//        properties[@"$dr"] = [NSString stringWithFormat:@"%.0f",_diff];
        properties[@"$page_url"] = pageName;
        properties[@"$eid"] = @"dr";
        properties[@"$page_title"] = [self zhugeScreenTitle];
        [[Zhuge sharedInstance] trackDurationOnPage:properties];
        
    }
    @catch (NSException *exception) {
        ZGLogDebug(@"end track properties exception %@",exception);
    }
}

- (void)checkAutoTrackPageView{
    if ([[Zhuge sharedInstance].config autoTrackEnable]) {
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
            ZGLogDebug([NSString stringWithFormat:@"controller :%@, error:%@",[self zhugeScreenName],[ex reason] ]);
        }
    }
    
}

-(void)autoTrackPageView{
    Zhuge * zhuge = [Zhuge sharedInstance];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:@"pv" forKey:@"$eid"];
    [data setObject:[self zhugeScreenName] forKey:@"$page_url"];
    [data setObject:[self zhugeScreenTitle] forKey:@"$page_title"];
    
    if (self.zhugeioAttributesPageName) {
        [data setObject:self.zhugeioAttributesPageName forKey:@"$page_title"];
    }
    
    if (self.zhugeioAttributesVariable) {
        __block NSMutableDictionary *copy = [NSMutableDictionary dictionaryWithCapacity:[self.zhugeioAttributesVariable count]];
        for (NSString *key in self.zhugeioAttributesVariable) {
            id value = self.zhugeioAttributesVariable[key];
            NSString *newKey = [NSString stringWithFormat:@"_%@",key];
            [copy setValue:value forKey:newKey];
        }
        
        [data addEntriesFromDictionary:copy];
    }
    
    [zhuge autoTrack:data];
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

// 系统生成的 ViewController 黑名单
- (BOOL)isBlackListViewController:(UIViewController *)viewController {
    
    NSArray *blackListViewControllers = @[@"UIApplicationRotationFollowingController",
                                          @"SFBrowserRemoteViewController",
                                          @"UIInputWindowController",
                                          @"UIKeyboardCandidateGridCollectionViewController",
                                          @"UICompatibilityInputViewController",
                                          @"UIApplicationRotationFollowingControllerNoTouches",
                                          @"UIActivityGroupViewController",
                                          @"UIKeyboardCandidateRowViewController",
                                          @"UIKeyboardHiddenViewController",
                                          @"_UIAlertControllerTextFieldViewController",
                                          @"_UILongDefinitionViewController",
                                          @"_UIResilientRemoteViewContainerViewController",
                                          @"_UIShareExtensionRemoteViewController",
                                          @"_UIRemoteDictionaryViewController",
                                          @"UISystemKeyboardDockController",
                                          @"_UINoDefinitionViewController",
                                          @"_UIActivityGroupListViewController",
                                          @"_UIRemoteViewController",
                                          @"_UIFallbackPresentationViewController",
                                          @"_UIDocumentPickerRemoteViewController",
                                          @"_UIAlertShimPresentingViewController",
                                          @"_UIWaitingForRemoteViewContainerViewController",
                                          @"_UIActivityUserDefaultsViewController",
                                          @"_UIActivityViewControllerContentController",
                                          @"_UIRemoteInputViewController",
                                          @"_UIUserDefaultsActivityNavigationController",
                                          @"_SFAppPasswordSavingViewController",
                                          @"UISnapshotModalViewController",
                                          @"WKActionSheet",
                                          @"DDSafariViewController",
                                          @"SFAirDropActivityViewController",
                                          @"CKSMSComposeController",
                                          @"DDParsecLoadingViewController",
                                          @"PLUIPrivacyViewController",
                                          @"PLUICameraViewController",
                                          @"SLRemoteComposeViewController",
                                          @"CAMViewfinderViewController",
                                          @"DDParsecNoDataViewController",
                                          @"CAMPreviewViewController",
                                          @"DDParsecCollectionViewController",
                                          @"DDParsecRemoteCollectionViewController",
                                          @"AVFullScreenPlaybackControlsViewController",
                                          @"PLPhotoTileViewController",
                                          @"AVFullScreenViewController",
                                          @"CAMImagePickerCameraViewController",
                                          @"CKSMSComposeRemoteViewController",
                                          @"PUPhotoPickerHostViewController",
                                          @"PUUIAlbumListViewController",
                                          @"PUUIPhotosAlbumViewController",
                                          @"SFAppAutoFillPasswordViewController",
                                          @"PUUIMomentsGridViewController",
                                          @"SFPasswordRemoteViewController",
                                          @"UIWebRotatingAlertController",
                                          @"UIEditUserWordController",
                                          @"_UIContextMenuActionsOnlyViewController",
                                          @"UISystemInputAssistantViewController",
                                          @"UICandidateViewController",
                                          @"UINavigationController"];
    return [blackListViewControllers containsObject:NSStringFromClass(viewController.class)];
}

- (BOOL)isBlackListViewController:(UIViewController *)viewController ofType:(ZhugeioAnalyticsAutoTrackEventType)type {
    static dispatch_once_t onceToken;
    static NSDictionary *allClasses = nil;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"ZhugeioAnalyticsSDK" ofType:@"bundle"]];
        //文件路径
        NSString *jsonPath = [bundle pathForResource:@"za_autotrack_viewcontroller_blacklist.json" ofType:nil];
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        @try {
            allClasses = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
        } @catch(NSException *exception) {  // json加载和解析可能失败
            ZGLogError(@"%@ error: %@", self, exception);
        }

    });

    NSDictionary *dictonary = (type == ZhugeioAnalyticsEventTypeAppViewScreen) ? allClasses[ZA_EVENT_NAME_APP_VIEW_SCREEN] : allClasses[ZA_EVENT_NAME_APP_CLICK];
    for (NSString *publicClass in dictonary[@"public"]) {
        if ([viewController isKindOfClass:NSClassFromString(publicClass)]) {
            return YES;
        }
    }
    return [(NSArray *)dictonary[@"private"] containsObject:NSStringFromClass(viewController.class)];
}

//UITableView *tableView = (UITableView *)scrollView;
//NSArray *cells = [tableView visibleCells];
//if (cells.count > 0) {
//    [self checkoutScrollViewCells:cells];
//}

- (void)checkoutSubviews:(UIView *)view {
    
    if ([view isKindOfClass:[UITableView class]] ||
        [view isKindOfClass:[UICollectionView class]]) {
        return;
    }
    
    [view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull view, NSUInteger index, BOOL * _Nonnull stop) {

        if (view.zhugeioAttributesValue && !view.zhugeioAttributesDonotTrackExp) {
            [self trackExpEvent:view.zhugeioAttributesValue properties:view.zhugeioAttributesVariable];
        }

        if (view.subviews.count > 0) {
            [self checkoutSubviews:view];
        }

    }];
}


- (void)trackExpEvent:(NSString *)eid properties:(NSDictionary *)pro {
    [[Zhuge sharedInstance] track:eid properties:pro];
}



@end



@implementation UIViewController (ZAAttibutes)

- (void)setZhugeioAttributesInfo:(NSString *)zhugeioAttributesInfo {
    objc_setAssociatedObject(self, @"zhugeioAttributesInfo", zhugeioAttributesInfo, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)zhugeioAttributesInfo {
    return objc_getAssociatedObject(self, @"zhugeioAttributesInfo");
}

- (void)setZhugeioAttributesPageName:(NSString *)zhugeioAttributesPageName {
    objc_setAssociatedObject(self, @"zhugeioAttributesPageName", zhugeioAttributesPageName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)zhugeioAttributesPageName {
    return objc_getAssociatedObject(self, @"zhugeioAttributesPageName");
}


- (void)setZhugeioAttributesVariable:(NSDictionary *)zhugeioAttributesVariable {
    objc_setAssociatedObject(self, @"zhugeioAttributesVariable", zhugeioAttributesVariable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary *)zhugeioAttributesVariable {
    return objc_getAssociatedObject(self, @"zhugeioAttributesVariable");
}




@end
