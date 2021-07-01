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


//static NSObject *loggingLockObject;
//
//#define __ZG_MAKE_LOG_FUNCTION(LEVEL, NAME) \
//static inline void NAME(NSString *format, ...) { \
//    @synchronized(loggingLockObject) { \
//        if (![Zhuge sharedInstance].config.enableLoger) return; \
//        va_list arg_list; \
//        va_start(arg_list, format); \
//        NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list]; \
//        asl_add_log_file(NULL, STDERR_FILENO); \
//        asl_log(NULL, NULL, (LEVEL), "%s", [formattedString UTF8String]); \
//        va_end(arg_list); \
//    } \
//}
//
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//// Something has failed.
//__ZG_MAKE_LOG_FUNCTION(ASL_LEVEL_ERR, ZGLogError_legacy)
//
//// Something is amiss and might fail if not corrected.
//__ZG_MAKE_LOG_FUNCTION(ASL_LEVEL_WARNING, ZGLogWarning_legacy)
//
//// The lowest priority that you would normally log, and purely informational in nature.
//__ZG_MAKE_LOG_FUNCTION(ASL_LEVEL_INFO, ZGLogInfo_legacy)
//
//// The lowest priority, and normally not logged except for code based messages.
//__ZG_MAKE_LOG_FUNCTION(ASL_LEVEL_DEBUG, ZGLogDebug_legacy)
//
//
//#undef __MP_MAKE_LOG_FUNCTION
//#pragma clang diagnostic pop

static inline os_log_t zhugeioLog() {
    static os_log_t logger = nil;
    if (!logger) {
        if (@available(iOS 10.0, macOS 10.12, *)) {
            logger = os_log_create("com.zhugeio.sdk.ios", "Zhugeio");
        }
    }
    return logger;
}


static inline void ZGLogDebug(NSString *format, ...) {
    if (![Zhuge sharedInstance].config.enableLoger) return;
    va_list arg_list;
    va_start(arg_list, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];
    if (@available(iOS 10.0, macOS 10.12, *)) {
        os_log_with_type(zhugeioLog(), OS_LOG_TYPE_DEBUG, "<Debug>: %s", [formattedString UTF8String]);
    }
    else {
//        ZGLogDebug_legacy(@"%s", [formattedString UTF8String]);
        NSLog(@"[Zhuge]: %@", formattedString);
    }
}

static inline void ZGLogInfo(NSString *format, ...) {
    if (![Zhuge sharedInstance].config.enableLoger) return;
    va_list arg_list;
    va_start(arg_list, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];
    if (@available(iOS 10.0, macOS 10.12, *)) {
        os_log_with_type(zhugeioLog(), OS_LOG_TYPE_INFO, "<Info>: %s", [formattedString UTF8String]);
    }
    else {
//        ZGLogInfo_legacy(@"%s", [formattedString UTF8String]);
        NSLog(@"[Zhuge]: %@", formattedString);
    }
}

static inline void ZGLogWarning(NSString *format, ...) {
    if (![Zhuge sharedInstance].config.enableLoger) return;
    va_list arg_list;
    va_start(arg_list, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];
    if (@available(iOS 10.0, macOS 10.12, *)) {
        os_log_with_type(zhugeioLog(), OS_LOG_TYPE_ERROR, "<Warning>: %s", [formattedString UTF8String]);
    }
    else {
//        ZGLogWarning_legacy(@"%s", [formattedString UTF8String]);
        NSLog(@"[Zhuge]: %@", formattedString);
    }
}

static inline void ZGLogError(NSString *format, ...) {
    if (![Zhuge sharedInstance].config.enableLoger) return;
    va_list arg_list;
    va_start(arg_list, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];
    if (@available(iOS 10.0, macOS 10.12, *)) {
        os_log_with_type(zhugeioLog(), OS_LOG_TYPE_ERROR, "<Error>: %s", [formattedString UTF8String]);
    }
    else {
//        ZGLogError_legacy(@"%s", [formattedString UTF8String]);
        NSLog(@"[Zhuge]: %@", formattedString);
    }
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


