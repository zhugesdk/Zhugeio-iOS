//
//  ZGPrivacyManager.m
//  Pods
//
//  Created by kang on 2025/7/20.
//


#import "ZGPrivacyManager.h"
#import "ZGLog.h"
@implementation ZGPrivacyManager

static NSString * const kZGPrivacyAgreedKey = @"com.zhuge.sdk.privacyAgreed";
static NSString * const kZGPrivacyControllKey = @"com.zhuge.sdk.privacyControl";
static NSString * const kZhugeSDKConfigSuite = @"com.zhuge.sdk.config";

+ (instancetype)sharedManager {
    static ZGPrivacyManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ZGPrivacyManager alloc] init];
    });
    return instance;
}

-(NSUserDefaults*)sdkDefaults{
    static NSUserDefaults *zgDefaults = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        zgDefaults = [[NSUserDefaults alloc] initWithSuiteName:kZhugeSDKConfigSuite];
    });
    return zgDefaults;
}

- (void)setUserAgreed:(BOOL)agreed {
    [[self sdkDefaults] setBool:agreed forKey:kZGPrivacyAgreedKey];
}

- (BOOL)isUserAgreed {
    NSUserDefaults *config = [self sdkDefaults];
    BOOL enable = [config boolForKey:kZGPrivacyControllKey];
    if (!enable) {
        return YES;
    }
    return [config boolForKey:kZGPrivacyAgreedKey];
}

-(void)setPrivacyControl:(BOOL)enable{
    [[self sdkDefaults] setBool:enable forKey:kZGPrivacyControllKey];
}

@end
