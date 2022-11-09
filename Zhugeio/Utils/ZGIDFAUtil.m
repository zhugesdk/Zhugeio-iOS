//
//  ZGIDFAUtil.m
//  ZhugeioAnanlytics
//
//  Created by jiaokang on 2022/10/15.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "ZGIDFAUtil.h"

@implementation ZGIDFAUtil

+ (id)idfaManager {
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
    if (![ASIdentifierManagerClass respondsToSelector:sharedManagerSelector]) {
        return nil;
    }

    id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
    return sharedManager;
}

+ (BOOL)isEnableIDFA {
    if (@available(iOS 14.5, *)) {
        Class ATTrackingManagerClass = NSClassFromString(@"ATTrackingManager");
        SEL trackingAuthorizationStatusSelector = NSSelectorFromString(@"trackingAuthorizationStatus");
        if (![ATTrackingManagerClass respondsToSelector:trackingAuthorizationStatusSelector]) {
            return NO;
        }
        NSInteger status = ((NSInteger (*)(id, SEL))[ATTrackingManagerClass methodForSelector:trackingAuthorizationStatusSelector])(ATTrackingManagerClass, trackingAuthorizationStatusSelector);
        return status == 3;
    }

    id idfaManager = [self idfaManager];
    SEL isEnableIDFASelector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
    if (![idfaManager respondsToSelector:isEnableIDFASelector]) {
        return NO;
    }

    BOOL isEnable = ((BOOL (*)(id, SEL))[idfaManager methodForSelector:isEnableIDFASelector])(idfaManager, isEnableIDFASelector);
    return isEnable;
}

+ (NSString *)idfa {
    if (![self isEnableIDFA]) {
        return nil;
    }

    id idfaManager = [self idfaManager];
    SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
    if (![idfaManager respondsToSelector:advertisingIdentifierSelector]) {
        return nil;
    }

    NSUUID *uuid = ((NSUUID * (*)(id, SEL))[idfaManager methodForSelector:advertisingIdentifierSelector])(idfaManager, advertisingIdentifierSelector);;
    NSString *idfa = [uuid UUIDString];
    // 在 iOS 10.0 以后，当用户开启限制广告跟踪，advertisingIdentifier 的值是全零
    // 00000000-0000-0000-0000-000000000000
    return idfa;
}

@end
