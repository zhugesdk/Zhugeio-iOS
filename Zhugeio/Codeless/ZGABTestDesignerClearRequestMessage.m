//
//  MPABTestDesignerClearRequestMessage.m
//  HelloZhugeio
//
//  Created by Alex Hofsteede on 3/7/14.
//  Copyright (c) 2014 Zhugeio. All rights reserved.
//

#import "ZGABTestDesignerClearRequestMessage.h"
#import "ZGABTestDesignerClearResponseMessage.h"
#import "ZGABTestDesignerConnection.h"
#import "ZGVariant.h"

NSString *const MPABTestDesignerClearRequestMessageType = @"clear_request";

@implementation ZGABTestDesignerClearRequestMessage

+ (instancetype)message
{
    return [(ZGABTestDesignerClearRequestMessage *)[self alloc] initWithType:MPABTestDesignerClearRequestMessageType];
}

- (NSOperation *)responseCommandWithConnection:(ZGABTestDesignerConnection *)connection
{
    __weak ZGABTestDesignerConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        ZGABTestDesignerConnection *conn = weak_connection;

        ZGVariant *variant = [conn sessionObjectForKey:kSessionVariantKey];
        if (variant) {
            NSArray *actions = [self payload][@"actions"];
            for (NSString *name in actions) {
                [variant removeActionWithName:name];
            }
        }

        ZGABTestDesignerClearResponseMessage *clearResponseMessage = [ZGABTestDesignerClearResponseMessage message];
        clearResponseMessage.status = @"OK";
        [conn sendMessage:clearResponseMessage];
    }];
    return operation;
}

@end
