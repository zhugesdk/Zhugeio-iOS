//
//  ZGNetworking.h
//  HelloZhuge
//
//  Created by Good_Morning_ on 2020/1/2.
//  Copyright © 2020 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZGNetConstant.h"
NS_ASSUME_NONNULL_BEGIN

@interface ZGNetworking : NSObject

+(void)requestWithUrl:(NSString *)url parameters:(NSString *)parameters method:(NSString *)method completionhandler:(void (^)(NSURLResponse *response, NSData *data, NSError *error))complate;


@end

NS_ASSUME_NONNULL_END
