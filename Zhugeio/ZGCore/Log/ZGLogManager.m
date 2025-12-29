//
//  LogManager.m
//  ZhugeioAnanlytics
//
//  Created by kang on 2025/8/24.
//

// LogManager.m

#import "ZGLogManager.h"

@interface ZGLogManager ()
@property (nonatomic, strong) NSMutableArray<NSString *> *logs;
@property (nonatomic, strong)NSDateFormatter *dfm;
@end

NSString * const ZgLogManagerDidAddLogNotification = @"LogManagerDidAddLogNotification";

@implementation ZGLogManager

+ (instancetype)shared {
    static ZGLogManager *mgr;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        mgr = [ZGLogManager new];
        mgr.logs = [NSMutableArray array];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyy-MM-dd";
        mgr.dfm = formatter;
    });
    return mgr;
}

- (void)addLog:(NSString *)log {
#if ZHUGE_SDK_DEBUG
    NSString *line = [NSString stringWithFormat:@"%@ %@", [self.dfm stringFromDate:[NSDate date]], log];
    if ([self.logs count] >= 500) {
        [self.logs removeLastObject];
    }
    [self.logs addObject:line];
    
    // 发送通知，带上新日志
    [[NSNotificationCenter defaultCenter] postNotificationName:ZgLogManagerDidAddLogNotification
                                                        object:line];
#endif
}

- (NSArray<NSString *> *)allLogs {
    return self.logs.copy;
}

@end
