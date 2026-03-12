//
//  LogManager.h
//  ZhugeioAnanlytics
//
//  Created by kang on 2025/8/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
extern NSString * const ZgLogManagerDidAddLogNotification;

// LogManager.h
@interface ZGLogManager : NSObject
+ (instancetype)shared;
- (void)addLog:(NSString *)log;
- (NSArray<NSString *> *)allLogs;
@end
NS_ASSUME_NONNULL_END

