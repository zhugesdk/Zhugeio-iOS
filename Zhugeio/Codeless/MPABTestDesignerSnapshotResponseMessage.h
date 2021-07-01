//
// Copyright (c) 2014 Zhugeio. All rights reserved.

#import <UIKit/UIKit.h>
#import "ZGAbstractABTestDesignerMessage.h"

@interface MPABTestDesignerSnapshotResponseMessage : ZGAbstractABTestDesignerMessage

+ (instancetype)message;

@property (nonatomic, strong) UIImage *screenshot;
@property (nonatomic, copy) NSDictionary *serializedObjects;
@property (nonatomic, strong, readonly) NSString *imageHash;

@end
