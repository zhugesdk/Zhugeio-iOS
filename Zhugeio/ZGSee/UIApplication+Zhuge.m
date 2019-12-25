//
//  UIApplication+Zhuge.m
//  HelloZhuge
//
//  Created by jiaokang on 2018/9/5.
//  Copyright © 2018年 37degree. All rights reserved.
//

#import "UIApplication+Zhuge.h"
#import "Zhuge.h"
#import "ZGSharedDur.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "ZhugeAutoTrackUtils.h"


static UITouch *_touch;
//开始坐标
//static CGPoint _beginPoint;
//结束坐标
//static CGPoint _endPoint;
//移动坐标
//static CGPoint _movedPoint;
//事件触发在会话开始的第几秒
//static CGFloat eventFloat = 0.0;
//移动有效坐标倍数 用于减少上传坐标数量 20像素上传一次
//static NSInteger directionNum = 1;
//存储坐标数组
static NSMutableArray *_pointArray;
//存储拖动方向
static NSString * directionStr = @"";
//存储开始截图
static NSData *_imageData;
//viewPath
static NSString *_viewPath = @"";
//操作时间
static NSDate *_rdDate;

static NSMutableDictionary *_dataDic;


@implementation UIApplication (Zhuge)

-(BOOL)zhuge_sendAction:(SEL)action to:(id)to from:(id)from forEvent:(UIEvent *)event{
    
    /*
     默认先执行 AutoTrack
     如果先执行原点击处理逻辑，可能已经发生页面 push 或者 pop，导致获取当前 ViewController 不正确
     */
    
    @try {
        [self zhuge_track:action to:to from:from forEvent:event];
    } @catch (NSException *exception) {
        NSLog(@"%@ error: %@", self, exception);
    }
    return [self zhuge_sendAction:action to:to from:from forEvent:event];
}

- (void)zhuge_track:(SEL)action to:(id)to from:(id)from forEvent:(UIEvent *)event {
    // ViewType 被忽略
    if ([to isKindOfClass:[UITabBar class]]) {
        return;
    }
    BOOL isTabBar = [from isKindOfClass:[UITabBarItem class]] && [to isKindOfClass:[UITabBarController class]];
    
    
    if ([from isKindOfClass:[UISwitch class]] ||
        [from isKindOfClass:[UIStepper class]] ||
        [from isKindOfClass:[UISegmentedControl class]] ||
        [from isKindOfClass:[UITabBarItem class]]) {
        [ZhugeAutoTrackUtils zhugeAutoTrackClick:from withController:isTabBar ? (UITabBarController *)to : nil andTag:@"type1"];
        return;
    }
    
    if ([event isKindOfClass:[UIEvent class]] && event.type == UIEventTypeTouches && [[[event allTouches] anyObject] phase] == UITouchPhaseEnded) {
        [ZhugeAutoTrackUtils zhugeAutoTrackClick:from withController:isTabBar ? (UITabBarController *)to : nil andTag:@"type2"];
        return;
    }
    
}

//+ (void)load {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//
//        SEL origilaSEL = @selector(sendEvent:);
//
//        SEL hook_SEL = @selector(gc_sendEvent:);
//
//        //交换方法
//        Method origilalMethod = class_getInstanceMethod(self, origilaSEL);
//
//
//        Method hook_method = class_getInstanceMethod(self, hook_SEL);
//
//
//        class_addMethod(self,
//                        origilaSEL,
//                        class_getMethodImplementation(self, origilaSEL),
//                        method_getTypeEncoding(origilalMethod));
//
//        class_addMethod(self,
//                        hook_SEL,
//                        class_getMethodImplementation(self, hook_SEL),
//                        method_getTypeEncoding(hook_method));
//
//        method_exchangeImplementations(class_getInstanceMethod(self, origilaSEL), class_getInstanceMethod(self, hook_SEL));
//
//    });
//
//
//
//}
//
//- (void)gc_sendEvent:(UIEvent *)event {
//
//    ZGSharedDur *dur = [ZGSharedDur shareInstance];
//    BOOL isKeyboard = [dur isKeyboardShow];
//    if ([[Zhuge sharedInstance].config isSeeEnable] && !isKeyboard && event.type==UIEventTypeTouches) {
//        //响应触摸事件（手指刚刚放上屏幕）
//        if (!_touch) {
//            _touch=[event.allTouches anyObject];
//        }
//        UIWindow * window=[[[UIApplication sharedApplication] delegate] window];
//
//        if ([[event.allTouches anyObject] phase] == UITouchPhaseBegan) {
//            //初始化坐标数组
//            if (!_pointArray) {
//                _pointArray = [[NSMutableArray alloc] init];
//            }
//
//            if (_pointArray.count > 0) {
//                [_pointArray removeAllObjects];
//            }
//
//            //记录开始触摸的点
//            _beginPoint = [_touch locationInView:window];
//
//            //坐标
//            _viewPath = [[ZGSharedDur shareInstance] getViewToPath:_touch.view];
//
//            //添加坐标
//            [_pointArray addObject:@[@(_beginPoint.x),@(_beginPoint.y)]];
//
//            //操作开始时间
//            _rdDate = [NSDate date];
//
//            //动作开始时 截图
//            _imageData = [[ZGSharedDur shareInstance] pixData];
//
//        }
//        if ([[event.allTouches anyObject] phase] == UITouchPhaseMoved) {
//            //移动Point
//            _movedPoint = [_touch locationInView:window];
//
//            //计算移动Point
//            CGPoint deltaPoint = CGPointMake((_beginPoint.x - _movedPoint.x), (_beginPoint.y - _movedPoint.y));
//
//            [self commitTranslation:deltaPoint movedPoint:_movedPoint];
//
//        }
//        if ([[event.allTouches anyObject] phase] == UITouchPhaseStationary) {
//
////            _imageData = [[ZGSharedDur shareInstance] pixData];
//
//        }
//        if ([[event.allTouches anyObject] phase] == UITouchPhaseEnded) {
//            //结束Point
//            _endPoint = [_touch locationInView:window];
//            //上传数据
//            [self taskData];
//
//            //清空有效移动倍数
//            directionNum = 1;
//        }
//        if ([[event.allTouches anyObject] phase] == UITouchPhaseCancelled) {
//
//        }
//    }
//
//    [self gc_sendEvent:event];
//
//}
//
////整理并上传数据
//- (void)taskData {
//    ZGSharedDur * dur = [ZGSharedDur shareInstance];
//    if (!_dataDic) {
//        _dataDic = [[NSMutableDictionary alloc] init];
//    }
//    _dataDic[@"$pix"] = _imageData;
//    _dataDic[@"$page"] = _viewPath;
//    _dataDic[@"$dru"] = @([[ZGSharedDur shareInstance] durInterval]);
//    _dataDic[@"$pel"] = _pointArray;
//    NSString *gap = [dur getCurrentGap];
//    [dur updateCommanGapData];
//    _dataDic[@"$gap"] = gap;
//    _dataDic[@"$rd"] = @([[NSDate date] timeIntervalSinceDate:_rdDate]);
//    _dataDic[@"$wh"] = @[@([UIScreen mainScreen ].bounds.size.width),@([UIScreen mainScreen ].bounds.size.height)];
//    if (_pointArray.count>1) {
//        _dataDic[@"$eid"] = @"zgsee-scroll";
//    } else {
//        _dataDic[@"$eid"] = @"zgsee-click";
//    }
//    _dataDic[@"$pn"] = [[ZGSharedDur shareInstance] zhugeGetCurrentVC];
////    NSLog(@"_dataDic == %@",_dataDic);
//    [[Zhuge sharedInstance] setZhuGeSeeEvent:_dataDic];
//}

//#pragma mark --- 拖动手势方向
///** 判断手势方向  */
//- (void)commitTranslation:(CGPoint)translation movedPoint:(CGPoint)movedPoint{
//
//    CGFloat absX = fabs(translation.x);
//    CGFloat absY = fabs(translation.y);
//
//    //算法-滑动有效距离倍数
//    NSInteger  directionInt = 50 * directionNum;
//    //上下滑动
//    if(absY > absX) {
//        //向上滑动
//        if (translation.y > directionInt)   //有效滑动距离 MINDISTANCE
//        {
//            [self directionName:@"向上滑动" movedPoint:movedPoint];
//        }
//        //向下滑动
//        else if (translation.y < -directionInt)
//        {
//            [self directionName:@"向下滑动" movedPoint:movedPoint];
//        }
//    }
//    //左右滑动
//    else if(absX > absY) {
//        if (translation.x > directionInt) {  //向左滑动
//            [self directionName:@"向左滑动" movedPoint:movedPoint];
//        } else if (translation.x < -directionInt) {  //向右滑动
//            [self directionName:@"向右滑动" movedPoint:movedPoint];
//        }
//    }
//
//}
//
//- (void)directionName:(NSString *)directionName movedPoint:(CGPoint)movedPoint {
//    directionNum++;
//    directionStr = directionName;
//    //添加坐标
//    [_pointArray addObject:@[@(movedPoint.x),@(movedPoint.y)]];
//}



@end
