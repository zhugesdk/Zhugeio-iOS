//
//  MPDesignerEventBindingMessage.h
//  HelloZhugeio
//
//  Created by Amanda Canyon on 11/18/14.
//  Copyright (c) 2014 Zhugeio. All rights reserved.
//

#import "ZGAbstractABTestDesignerMessage.h"

extern NSString *const MPDesignerEventBindingRequestMessageType;

@interface MPDesignerEventBindingRequestMessage : ZGAbstractABTestDesignerMessage

@end

__deprecated
@interface MPDesignerEventBindingRequestMesssage : MPDesignerEventBindingRequestMessage

@end


@interface MPDesignerEventBindingResponseMessage : ZGAbstractABTestDesignerMessage

+ (instancetype)message;

@property (nonatomic, copy) NSString *status;

@end

__deprecated
@interface MPDesignerEventBindingResponseMesssage : MPDesignerEventBindingResponseMessage

@end


@interface MPDesignerTrackMessage : ZGAbstractABTestDesignerMessage

+ (instancetype)message;
+ (instancetype)messageWithPayload:(NSDictionary *)payload;

@end


