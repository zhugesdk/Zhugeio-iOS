//
//  ZAUUID.m
//  ZhugeioAnalytics
//

#import "ZAUUID.h"

@implementation ZAUUID

+ (NSString *)getUUID {
    return [self uuidFromUserDefaults];
}

+ (NSString *)uuidFromUserDefaults {
    // Keep the existing key so upgrades retain the same randomly generated UUID.
    static NSString * const kUUIDKey = @"zgid_uuid";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [defaults stringForKey:kUUIDKey];

    if (!uuid) {
        uuid = [[NSUUID UUID] UUIDString];
        [defaults setObject:uuid forKey:kUUIDKey];
    }
    return uuid;
}

@end
