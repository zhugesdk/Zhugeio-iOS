#ifndef ZGEncryptAvailability_h
#define ZGEncryptAvailability_h

#ifdef __has_include

// ------------------------------
// 1️⃣ Pod / Framework 模式
// ------------------------------
#if __has_include(<ZhugeioAnanlytics/GMEncrypt/GMSm4Utils.h>)
    #import <ZhugeioAnanlytics/GMEncrypt/GMSm4Utils.h>
    #import <ZhugeioAnanlytics/GMEncrypt/ZGGMSm2Utils.h>
    #import <ZhugeioAnanlytics/GMEncrypt/GMSm2Bio.h>
    #import <ZhugeioAnanlytics/GMEncrypt/GMSm3Utils.h>
    #import <ZhugeioAnanlytics/GMEncrypt/GMUtils.h>
    #import <ZhugeioAnanlytics/GMEncrypt/GMObjCDef.h>
    #define ZG_HAS_ENCRYPT_MODULE 1

// ------------------------------
// 2️⃣ 直接源码引入模式（相对路径）
// ------------------------------
#elif __has_include("GMSm4Utils.h")
    #import "GMSm4Utils.h"
    #import "ZGGMSm2Utils.h"
    #import "GMSm2Bio.h"
    #import "GMUtils.h"
    #import "GMSm3Utils.h"
    #import "GMObjCDef.h"
    #define ZG_HAS_ENCRYPT_MODULE 2

// ------------------------------
// 3️⃣ 模块不存在
// ------------------------------
#else
    #define ZG_HAS_ENCRYPT_MODULE 0

#endif

#else
// 不支持 __has_include 的旧编译器
#define ZG_HAS_ENCRYPT_MODULE 0
#endif

#endif /* ZGEncryptAvailability_h */
