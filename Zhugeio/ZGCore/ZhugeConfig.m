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
        self.debug = NO;
        self.apsProduction = YES;
        self.exceptionTrack = NO;
        self.zgSeeEnable = NO;
        self.autoTrackEnable = NO;
        self.serverPolicy = -1;
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

