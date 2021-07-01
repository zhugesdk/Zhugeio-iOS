//
// Copyright (c) 2014 Zhugeio. All rights reserved.

#import "ZGABTestDesignerChangeResponseMessage.h"

@implementation ZGABTestDesignerChangeResponseMessage

+ (instancetype)message
{
    return [(ZGABTestDesignerChangeResponseMessage *)[self alloc] initWithType:@"change_response"];
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
