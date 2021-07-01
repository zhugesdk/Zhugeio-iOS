//
//  NSThread+MPHelpers.m
//  Zhugeio
//
//  Created by Peter Chien on 6/29/17.
//  Copyright © 2017 Zhugeio. All rights reserved.
//

#import "NSThread+Helpers.h"

@implementation NSThread (Helpers)

+ (void)mp_safelyRunOnMainThreadSync:(void (^)(void))block {
    if ([self isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@end
