//
// Copyright (c) 2014 Zhugeio. All rights reserved.

#import <Foundation/Foundation.h>
#import "ZGWebSocket.h"

@protocol ZGABTestDesignerMessage;

extern NSString *const kSessionVariantKey;

@interface ZGABTestDesignerConnection : NSObject

@property (nonatomic, readonly) BOOL connected;
@property (nonatomic, assign) BOOL sessionEnded;

- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithURL:(NSURL *)url keepTrying:(BOOL)keepTrying connectCallback:(void (^)(void))connectCallback disconnectCallback:(void (^)(void))disconnectCallback;

- (void)setSessionObject:(id)object forKey:(NSString *)key;
- (id)sessionObjectForKey:(NSString *)key;
- (void)sendMessage:(id<ZGABTestDesignerMessage>)message;
- (void)close;

// 可视化-发送登录的消息
- (void)sendLoginMessage:(id<ZGABTestDesignerMessage>)message;
// 可视化-初始化方法.
- (instancetype)initWithURL:(NSURL *)url keepTrying:(BOOL)keepTrying connectCallback:(void (^)(void))connectCallback didOpenCallback:(void(^)(void))didOpenCallback messageCallback:(void(^)(id message))messageCallback  disconnectCallback:(void (^)(void))disconnectCallback;

@end
