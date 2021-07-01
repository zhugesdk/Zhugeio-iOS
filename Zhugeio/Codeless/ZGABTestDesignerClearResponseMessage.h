//
//  MPABTestDesignerClearResponseMessage.h
//  HelloZhugeio
//
//  Created by Alex Hofsteede on 3/7/14.
//  Copyright (c) 2014 Zhugeio. All rights reserved.
//

#import "ZGAbstractABTestDesignerMessage.h"

@interface ZGABTestDesignerClearResponseMessage : ZGAbstractABTestDesignerMessage

+ (instancetype)message;

@property (nonatomic, copy) NSString *status;

@end
