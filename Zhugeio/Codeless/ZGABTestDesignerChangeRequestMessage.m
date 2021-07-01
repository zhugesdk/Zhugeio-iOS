//
// Copyright (c) 2014 Zhugeio. All rights reserved.

#import "ZGABTestDesignerChangeRequestMessage.h"
#import "ZGABTestDesignerChangeResponseMessage.h"
#import "ZGABTestDesignerConnection.h"
#import "MPABTestDesignerSnapshotResponseMessage.h"
#import "ZGVariant.h"

NSString *const MPABTestDesignerChangeRequestMessageType = @"change_request";

@implementation ZGABTestDesignerChangeRequestMessage

+ (instancetype)message
{
    return [(ZGABTestDesignerChangeRequestMessage *)[self alloc] initWithType:MPABTestDesignerChangeRequestMessageType];
}

- (NSOperation *)responseCommandWithConnection:(ZGABTestDesignerConnection *)connection
{
    __weak ZGABTestDesignerConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        ZGABTestDesignerConnection *conn = weak_connection;

        ZGVariant *variant = [connection sessionObjectForKey:kSessionVariantKey];
        if (!variant) {
            variant = [[ZGVariant alloc] init];
            [connection setSessionObject:variant forKey:kSessionVariantKey];
        }

        id actions = [self payload][@"actions"];
        if ([actions isKindOfClass:[NSArray class]]) {
            [variant addActionsFromJSONObject:actions andExecute:YES];
        }

        ZGABTestDesignerChangeResponseMessage *changeResponseMessage = [ZGABTestDesignerChangeResponseMessage message];
        changeResponseMessage.status = @"OK";
        [conn sendMessage:changeResponseMessage];
    }];

    return operation;
}

@end
