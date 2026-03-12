//
//  ZGRequest.h
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2020/8/14.
//  Copyright © 2020 GoodMorning. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^CompletionBlock)(NSDictionary *resultDic);

@interface ZGRequest : NSObject

+ (void)postRequestWithApi:(NSString *)url backupUrl:(NSString *)backupUrl parameters:(NSString *)parameters callback:(CompletionBlock)callback;

+ (void)getRequestWithApi:(NSString *)url backupUrl:(NSString *)backupUrl parameters:(NSString *)parameters callback:(CompletionBlock)callback;

@end

NS_ASSUME_NONNULL_END
