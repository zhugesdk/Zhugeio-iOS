//
//  ZGLog.h
//  iosapp
//
//  Created by Zhugeio on 15/10/23.
//  Copyright © 2015年 oschina. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <asl.h>
#import <pthread.h>
#import <os/log.h>
#import "Zhuge.h"
#if ZHUGE_SDK_DEBUG
#import "ZGLogManager.h"
#endif
static inline os_log_t zhugeioLog() {
    static os_log_t logger = nil;
    if (!logger) {
        if (@available(iOS 10.0, macOS 10.12, *)) {
            logger = os_log_create("com.zhugeio.sdk.ios", "Zhugeio");
        }
    }
    return logger;
}

// 获取线程名（主线程显示 main，其他线程显示 queue/thread 名称）
//static inline NSString *ZGCurrentThreadName(void) {
//    if ([NSThread isMainThread]) return @"main";
//    NSString *name = [[NSThread currentThread] name];
//    if (name.length == 0) name = [NSString stringWithFormat:@"%p", [NSThread currentThread]];
//    return name;
//}

static inline void addToZGLogManager(NSString *log) {
#if ZHUGE_SDK_DEBUG
    [[ZGLogManager shared] addLog:log];
#endif
}

// 获取时间戳（线程安全）
static inline NSString *ZGCurrentTimestampString(void) {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"HH:mm:ss.SSS"];
        [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    });
    return [formatter stringFromDate:[NSDate date]];
}


static inline void ZGLogDebug(NSString *format, ...) {
    if (![Zhuge isLogEnable]) return;
    
    va_list arg_list;
    va_start(arg_list, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];
    va_end(arg_list);

    // 拼接时间戳
    NSString *logMessage = [NSString stringWithFormat:@"[%@]<Debug> %@", ZGCurrentTimestampString(), formattedString];

    if (@available(iOS 10.0, macOS 10.12, *)) {
        os_log_with_type(zhugeioLog(), OS_LOG_TYPE_DEBUG, "%{public}s", [logMessage UTF8String]);
    }
    else {
//        ZGLogDebug_legacy(@"%s", [formattedString UTF8String]);
        NSLog(@"[Zhuge]: %@", formattedString);
    }
    addToZGLogManager(logMessage);
}

static inline void ZGLogInfo(NSString *format, ...) {
    if (![Zhuge isLogEnable]) return;
    va_list arg_list;
    va_start(arg_list, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];
    va_end(arg_list);

    // 拼接时间戳
    NSString *logMessage = [NSString stringWithFormat:@"[%@] <Info> %@", ZGCurrentTimestampString(), formattedString];

    if (@available(iOS 10.0, macOS 10.12, *)) {
        os_log_with_type(zhugeioLog(), OS_LOG_TYPE_INFO,  "%{public}s", [logMessage UTF8String]);
    }
    else {
//        ZGLogInfo_legacy(@"%s", [formattedString UTF8String]);
        NSLog(@"[Zhuge]: %@", formattedString);
    }
    addToZGLogManager(logMessage);
}

static inline void ZGLogWarning(NSString *format, ...) {
    if (![Zhuge isLogEnable]) return;
    va_list arg_list;
    va_start(arg_list, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];
    va_end(arg_list);

    // 拼接时间戳
    NSString *logMessage = [NSString stringWithFormat:@"[%@] <Warning> %@", ZGCurrentTimestampString(), formattedString];

    if (@available(iOS 10.0, macOS 10.12, *)) {
        os_log_with_type(zhugeioLog(), OS_LOG_TYPE_ERROR, "%{public}s", [logMessage UTF8String]);
    }
    else {
//        ZGLogWarning_legacy(@"%s", [formattedString UTF8String]);
        NSLog(@"[Zhuge]: %@", formattedString);
    }
    addToZGLogManager(logMessage);
}

static inline void ZGLogError(NSString *format, ...) {
    if (![Zhuge isLogEnable]) return;
    va_list arg_list;
    va_start(arg_list, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];
    va_end(arg_list);

    // 拼接时间戳
    NSString *logMessage = [NSString stringWithFormat:@"[%@] <Error> %@", ZGCurrentTimestampString(), formattedString];

    if (@available(iOS 10.0, macOS 10.12, *)) {
        os_log_with_type(zhugeioLog(), OS_LOG_TYPE_ERROR, "%{public}s", [logMessage UTF8String]);
    }
    else {
//        ZGLogError_legacy(@"%s", [formattedString UTF8String]);
        NSLog(@"[Zhuge]: %@", formattedString);
    }
    addToZGLogManager(logMessage);
}



//static inline void ZGLog(NSString *format, ...) {
//    __block va_list arg_list;
//    va_start (arg_list, format);
//    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];
//    va_end(arg_list);
//    if ([Zhuge sharedInstance].config.enableLoger == YES) {
//        NSLog(@"[Zhuge]: %@", formattedString);
//    }
//
//}

//#define ZhugeDebug(...) ZGLog(__VA_ARGS__)


