//
//  MPABTestDesignerDisconnectMessage.m
//  HelloZhugeio
//
//  Created by Alex Hofsteede on 29/7/14.
//  Copyright (c) 2014 Zhugeio. All rights reserved.
//

#import "ZGABTestDesignerConnection.h"
#import "ZGABTestDesignerDisconnectMessage.h"
#import "ZGVariant.h"

NSString *const MPABTestDesignerDisconnectMessageType = @"disconnect";

@implementation ZGABTestDesignerDisconnectMessage

+ (instancetype)message
{
    return [(ZGABTestDesignerDisconnectMessage *)[self alloc] initWithType:MPABTestDesignerDisconnectMessageType];
}

- (NSOperation *)responseCommandWithConnection:(ZGABTestDesignerConnection *)connection
{
    __weak ZGABTestDesignerConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        ZGABTestDesignerConnection *conn = weak_connection;

        ZGVariant *variant = [connection sessionObjectForKey:kSessionVariantKey];
        if (variant) {
            [variant stop];
        }

        conn.sessionEnded = YES;
        [conn close];
    }];
    return operation;
}

@end
