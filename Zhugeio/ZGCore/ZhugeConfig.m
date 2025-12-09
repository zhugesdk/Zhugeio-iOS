#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif
//
//  ZhugeConfig.m
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import "ZhugeConfig.h"
#import "ZhugeConstants.h"
#import "ZGUtils.h"
#import "ZGLog.h"


@implementation ZhugeConfig{
    NSString *uploadUrl;
    NSString *uploadBackupUrl;
}

- (instancetype)init {
    if (self = [super init]) {
        self.sdkVersion = ZG_SDK_VERSION;
        self.appVersion = ZG_APP_VERSION;
        self.appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        self.channel = ZG_CHANNEL;
        self.sendInterval = 10;
        self.limitCount = 1;
        self.sendMaxSizePerDay = 50000;
        self.cacheMaxSize = 3000;
        self.sessionEnable = YES;
        self.exceptionTrack = NO;
        self.debug = NO;
        self.autoTrackEnable = NO;
        self.isEnableDurationOnPage = NO;
        self.isEnableExpTrack = NO;
        self.enableVisualization = NO;
        self.debugVisualizationTime = 2;
        self.enableJavaScriptBridge = NO;
        self.overwriteH5ProWithAppSuperPro = NO;
//        self.enableLoger = NO;
        self.serverPolicy = -1;
        self.uploadPubkey = @"-----BEGIN PUBLIC KEY-----\nMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA5FhCfmlBx2dlDoAs9U9WgnFd4BXbPJoT52ptYB1t6zcxpv3bYzRrUvEqy0utrrUqkJPCGR5rFG+K4ph2ywoz9VpdjAyEFeAmik7nGgd0AxhJK9Vjl2GsEsJ7FBoHkDLbXdiDOnJflvPXlqfOwte+Tr4tZAUVm2PYGbVlgwQdUlM/dLPmPpRp5wVauv+waLBPcIVBMgNPl9xUqU4KLCtMj/OzHetdJEWMM3bk3s1TpgE8fR+T+63RvQ4ydveC/do2NIFqK2NoO7dIE5YFUwh0ImVV7nDZkgGYu/+i9/6zN4H4GqUKfSRMEhj7EsR3iMVkLVhC1LXfTxeHgHWRL8mVhi7s/SF2E+UDghBleW1/iQbCj3VVypjGBTIdp1kTfNrEJSEtsirnzqMDZRKVsocd4RMb/rLsYmI8VlUNZJSI0Vqr6ywH1mFM92lqzH1y2H4RGVkpbUqmfUiH3aCzRsN271im26vV16XU7LDSPqMr4l4P9sOszo6YwyC/6cXZduzlAgMBAAE=\n-----END PUBLIC KEY-----";
        self.uploadSM2Pubkey = @"-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoEcz1UBgi0DQgAEHgm0RcgI0rl/8B8xj3hWcvrBfwOvwpwlmwVI1/OtbGYZ5wQ1Xs6wJyFiImKjbd3sLTfOpl2ZDVTgwKaaGG5iZQ==\n-----END PUBLIC KEY-----";
        self.businessKey = nil;
        uploadUrl = [NSString stringWithFormat:@"%@/%@",ZG_BASE_API,@"apipool"];
        uploadBackupUrl = [NSString stringWithFormat:@"%@/%@",ZG_BACKUP_API,@"apipool" ];
        self.visualWebsocketUrl = @"wss://saas.zhugeio.com";
        self.visualEventUrl = @"https://saas.zhugeio.com";
        self.enableEncrypt = NO;
        self.encryptType = 1;
    }
    
    return self;
}
- (NSString *) description {
    return [NSString stringWithFormat: @"\n{\nsdkVersion=%@,\nappName = %@,\nappVersion=%@,\nchannel=%@,\nsendInterval=%lu,\nlimitCount=%lu,\nsendMaxSizePerDay=%lu,\ncacheMaxSize=%lu,\nsessionEnable=%@,\ndebug=%@,\nexceptionTrack=%@}", _sdkVersion, _appName,_appVersion, _channel, (unsigned long)_sendInterval, (unsigned long)_limitCount,(unsigned long)_sendMaxSizePerDay, (unsigned long)_cacheMaxSize, _sessionEnable?@"YES":@"NO",_debug?@"YES":@"NO",_exceptionTrack?@"YES":@"NO"];
}
- (void)enableEncryptUpload:(BOOL)encrypt CryptoType:(int)cryptoType {
    self.enableEncrypt = encrypt;
    self.encryptType = cryptoType;
}
-(void)setUploadURL:(NSString *)url andBackupUrl:(NSString *)backupUrl{
    if (!url || url.length == 0) {
        ZGLogError(@"setUploadURL url is nil");
        return;
    }
    uploadUrl = url;
    if (backupUrl && backupUrl.length > 0) {
        uploadBackupUrl = backupUrl;
    } else {
        uploadBackupUrl = nil;
    }
}
-(void)setVisualWebsocketUrl:(NSString *)visualWebsocketUrl{
    if (!visualWebsocketUrl || visualWebsocketUrl.length == 0) {
        ZGLogError(@"setVisualWebsocketUrl is nil");
        return;
    }
    _visualWebsocketUrl = [ZGUtils parseUrl:visualWebsocketUrl];
}
-(void)setVisualEventUrl:(NSString *)visualEventUrl{
    if (!visualEventUrl || visualEventUrl.length == 0) {
        ZGLogError(@"setVisualEventUrl is nil");
        return;
    }
    _visualEventUrl = [ZGUtils parseUrl:visualEventUrl];
}
-(NSString*)getUploadUrl{
    return uploadUrl;
}
-(NSString*)getUploadBackupUrl{
    return uploadBackupUrl;
}

@end

