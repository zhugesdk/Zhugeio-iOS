//
// Copyright (c) 2014 Zhugeio. All rights reserved.

#import <Foundation/Foundation.h>
#import "ZGAbstractABTestDesignerMessage.h"

@class MPObjectSerializerConfig;

extern NSString *const MPABTestDesignerSnapshotRequestMessageType;

@interface ZGABTestDesignerSnapshotRequestMessage : ZGAbstractABTestDesignerMessage

+ (instancetype)message;

@property (nonatomic, readonly) MPObjectSerializerConfig *configuration;

@end
