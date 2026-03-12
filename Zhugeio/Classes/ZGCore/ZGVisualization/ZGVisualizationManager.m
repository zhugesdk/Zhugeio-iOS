//
//  ZGVisualizationManager.m
//  ZGTestDemo
//
//  Created by 范奇 on 2023/2/23.
//

#import "ZGVisualizationManager.h"
#import "UIView+ZGView.h"
#import "UIImage+ZGDifference.h"
#import "NSString+ZGMD5.h"
#import <objc/runtime.h>
#import "ZGVisualizedTool.h"
#import "UIWindow+ZGView.h"
#import "NSTimer+ZGWeakTimer.h"
#import "NSObject+ZGResponseID.h"
#import "Zhuge.h"
#import "ZGLog.h"
#import "ZhugeAutoTrackUtils.h"

@interface ZGVisualizationManager()

/// pc联调时.页面可响应控件展示的优先级.默认为0
@property (nonatomic, assign) NSInteger zgZIndexLevel;
/// 联调定时器
@property (nonatomic, strong) NSTimer* zg_timer;
/// 调试时的展示view
@property (nonatomic, strong) NSMutableArray * allShowClickViews;
/// 记录当前截图的视图标识
@property (nonatomic, copy) NSString *imgIdStr;
/// 记录当前截图的image对象
@property (nonatomic, strong) UIImage * fullImage;
/// 防抖标识
@property (nonatomic, assign) BOOL zgOnceHandleTagKey;
/// 调试使用: 待标识的可响应控件
@property (nonatomic, strong) UIImageView * showCurrentView;
/// 记录是否进入了后台.默认为NO
@property (nonatomic, assign) BOOL hasEnterBackGround;
@end

@implementation ZGVisualizationManager

static ZGVisualizationManager *_manger = nil;
+ (ZGVisualizationManager *)shareCustomerManger
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manger = [[super allocWithZone:NULL] init];
        _manger.zgZIndexLevel = 0;
        _manger.zg_reportTime = 2;
        _manger.zgOnceHandleTagKey = YES;
        _manger.compareDic = [NSMutableDictionary dictionary];
        //调试
        _manger.zg_hasTestDebug = NO;
        
        //监听程序进入前台和后台
        // iOS 13+ 使用 Scene 生命周期通知
        if (@available(iOS 13.0, *)) {
            [[NSNotificationCenter defaultCenter] addObserver:_manger
                                                     selector:@selector(sceneDidEnterBackground:)
                                                         name:UISceneDidEnterBackgroundNotification
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:_manger
                                                     selector:@selector(sceneWillEnterForeground:)
                                                         name:UISceneWillEnterForegroundNotification
                                                       object:nil];
        }
        // Application 通知作为兜底
        [[NSNotificationCenter defaultCenter] addObserver:_manger
                                                 selector:@selector(enterBackGround:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:_manger
                                                     selector:@selector(enterForeGround:)
                                                         name:UIApplicationWillEnterForegroundNotification
                                                       object:nil];
    });
    return _manger;
}

-(instancetype)init
{
    if ([super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            //如果有数据初始化时，需要保证初始化也只进行一次
        });
        
    }
    
    return self;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return [ZGVisualizationManager shareCustomerManger];
}

-(instancetype)copyWithZone:(NSZone *)zone {
    
    return  [ZGVisualizationManager shareCustomerManger];
}

-(instancetype)mutableCopyWithZone:(NSZone *)zone {
    
    return  [ZGVisualizationManager shareCustomerManger];
}


#pragma mark - 开放Api

/// 开始与pc端连接,可视化埋点,reportTime为循环上报时间.默认为2s
- (void)zg_startDebuggingTrack
{
    [self startTimer];
}

/// 结束与pc端连接,可视化埋点
- (void)zg_stopDebuggingTrack
{
    [self stopTimer];
    
    for (UIView * oldItemView in self.allShowClickViews) {
        [oldItemView removeFromSuperview];
    }
    [self.allShowClickViews removeAllObjects];
    
    [self.showCurrentView removeFromSuperview];
    self.showCurrentView = nil;
}

-(void)startTimer{
    
    if([self.zg_timer isValid]){
        [self.zg_timer invalidate];
        self.zg_timer                   = nil;
    }
    
    self.zg_timer                   = [NSTimer scheduledWeakTimerWithTimeInterval:0.5 target:self selector:@selector(zg_checkTime) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.zg_timer forMode:NSRunLoopCommonModes];
}

-(void)stopTimer{
    if([self.zg_timer isValid]){
        [self.zg_timer invalidate];
    }
    self.zg_timer = nil;
}
/// 传入一个view.判断该事件的id.并上报.
-(void)zg_identificationAndUPloadWithView:(UIView *)view{
    [self zg_identificationAndUPloadWithView:view andIndex:NSNotFound];
}

-(void)zg_identificationAndUPloadWithView:(UIView *)view andIndex:(NSInteger)viewIndex{
    //不处理UIBarItem非View类型的.
    if(![view isKindOfClass:[UIView class]]){
        return;
    }
    
    if([Zhuge visualInstance].count <= 0){
        return;
    }
    
    if([view zg_isAutoTrackAppClick] == NO){
        return;
    }
    
    NSString * idStr = [self zgIdentificationWithView:view];
    NSInteger supViewIndex ;
    if (viewIndex == NSNotFound) {
        [self setCurrentViewSubViewsIndex:view];
        supViewIndex = view.zgSupViewIndex;
    } else {
        supViewIndex = viewIndex;
    }
    NSString * viewNameStr = [self getCurrentViewNameWithView:view];
    //根据已缓存的.进行遍历比对查找
    UIViewController * localVC = [view parentController];
    NSString * localVCStr = localVC ? NSStringFromClass(localVC.class) : @"keyWindow";
    NSArray *keys = [self.compareDic allKeys];
    for (NSString *key in keys) {
        Zhuge *visualSDK = [Zhuge getInstanceForKey:key];
        if (!visualSDK) {
            continue;
        }
        if (!visualSDK.config.enableVisualization) {
            continue;
        }
        NSArray *appkeyArray = [self.compareDic objectForKey:key];
        if (![appkeyArray isKindOfClass: [NSArray class]]) {
            continue;
        }
        NSArray *infoArrays = [appkeyArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"eventType == %@",@"click"]];
        if (infoArrays == nil || [infoArrays count ] == 0) {
            continue;;
        }
        [infoArrays enumerateObjectsUsingBlock:^(NSDictionary*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString * elementConditions = obj[@"elementConditions"];
            if(elementConditions){
                NSDictionary * dict = [ZGVisualizationManager getDictWithPageData:elementConditions];
                
                NSString * identification = ZGSafeStringFromDict(dict, @"id");
                NSString * viewName =  ZGSafeStringFromDict(dict, @"viewName");
                NSString * index = ZGSafeStringFromDict(dict, @"index");
                NSString *scope = ZGSafeStringFromDict(obj, @"scope");
                NSString *pagePath = ZGSafeStringFromDict(obj, @"pagePath");
                
                BOOL idEqual = [idStr isEqualToString:identification];
                BOOL nameEqual = viewName == nil || [viewName isEqualToString:viewNameStr];
                BOOL indexEqual = index == nil || index.integerValue == supViewIndex;
                BOOL pageEqual = [scope isEqualToString:@"all"] ||[pagePath isEqualToString:localVCStr];
                if (idEqual && nameEqual && indexEqual && pageEqual) {
                    *stop = YES;
                    [self zgUploadVisualizationData:obj forKey:key];
                }
            }
        }];
    }
}

/// 传入一个vcStr.判断该页面是否埋点.
- (void)zg_pvUPloadWithVCStr:(NSString *)vcStr {
    
    //不处理UIBarItem非View类型的.
    if(!vcStr){
        return;
    }
    
    //开启可视化.并且未开启全埋点.
    if([Zhuge visualInstance].count <= 0){
        return;
    }
    
    //根据已缓存的.进行遍历比对查找
    NSArray *keys = [self.compareDic allKeys];
    for (NSString *key in keys) {
        Zhuge *visualSDK = [Zhuge getInstanceForKey:key];
        if (!visualSDK) {
            continue;
        }
        if (!visualSDK.config.enableVisualization) {
            continue;
        }
        
        NSArray *appkeyArray = [self.compareDic objectForKey:key];
        if (![appkeyArray isKindOfClass: [NSArray class]]) {
            continue;
        }
        NSArray *infoArrays = [appkeyArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"eventType == %@",@"pv"]];
        [infoArrays enumerateObjectsUsingBlock:^(NSDictionary*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString * pagePath = obj[@"pagePath"];
            NSString *type = obj[@"eventType"];
            if ([vcStr isEqualToString:pagePath]) {
                [self zgPVUploadVisualizationData:obj appKey:key];
            }
        }];
    }
    
}

/// 诸葛上报可视化页面埋点数据
-(void)zgPVUploadVisualizationData:(NSDictionary *)dataDict appKey:(NSString *)key{
    ZGLogDebug(@"zhugeio 缓存数据中匹配到页面埋点数据:%@",dataDict);
    //与可视化事件埋点保持一致
    if(self.websocketConnent == NO){
        Zhuge *zhuge = [Zhuge getInstanceForKey:key];
        if (zhuge) {
            [zhuge zgVisualizationTrack:dataDict];
        }
    }
    if(self.pageCheckBlock){
        self.pageCheckBlock(dataDict);
    }
}

/// 诸葛上报可视化事件埋点数据
-(void)zgUploadVisualizationData:(NSDictionary *)dataDict forKey:(NSString *) appkey{
    ZGLogDebug(@"zhugeio 缓存数据中匹配到事件埋点数据:%@",dataDict);
    if(self.websocketConnent == NO){
        Zhuge *zhuge = [Zhuge getInstanceForKey:appkey];
        if (zhuge) {
            [zhuge zgVisualizationTrack:dataDict];
        }
    }
    if(self.pageCheckBlock){
        self.pageCheckBlock(dataDict);
    }
}

/// 根据子视图获取其唯一标识,用于比对视图id.判断是否需要上报
/// - Parameter view: 子视图
- (NSString *)zgIdentificationWithView:(UIView *)view{
    
    // NSString * classStr = @"keyWindow";
    
    // UIViewController * localVC = [view parentController];
    // if([localVC isKindOfClass:[UIViewController class]]){
    //     UIViewController * currentRootVC = [ZGVisualizationManager zg_getRootViewController];
    //     classStr = NSStringFromClass(currentRootVC.class);
    // }
    // NSString * localVCStr = localVC ? NSStringFromClass(localVC.class) : @"keyWindow";
    // NSString * responseIDStr = view.zg_responseID ? view.zg_responseID : NSStringFromClass(view.class);
    
    // NSInteger supViewIndex = 0;
    // NSString * sign = [NSString stringWithFormat:@"%@_%@_%@_%@",classStr,localVCStr,responseIDStr,[view class]];
    // //新逻辑,根据事件名即zg_reponseID,根据当前视图容器名控制器或者keyWindow,根据当前容器类型以及索引
    // NSString * identificationStr = [NSString stringWithFormat:@"%@-%@-%@",responseIDStr,classStr,sign];
    // NSString * md5Str = [identificationStr getZGSHA256Str];
    
    // return md5Str;
    return [view zgStableViewID];
}

/// 开启定时器监听变化
-(void)zg_checkTime{
    
    if(self.hasEnterBackGround){
        return;
    }
    
    UIWindow *keyWindow = [UIWindow zg_currentWindow];
    NSInteger currentScale = 1;
    UIImage * uiImage = [self screenshotWithView:keyWindow afterScreenUpdates:NO currentScale:currentScale];
    
    NSString *imgIdStr = [uiImage getCurrentImgSign];
    if([self.imgIdStr isEqualToString:imgIdStr]){
        return;
    }
    
    if(self.hasEnterBackGround){
        return;
    }
    __weak __typeof(self)weakSelf = self;
    [self zgLimitHandingOnce:self.zg_reportTime handleBlock:^{
        weakSelf.fullImage = uiImage;
        weakSelf.imgIdStr = imgIdStr;
        [weakSelf zg_uploadVisualizationData:currentScale window:keyWindow];
    }];
}

/// 更新当前可视化页面信息
- (void)updatePageData{
    
    UIWindow *keyWindow = [UIWindow zg_currentWindow];
    NSInteger currentScale = 1;
    UIImage * uiImage = [self screenshotWithView:keyWindow afterScreenUpdates:NO currentScale:currentScale];
    
    NSString *imgIdStr = [uiImage getCurrentImgSign];
    self.fullImage = uiImage;
    self.imgIdStr = imgIdStr;
    [self zg_uploadVisualizationData:currentScale window:keyWindow];
}

// 对 view 截图
- (UIImage *)screenshotWithView:(UIView *)currentView afterScreenUpdates:(BOOL)afterUpdates currentScale:(NSInteger)currentScale {
    if (!currentView || ![currentView isKindOfClass:UIView.class]) {
        return nil;
    }
    UIImage *screenshotImage = nil;
    @try {
        CGSize size = currentView.bounds.size;
        UIGraphicsBeginImageContextWithOptions(size, YES, currentScale);
        CGRect rect = currentView.bounds;
        //  drawViewHierarchyInRect:afterScreenUpdates: 截取一个UIView或者其子类中的内容，并且以位图的形式（bitmap）保存到UIImage中
        [currentView drawViewHierarchyInRect:rect afterScreenUpdates:afterUpdates];
        screenshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    } @catch (NSException *exception) {
        NSLog(@"screenshot fail，error %@: %@", self, exception);
    }
    return screenshotImage;
}

/// 上传当前同步页面的按钮数据信息
-(void)zg_uploadVisualizationData:(NSInteger)currentScale window:(UIWindow *)keyWindow{
    
    if(self.hasEnterBackGround){
        return;
    }
    
    //测试代码.去掉调试视图
    for (UIView * oldItemView in self.allShowClickViews) {
        [oldItemView removeFromSuperview];
    }
    [self.allShowClickViews removeAllObjects];
    self.zgZIndexLevel = 0;
    
    /*
     关键参数:
     screenSize: 屏幕的宽高,w:10,h:10,自身宽度:10,自身高度:10
     classIndexPath: 控制器的继承链 - 优化为控制器名称,或者keywindow
     scale: 截图与实际屏幕的尺寸比例系数
     控件信息
     location: 控件当前的位置,x:10,y:10,w:10,h:10,即距离左侧:10,距离顶部10,自身宽度:10,自身高度:10
     indexPath: 控件层次链
     resIndexPath: 控件响应链
     sign: 控件拼接标识(classStr,localVCStr,responseIDStr,[subView class])
     identification: 通过select path拼接以后sha256生成.后台可作为唯一标识.
     zgSupViewIndex: 在同级父级容器中第几个元素索引
     zgSupViewZIndex: 在视图中的纵向层级索引
     zgZIndexLevel: 会变化.该值只在与PC端调试埋点时比较优先级时可作参考.因页面滑动会随之变化,显示的优先级,为值越大越上面
     viewName: 控件的特定标识.非唯一.
     pageUrl: 视图来源
     */
    
    NSMutableDictionary * muDict = [[NSMutableDictionary alloc]init];
    [muDict setObject:[self getPageCGSizeStr:UIScreen.mainScreen.bounds.size] forKey:@"screenSize"];
    [muDict setObject:@(currentScale).stringValue forKey:@"scale"];
    
    UIViewController * currentTopVC = [ZGVisualizationManager getCurrentVC];
    /*
     与全埋点保持一致 - 晚点研究两者之前的区别.
     UIViewController *currentTopVC = [ZhugeAutoTrackUtils zhugeGetViewControllerByView:view];
     */
    
    [muDict setObject: currentTopVC ? NSStringFromClass([currentTopVC class]):@"keyWindow" forKey:@"pageUrl"];
    NSMutableArray * muArr = [NSMutableArray array];
    UIView * windowView = [keyWindow zg_subFullElement];
    
    if (windowView.zg_isVisible && [NSStringFromClass(windowView.class) isEqualToString:@"UITransitionView"]) {
        UIViewController * currentRootVC = [ZGVisualizationManager zg_getRootViewController];
        [self getCurrentViewSubViews:currentRootVC.view muArr:muArr classStr:NSStringFromClass(currentRootVC.class) zindex:0];
    }else{
        [self getCurrentViewSubViews:windowView muArr:muArr classStr:@"keyWindow" zindex:0];
    }
    
    BOOL hasFlag = NO;
    for (UIView * subView in keyWindow.subviews) {
        if(hasFlag){
            /*
             fq: 当顶层是透明的一层,且userinterface为yes.还是得用window最顶层的的视图.
             */
            [self getCurrentViewSubViews:subView muArr:muArr classStr:@"keyWindow" zindex:0];
        }
        if([subView isEqual:windowView]){
            hasFlag = YES;
        }
    }
    
    [muDict setObject:muArr forKey:@"allBtns"];
    NSString * pageDatas = [ZGVisualizationManager getPageData:muDict.copy];
    
    if (self.pageUpdateBlock){
        NSData *  pixData = UIImageJPEGRepresentation(self.fullImage, 1);
        NSString *base64Data = [pixData zgBase64EncodedString];
        NSString * pageImgMD5Str = [base64Data getZGMD5Str];
        [muDict setObject:pageImgMD5Str forKey:@"key"];
        [muDict setObject:base64Data forKey:@"bgImg"];
        if(!self.hasEnterBackGround){
            self.pageUpdateBlock(muDict.copy);
        }
    }
    
    /*
     研发调试属性
     */
    if(self.zg_hasTestDebug){
        //展示调试视图
        self.showCurrentView.image = self.fullImage;
        //展示可响应视图
        [self testShowClick:pageDatas];
    }
}


/// 获取当前视图在父视图中的第几位视图
/// - Parameter childView: 当前视图
-(void)setCurrentViewSubViewsIndex:(UIView *)childView{
    NSInteger cellIndex = [ZhugeAutoTrackUtils globalIndexForIfCellView:childView];
    if (cellIndex == NSNotFound) {
        childView.zgSupViewIndex = [childView.superview.subviews indexOfObject:childView] + 1;
    } else {
        childView.zgSupViewIndex = cellIndex + 1;
    }
}


///  递归获取所有按钮元素.并收集可响应的控件
/// - Parameters:
///   - supView: 当前视图
///   - muArr: 可视化视图数据数组
///   - classStr: 当前控制器或者keywindow
///   - zindex: 已作废.每次记录时重新通过setCurrentViewSubViewsIndex获取了
-(void)getCurrentViewSubViews:(UIView *)supView muArr:(NSMutableArray *)muArr classStr:(NSString *)classStr zindex:(NSInteger)zindex{
    supView.zgSupViewZIndex = zindex;
    if(![supView zg_isVisible] || supView.userInteractionEnabled == NO){
        return;
    }
    UIWindow *keyWindow = [UIWindow zg_currentWindow];
    if(zindex == 0){
        [self addMuItem:supView muArr:muArr zindex:zindex classStr:classStr keyWindow:keyWindow];
    }
    if(supView.subviews.count != 0){
        /*
         fq: 在埋点中:UIButton、UISwitch、UITextView、UISlider、UIStepper,这种复合控件没必要遍历的
         但是考虑到有人在其上面添加可响应子控件.所以放开UIButton和UITextView,
         这是关于性能与精确度的一次考量
         */
        if([supView isKindOfClass:[UISwitch class]] ||
           [supView isKindOfClass:[UISlider class]] ||
           [supView isKindOfClass:[UIStepper class]]){
            return;
        }
        
        NSArray * sumViews = supView.subviews;
        
        if([supView isKindOfClass:[UITableView class]]){
            UITableView * tableView = (UITableView *)supView;
            sumViews = [tableView zg_subElements];
        }
        
        if([supView isKindOfClass:[UICollectionView class]]){
            UICollectionView * collectionView = (UICollectionView *)supView;
            sumViews = [collectionView zg_subElements];
        }
        
        for (UIView * subView in sumViews) {
            
            [self addMuItem:subView muArr:muArr zindex:zindex classStr:classStr keyWindow:keyWindow];
            
            //先添加自身类的.再添加子类.这样能保证使用深度遍历顺序https://zhuanlan.zhihu.com/p/566445929
            if(subView.subviews.count > 0){
                [self getCurrentViewSubViews:subView muArr:muArr classStr:classStr zindex:(zindex + 1)];
            }
        }
    }else{
        
    }
    
}


-(BOOL)addMuItem:(UIView *)subView muArr:(NSMutableArray *)muArr zindex:(NSInteger)zindex classStr:(NSString *)classStr keyWindow:(UIWindow *)keyWindow{
    subView.zgSupViewZIndex = zindex;
    
    //有事件的控件.可以是实现了touchBegin的.也可以是addGesture的.
    if([subView isKindOfClass:[UIView class]]){
        
        if(subView.zg_isVisible == NO || subView.userInteractionEnabled == NO){
            return NO;
        }
        
        if([subView zg_isAutoTrackAppClick] == NO){
            return NO;
        }
        
        UIViewController * localVC = [subView parentController];
        NSString * localVCStr = localVC ? NSStringFromClass(localVC.class) : @"keyWindow";
        
        [self setCurrentViewSubViewsIndex:subView];
        
        NSMutableDictionary * muItemDict = [[NSMutableDictionary alloc]init];
        
        NSString * viewName = [self getCurrentViewNameWithView:subView];
        [muItemDict setObject:viewName forKey:@"viewName"];
        
        NSString * responseIDStr = subView.zg_responseID ? subView.zg_responseID : NSStringFromClass(subView.class);
        
        NSString * sign = [subView zgStableViewPath];
        [muItemDict setObject:sign forKey:@"sign"];
        
        [muItemDict setObject:@(subView.zgSupViewIndex) forKey:@"zgSupViewIndex"];
        
        CGRect tempFrame = [subView convertRect:subView.bounds toView:keyWindow];
        [muItemDict setObject:[self getPageCGRectStr:tempFrame] forKey:@"location"];
        
        //新逻辑,根据事件名即zg_reponseID,根据当前视图容器名控制器或者keyWindow,根据当前容器类型以及索引
        NSString * identificationStr = [self zgIdentificationWithView:subView];
        [muItemDict setObject:identificationStr forKey:@"identification"];
        
        [muItemDict setObject:@(self.zgZIndexLevel) forKey:@"zgZIndexLevel"];
        [muArr addObject:muItemDict];
        return YES;
    }else{
        return NO;
    }
}


#pragma mark - 调试效果

//模拟点击区域
-(void)testShowClick:(NSString *)pageDatas{
    
    NSDictionary * dict = [ZGVisualizationManager getDictWithPageData:pageDatas];
    NSArray * btns = dict[@"allBtns"];
    
    UIWindow * keyWindow = [UIWindow zg_currentWindow];
    
    for (NSDictionary * btnData in btns) {
        UILabel * view = [[UILabel alloc]init];
        view.backgroundColor = [UIColor.greenColor colorWithAlphaComponent:0.5];
        NSDictionary * dict = btnData[@"location"];
        CGFloat x = [dict[@"x"] floatValue];
        CGFloat y = [dict[@"y"] floatValue];
        CGFloat w = [dict[@"w"] floatValue];
        CGFloat h = [dict[@"h"] floatValue];
        CGRect rect = CGRectMake(x, y, w, h);
        view.frame = rect;
        view.text = [NSString stringWithFormat:@"%@-%@",btnData[@"zgZIndexLevel"],btnData[@"zgSupViewIndex"]];
        [self.allShowClickViews addObject:view];
        [keyWindow addSubview:view];
    }
}

#pragma mark - 工具函数

/// 文案内容.非唯一.仅作为参考,和全埋点保持一致
/// - Parameter subView: 获取标识的视图
-(NSString *)getCurrentViewNameWithView:(UIView *)subView{
    return [ZhugeAutoTrackUtils zhugeGetViewContent:subView];
}


-(void)zgLimitHandingOnce:(NSTimeInterval)intervalTime handleBlock:(void(^)(void))handleBlock{
    if (self.zgOnceHandleTagKey == YES){
        self.zgOnceHandleTagKey = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(intervalTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.zgOnceHandleTagKey = YES;
        });
        if(handleBlock){
            handleBlock();
        }
    }
}


+(NSString *)getPageData:(NSDictionary *)dic{
    NSError *parseError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    if (parseError) {
        //解析出错
    }
    NSString * str = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return  str;
}


+(NSDictionary *)getDictWithPageData:(NSString *)jsonString{
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        //解析出错
    }
    return dic;
}

-(NSDictionary *)getPageCGRectStr:(CGRect)rect{
    NSMutableDictionary * muDict = [NSMutableDictionary dictionary];
    [muDict setObject:@(rect.origin.x).stringValue forKey:@"x"];
    [muDict setObject:@(rect.origin.y).stringValue forKey:@"y"];
    [muDict setObject:@(rect.size.width).stringValue forKey:@"w"];
    [muDict setObject:@(rect.size.height).stringValue forKey:@"h"];
    return muDict.copy;
}


-(NSDictionary *)getPageCGSizeStr:(CGSize)size{
    NSMutableDictionary * muDict = [NSMutableDictionary dictionary];
    [muDict setObject:@(size.width).stringValue forKey:@"w"];
    [muDict setObject:@(size.height).stringValue forKey:@"h"];
    return muDict.copy;
}

//获取当前屏幕显示的viewcontroller
+ (UIViewController *)zg_getRootViewController
{
    UIWindow *keyWindow = [UIWindow zg_currentWindow];
    UIViewController *rootViewController = keyWindow.rootViewController;
    if ([rootViewController presentedViewController]) {
        rootViewController = [rootViewController presentedViewController];
    }
    return rootViewController;
}

//获取当前屏幕显示的viewcontroller
+ (UIViewController *)getCurrentVC
{
    UIWindow *keyWindow = [UIWindow zg_currentWindow];
    UIViewController *rootViewController = keyWindow.rootViewController;
    UIViewController *currentVC = [self getCurrentVCFrom:rootViewController];
    return currentVC;
}

+ (UIViewController *)getCurrentVCFrom:(UIViewController *)rootVC
{
    UIViewController *currentVC;
    if ([rootVC presentedViewController]) {
        rootVC = [rootVC presentedViewController];
    }
    
    if ([rootVC isKindOfClass:[UITabBarController class]]) {
        currentVC = [self getCurrentVCFrom:[(UITabBarController *)rootVC selectedViewController]];
    } else if ([rootVC isKindOfClass:[UINavigationController class]]){
        currentVC = [self getCurrentVCFrom:[(UINavigationController *)rootVC visibleViewController]];
    } else {
        currentVC = rootVC;
    }
    
    return currentVC;
}

//获取视图链
-(NSString *)getCurrentBtn:(UIView *)sender lastStr:(NSString *)lastStr {
    
    NSString * currentViewStr = lastStr;
    if(sender.superview != nil){
        currentViewStr = [NSString stringWithFormat:@"%@%zd/%@",sender.superview.class,sender.superview.zgSupViewIndex,currentViewStr];
        return [self getCurrentBtn:sender.superview lastStr:currentViewStr];
    }else{
        UIResponder *res = [sender nextResponder];
        if([res isKindOfClass:[UIViewController class]]){
            UIViewController * vc = (UIViewController *)res;
            currentViewStr = [NSString stringWithFormat:@"%@/%@",vc.title ? vc.title : NSStringFromClass(vc.class),currentViewStr];
        }
        return currentViewStr;
    }
}

//获取响应链
-(NSString *)getResponse:(UIView *)sender str:(NSString *)currentViewStr{
    if(currentViewStr == nil){
        currentViewStr = NSStringFromClass(sender.class);
    }
    UIResponder *nextRes = [sender nextResponder];
    if( nextRes != nil){
        NSString * nextStr = NSStringFromClass(nextRes.class);
        currentViewStr = [NSString stringWithFormat:@"%@/%@",nextStr,currentViewStr];
        if([nextRes isKindOfClass:[UIView class]] || [nextRes isKindOfClass:[UIViewController class]]){
            return [self getResponse:(UIView *)nextRes str:currentViewStr];
        }else{
            return currentViewStr;
        }
    }else{
        return currentViewStr;
    }
}

//获取继承链
-(NSString *)getSuperPage:(Class)sender str:(NSString *)currentViewStr{
    if(currentViewStr == nil){
        currentViewStr = NSStringFromClass(sender);
    }
    Class nextClass = [sender superclass];
    if( nextClass != nil){
        NSString * nextStr = NSStringFromClass(nextClass);
        currentViewStr = [NSString stringWithFormat:@"%@/%@",nextStr,currentViewStr];
        return [self getSuperPage:nextClass str:currentViewStr];
    }else{
        return currentViewStr;
    }
}

/// 判断当前传入的视图是否是需要可视化识别的添加手势的视图
+ (BOOL)zg_customGestureViewsHasContainCurrentView:(UIView *)currentView
{
    NSArray * views = [Zhuge getCustomGestureViews];
    __block  BOOL hasContain = NO;
    [views enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([currentView isKindOfClass:NSClassFromString(obj)]){
            *stop = YES;
            hasContain = YES;
        }
    }];
    return hasContain;
}

- (void)enterBackGround:(NSNotificationCenter *)notification{
    self.hasEnterBackGround = YES;
}
- (void)enterForeGround:(NSNotificationCenter *)notification{
    self.hasEnterBackGround = NO;
}

#pragma mark - Scene 生命周期 (iOS 13+)

- (void)sceneDidEnterBackground:(NSNotification *)notification API_AVAILABLE(ios(13.0)) {
    if (self.hasEnterBackGround || [ZGUtils hasAnyForegroundScene]) {
        return;
    }
    self.hasEnterBackGround = YES;
}

- (void)sceneWillEnterForeground:(NSNotification *)notification API_AVAILABLE(ios(13.0)) {
    if (self.hasEnterBackGround) {
        self.hasEnterBackGround = NO;
    }
}

-(NSMutableArray *)allShowClickViews
{
    if(!_allShowClickViews){
        _allShowClickViews = [NSMutableArray array];
    }
    return _allShowClickViews;
}

-(UIImageView *)showCurrentView
{
    if(!_showCurrentView){
        _showCurrentView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 300, UIScreen.mainScreen.bounds.size.width * 0.2, UIScreen.mainScreen.bounds.size.height * 0.2)];
        UIWindow * keywindow = [UIWindow zg_currentWindow];
        [keywindow addSubview:_showCurrentView];
    }
    return _showCurrentView;
}

@end
