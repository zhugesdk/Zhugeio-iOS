//
//  DLConfig.h
//  TestDeeplink
//
//  Created by johney.song on 15/2/28.
//  Copyright (c) 2015年 johney.song. All rights reserved.
//

#ifndef Deeplink_SDK_Config_h
#define Deeplink_SDK_Config_h

#define DOMAIN_UNIVERSAL_LINK   @"zhugeapi.com"
#define IDFA_DISABLE      @"IDFAdisable"

#define DL_PROD_ENV
//#define DL_STAGE_ENV
//#define DL_DEV_ENV

#ifdef DL_PROD_ENV
#define DL_API_BASE_URL        @"https://zhugeapi.com"
//#define DL_API_BASE_URL        @"http://42.159.133.35:8080"
#endif

#ifdef DL_STAGE_ENV
#define DL_API_BASE_URL        @"https://zhugeapi.com"
#endif

#ifdef DL_DEV_ENV
#define DL_API_BASE_URL        @"https://zhugeapi.com"
#endif

#define DL_API_VERSION         @"v2"

#endif

