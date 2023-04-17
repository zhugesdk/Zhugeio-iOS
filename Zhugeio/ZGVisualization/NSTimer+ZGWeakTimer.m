//
//  NSTimer+ZGWeakTimer.m
//  ZGTestDemo
//
//  Created by 范奇 on 2023/2/23.
//

#import "NSTimer+ZGWeakTimer.h"

@interface ZGWeakTimerTargetObj : NSObject

@property (nonatomic, weak) id aTarget;
@property (nonatomic, assign) SEL aSelector;

-(void)fire:(NSTimer *)timer;

@end
/**
 *  该类的作用是用来接管定时器的强引用
 */
@implementation ZGWeakTimerTargetObj

-(void)fire:(NSTimer *)timer{
    if (self.aTarget) {
        if ([self.aTarget respondsToSelector:self.aSelector]) {
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self.aTarget performSelector:self.aSelector withObject:timer.userInfo];
        }
    }else{
        [timer invalidate];
    }
}

@end

@implementation NSTimer (ZGWeakTimer)

+ (NSTimer *)scheduledWeakTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo {
    
    // 创建当前类对象
    ZGWeakTimerTargetObj *obj = [[ZGWeakTimerTargetObj alloc] init];
    obj.aTarget = aTarget; // 控制器
    obj.aSelector = aSelector; // 控制器的update方法
    return [NSTimer scheduledTimerWithTimeInterval:ti target:obj selector:@selector(fire:) userInfo:userInfo repeats:yesOrNo];
}

@end
