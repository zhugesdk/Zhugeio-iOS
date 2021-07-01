//
//  MPABTestDesignerClearResponseMessage.m
//  HelloZhugeio
//
//  Created by Alex Hofsteede on 3/7/14.
//  Copyright (c) 2014 Zhugeio. All rights reserved.
//

#import "ZGABTestDesignerClearResponseMessage.h"

@implementation ZGABTestDesignerClearResponseMessage

+ (instancetype)message
{
    return [(ZGABTestDesignerClearResponseMessage *)[self alloc] initWithType:@"clear_response"];
}

- (void)setStatus:(NSString *)status
{
    [self setPayloadObject:status forKey:@"status"];
}

- (NSString *)status
{
    return [self payloadObjectForKey:@"status"];
}

@end
