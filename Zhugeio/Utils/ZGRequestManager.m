//
//  ZGRequestManager.m
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2021/1/26.
//  Copyright © 2021 GoodMorning. All rights reserved.
//

#import "ZGRequestManager.h"

@interface ZGRequestManager ()

@end

@implementation ZGRequestManager

+ (ZGRequestManager *)sharedManager {
    static ZGRequestManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[ZGRequestManager alloc] init];
    });
    return shared;
}

+ (NSURLSession *)sharedURLSession {
    static NSURLSession *sharedSession = nil;
    @synchronized(self) {
        if (sharedSession == nil) {
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            sessionConfig.timeoutIntervalForRequest = 30.0;
            sharedSession = [NSURLSession sessionWithConfiguration:sessionConfig];
        }
    }
    return sharedSession;
}

- (void)requestUrl:(NSString *)url {
    
}

@end
