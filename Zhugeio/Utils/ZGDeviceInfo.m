//
//  ZGDeviceInfo.m
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2020/8/17.
//  Copyright © 2020 GoodMorning. All rights reserved.
//

#import "ZGDeviceInfo.h"
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <sys/sysctl.h>
#import "sys/utsname.h"
#import <mach/mach.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import "ZGCMMotionManager.h"


@implementation ZGDeviceInfo

+ (NSString *)wifiSsid {
    NSString *ssid = @"Not Found";
    CFArrayRef myArray = CNCopySupportedInterfaces();
    if (myArray != nil) {
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
        if (myDict != nil) {
            NSDictionary *dict = (NSDictionary*)CFBridgingRelease(myDict);
            ssid = [dict valueForKey:@"SSID"];
        }
    }
    return ssid;
}

+ (NSString *)wifiBssid {
    NSString *bssid = @"Not Found";
    CFArrayRef myArray = CNCopySupportedInterfaces();

    if (myArray != nil) {
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
        if (myDict != nil) {
            NSDictionary *dict = (NSDictionary*)CFBridgingRelease(myDict);
            bssid = [dict valueForKey:@"BSSID"];
        }
        
    }
    return bssid;
}

// 获取当前设备可用内存(单位：MB）
+ (NSString *)availableMemory {
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(),
                                               HOST_VM_INFO,
                                               (host_info_t)&vmStats,
                                               &infoCount);
    
    if (kernReturn != KERN_SUCCESS) {
        return [NSString stringWithFormat:@"%ld",(long)NSNotFound];
    }
    return [NSString stringWithFormat:@"%f",((vm_page_size *vmStats.free_count) / 1024.0) / 1024.0];
}

+ (NSString *)totalSize {
    /// 总大小
    float totalsize = 0.0;
    
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    if (dictionary) {

        NSNumber *_total = [dictionary objectForKey:NSFileSystemSize];
        totalsize = [_total unsignedLongLongValue]*1.0/(1024);
    } else {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }
    return [NSString stringWithFormat:@"%f",totalsize/1024/1024/1024];
}

+ (NSString *)freeSize {
    /// 剩余大小
    float freesize = 0.0;
    
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    if (dictionary) {
        NSNumber *_free = [dictionary objectForKey:NSFileSystemFreeSize];
        freesize = [_free unsignedLongLongValue]*1.0/(1024);
    } else {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }
    return [NSString stringWithFormat:@"%f",freesize/1024];
}

+ (NSString *)curpower {
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    double deviceLevel = [UIDevice currentDevice].batteryLevel;
    return [NSString stringWithFormat:@"%.2f",deviceLevel];
}

// 设备型号
+ (NSString *)getDeviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return deviceString;
}

// 设备型号
+ (NSString *)getSysInfoByName:(char *)typeSpecifier {
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    free(answer);
    return results;
}

// 是否在后台运行
+ (BOOL)inBackground {
    return [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
}

// 是否越狱
+ (BOOL)isJailBroken {
    static const char * __jb_app = NULL;
    static const char * __jb_apps[] = {
        "/Application/Cydia.app",
        "/Application/limera1n.app",
        "/Application/greenpois0n.app",
        "/Application/blackra1n.app",
        "/Application/blacksn0w.app",
        "/Application/redsn0w.app",
        NULL
    };
    __jb_app = NULL;
    for ( int i = 0; __jb_apps[i]; ++i ) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:__jb_apps[i]]]) {
            __jb_app = __jb_apps[i];
            return YES;
        }
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/lib/apt/"]) {
        return YES;
    }
    
    return NO;
}

// 是否破解
+ (BOOL)isPirated {
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    /* SC_Info */
    if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/SC_Info",bundlePath]]) {
        return YES;
    }
    /* iTunesMetadata.plist */
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/iTunesMetadata.plist",bundlePath]]) {
        return YES;
    }
    return NO;
}

// 分辨率
+ (NSString *)resolution {
    CGRect rect = [[UIScreen mainScreen] bounds];
    CGFloat scale = [[UIScreen mainScreen] scale];
    return [[NSString alloc] initWithFormat:@"%.fx%.f",rect.size.height*scale,rect.size.width*scale];
}

+ (NSString *)userAgent {
    //使用配置好的WKWebViewConfiguration，创建WKWebView
    WKWebView *webview  =[[WKWebView alloc]init];
    __block NSString *userAgent;
    [webview evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, NSError *error) {
        if (!error) {
            userAgent = result;
        } else {
            NSLog(@"userAgent error== %@",error);
        }
    }];
    
    return userAgent;
}


@end
