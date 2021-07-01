//
//  NSThread+MPHelpers.h
//  Zhugeio
//
//  Created by Peter Chien on 6/29/17.
//  Copyright © 2017 Zhugeio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSThread (Helpers)

+ (void)mp_safelyRunOnMainThreadSync:(void (^)(void))block;

@end
