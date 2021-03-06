//
// Copyright (c) 2014 Zhugeio. All rights reserved.

#import <Foundation/Foundation.h>

@class MPClassDescription;
@class MPObjectSerializerContext;
@class MPObjectSerializerConfig;
@class MPObjectIdentityProvider;

@interface MPObjectSerializer : NSObject

/*!
 An array of MPClassDescription instances.
 */
- (instancetype)initWithConfiguration:(MPObjectSerializerConfig *)configuration objectIdentityProvider:(MPObjectIdentityProvider *)objectIdentityProvider;

- (NSDictionary *)serializedObjectsWithRootObject:(id)rootObject;

@end
