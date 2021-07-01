//
//  ZGRequestManager.h
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2021/1/26.
//  Copyright © 2021 GoodMorning. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGRequestManager : NSObject

+ (ZGRequestManager *)sharedManager;

+ (NSURLSession *)sharedURLSession;

- (void)requestUrl:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
