//
//  MPABTestDesignerTweakResponseMessage.h
//  HelloZhugeio
//
//  Created by Alex Hofsteede on 7/5/14.
//  Copyright (c) 2014 Zhugeio. All rights reserved.
//

#import "ZGAbstractABTestDesignerMessage.h"

@interface MPABTestDesignerTweakResponseMessage : ZGAbstractABTestDesignerMessage

+ (instancetype)message;

@property (nonatomic, copy) NSString *status;

@end
