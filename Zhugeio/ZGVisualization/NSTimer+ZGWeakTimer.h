//
//  NSTimer+ZGWeakTimer.h
//  ZGTestDemo
//
//  Created by 范奇 on 2023/2/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTimer (ZGWeakTimer)

+ (NSTimer *)scheduledWeakTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo;


@end

NS_ASSUME_NONNULL_END
