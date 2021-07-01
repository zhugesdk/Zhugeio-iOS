//
//  ShakeGesture.h
//  newdemo
//
//  Created by Zhugeio on 15/10/10.
//  Copyright © 2015年 Zhugeio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>



@protocol ShakeGestureDelegate <NSObject>

@required
- (void)onShakeGestureDo;

@end

@interface ShakeGesture : NSObject
@property(nonatomic,weak) id<ShakeGestureDelegate> delegate;
@property (nonatomic, strong)CMMotionManager *motionManager;

-(void)startShakeGesture;
-(void)stopShakeListen;

@end

