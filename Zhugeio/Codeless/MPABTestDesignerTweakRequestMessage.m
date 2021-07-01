//
//  MPABTestDesignerTweakRequestMessage.h
//  HelloZhugeio
//
//  Created by Alex Hofsteede on 7/5/14.
//  Copyright (c) 2014 Zhugeio. All rights reserved.
//

#import "ZGABTestDesignerConnection.h"
#import "MPABTestDesignerTweakRequestMessage.h"
#import "MPABTestDesignerTweakResponseMessage.h"
#import "ZGLog.h"
#import "ZGVariant.h"

NSString *const MPABTestDesignerTweakRequestMessageType = @"tweak_request";

@implementation MPABTestDesignerTweakRequestMessage

+ (instancetype)message
{
    return [(MPABTestDesignerTweakRequestMessage *)[self alloc] initWithType:MPABTestDesignerTweakRequestMessageType];
}

- (NSOperation *)responseCommandWithConnection:(ZGABTestDesignerConnection *)connection
{
    __weak ZGABTestDesignerConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        ZGABTestDesignerConnection *conn = weak_connection;

        ZGVariant *variant = [conn sessionObjectForKey:kSessionVariantKey];
        if (!variant) {
            variant = [[ZGVariant alloc] init];
            [conn setSessionObject:variant forKey:kSessionVariantKey];
        }

        id tweaks = [self payload][@"tweaks"];
        if ([tweaks isKindOfClass:[NSArray class]]) {
            [variant addTweaksFromJSONObject:tweaks andExecute:YES];
        }

        MPABTestDesignerTweakResponseMessage *changeResponseMessage = [MPABTestDesignerTweakResponseMessage message];
        changeResponseMessage.status = @"OK";
        [conn sendMessage:changeResponseMessage];
    }];

    return operation;
}

@end
