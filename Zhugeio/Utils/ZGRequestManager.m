//
//  ZGRequestManager.m
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2021/1/26.
//  Copyright © 2021 GoodMorning. All rights reserved.
//

#import "ZGRequestManager.h"
#import "Zhuge.h"
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
            if([Zhuge sharedInstance].config.idfaCollect){
                NSDictionary *header = sessionConfig.HTTPAdditionalHeaders;
                if(header){
                    [header setValue:[self getUserAgent] forKey:@"User-Agent"];
                } else {
                    header = [NSDictionary dictionaryWithObject:[self getUserAgent] forKey:@"User-Agent"];
                }
                sessionConfig.HTTPAdditionalHeaders = header;
            }
            sharedSession = [NSURLSession sessionWithConfiguration:sessionConfig];
        }
    }
    return sharedSession;
}

+ (NSURLSession *)defaultURLSession {
    static NSURLSession *defaultSession = nil;
    @synchronized(self) {
        if (defaultSession == nil) {
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            sessionConfig.timeoutIntervalForRequest = 60.0;
            defaultSession = [NSURLSession sessionWithConfiguration:sessionConfig];
        }
    }
    return defaultSession;
}

+(NSString *)getUserAgent{
    NSString  *oldAgent = [NSString stringWithFormat:@"Mozilla/5.0 (%@; CPU iPhone OS %@ like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148", [[UIDevice currentDevice] model], [[[UIDevice currentDevice] systemVersion] stringByReplacingOccurrencesOfString:@"." withString:@"_"]];
    return oldAgent;
    
}

- (void)requestUrl:(NSString *)url {
    
}

@end
