#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif
//
//  ZhugeConfig.m
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import "ZhugeConfig.h"

@implementation ZhugeConfig

- (instancetype)init {
    if (self = [super init]) {
        self.sdkVersion = ZG_SDK_VERSION;
        self.appVersion = ZG_APP_VERSION;
        self.appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        self.channel = ZG_CHANNEL;
        self.sendInterval = 10;
        self.sendMaxSizePerDay = 50000;
        self.cacheMaxSize = 3000;
        self.sessionEnable = YES;
        self.apsProduction = YES;
        self.serverPolicy = -1;
//        self.enableEncrypt = YES;
//        self.encryptType = 1;
        self.uploadPubkey = @"-----BEGIN PUBLIC KEY-----\nMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA5FhCfmlBx2dlDoAs9U9WgnFd4BXbPJoT52ptYB1t6zcxpv3bYzRrUvEqy0utrrUqkJPCGR5rFG+K4ph2ywoz9VpdjAyEFeAmik7nGgd0AxhJK9Vjl2GsEsJ7FBoHkDLbXdiDOnJflvPXlqfOwte+Tr4tZAUVm2PYGbVlgwQdUlM/dLPmPpRp5wVauv+waLBPcIVBMgNPl9xUqU4KLCtMj/OzHetdJEWMM3bk3s1TpgE8fR+T+63RvQ4ydveC/do2NIFqK2NoO7dIE5YFUwh0ImVV7nDZkgGYu/+i9/6zN4H4GqUKfSRMEhj7EsR3iMVkLVhC1LXfTxeHgHWRL8mVhi7s/SF2E+UDghBleW1/iQbCj3VVypjGBTIdp1kTfNrEJSEtsirnzqMDZRKVsocd4RMb/rLsYmI8VlUNZJSI0Vqr6ywH1mFM92lqzH1y2H4RGVkpbUqmfUiH3aCzRsN271im26vV16XU7LDSPqMr4l4P9sOszo6YwyC/6cXZduzlAgMBAAE=\n-----END PUBLIC KEY-----";
    }
    
    return self;
}
- (NSString *) description {
    return [NSString stringWithFormat: @"\n{\nsdkVersion=%@,\nappName = %@,\nappVersion=%@,\nchannel=%@,\nsendInterval=%lu,\nsendMaxSizePerDay=%lu,\ncacheMaxSize=%lu,\nsessionEnable=%@,\ndebug=%@,\nzgSeeEnable=%@,\ndevMode=%@,\nexceptionTrack=%@}", _sdkVersion, _appName,_appVersion, _channel, (unsigned long)_sendInterval, (unsigned long)_sendMaxSizePerDay, (unsigned long)_cacheMaxSize, _sessionEnable?@"YES":@"NO",_debug?@"YES":@"NO",_zgSeeEnable?@"YES":@"NO",_apsProduction?@"YES":@"NO",_exceptionTrack?@"YES":@"NO"];
}
-(BOOL)isSeeEnable{
    if (self.serverPolicy == -1) {
        return self.zgSeeEnable;
    }else{
        return self.serverPolicy == 0;
    }
}
@end

