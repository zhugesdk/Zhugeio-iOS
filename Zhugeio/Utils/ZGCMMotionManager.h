//
//  ZGCMMotionManager.h
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2020/7/12.
//  Copyright © 2020 GoodMorning. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGCMMotionManager : NSObject

+ (ZGCMMotionManager *)sharedManager;

- (NSString *)setupGyro;

@end

NS_ASSUME_NONNULL_END
