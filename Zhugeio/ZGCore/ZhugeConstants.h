//
//  ZhugeConstants.h
//  HelloZhuge
//
//  Created by Good_Morning_ on 2020/1/2.
//  Copyright © 2020 37degree. All rights reserved.
//

#ifndef ZhugeConstants_h
#define ZhugeConstants_h

#pragma mark - URL

static NSString *const ZG_BASE_API = @"https://u.zhugeapi.com";
static NSString *const ZG_BACKUP_API = @"https://ubak.zhugeio.com";


#pragma mark - NSUserDefault KEY
static NSString *const ZG_LAST_SESSIONID = @"ZGLastSessionId";


#pragma mark - 推送
// 支持的第三方推送渠道
typedef enum {
    ZG_PUSH_CHANNEL_XIAOMI = 1, // 小米
    ZG_PUSH_CHANNEL_JPUSH = 2,  // 极光推送
    ZG_PUSH_CHANNEL_UMENG = 3,  // 友盟
    ZG_PUSH_CHANNEL_BAIDU = 4,  // 百度云推送
    ZG_PUSH_CHANNEL_XINGE = 5,  // 信鸽
    ZG_PUSH_CHANNEL_GETUI = 6   // 个推
} ZGPushChannel;



#pragma mark - Codeless

static NSString *const CODELESS_WEB_SOCKET_URL = @"ws://codeless.zhugeio.com";
static NSString *const CODELESS_GET_EVENTS_URL = @"https://api.zhugeio.com";


#pragma mark - webview bridge name

static NSString *const ZA_SCRIPT_MESSAGE_HANDLER_NAME = @"zhugeTracker";


#endif /* ZhugeConstants_h */
