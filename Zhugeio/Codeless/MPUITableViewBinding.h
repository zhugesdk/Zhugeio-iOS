//
//  MPUITableViewBinding.h
//  HelloZhugeio
//
//  Created by Amanda Canyon on 8/5/14.
//  Copyright (c) 2014 Zhugeio. All rights reserved.
//

#import "ZGEventBinding.h"

@interface MPUITableViewBinding : ZGEventBinding

- (instancetype)init __unavailable;
- (instancetype)initWithEventName:(NSString *)eventName onPath:(NSString *)path withDelegate:(Class)delegateClass;

@end
