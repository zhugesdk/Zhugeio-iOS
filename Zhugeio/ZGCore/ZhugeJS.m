//
//  ZhugeJS.m
//  HelloZhuge
//
//  Created by Zhugeio on 2016/10/18.
//  Copyright © 2016年 37degree. All rights reserved.
//

#import "ZhugeJS.h"
#import "Zhuge.h"
#import "ZhugeConfig.h"
#import "ZGLog.h"
@implementation ZhugeJS

-(void)track:(NSString *)eventName Property:(NSString *)pro{

    NSData *data = [pro dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSMutableDictionary *mutableJson = [json mutableCopy];
    mutableJson[@"env_type"] = @"js";
    NSString *key = [self getAppKey:mutableJson];
    if (key) {
        Zhuge *zhuge = [Zhuge getInstanceForKey:key];
        if (zhuge) {
            NSDictionary *eventPro = [self checkIfMergeAppSuperProToEventPro:mutableJson sdkInstance:zhuge];
            [zhuge track:eventName properties:eventPro];
        }
    } else {
        Zhuge *zhuge = [Zhuge sharedInstance];
        NSDictionary *eventPro = [self checkIfMergeAppSuperProToEventPro:mutableJson sdkInstance:zhuge];
        [zhuge track:eventName properties:eventPro];
    }

}

-(void)identify:(NSString *)uid Property:(NSString *)pro{
    NSData *data = [pro dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *json = [[NSJSONSerialization JSONObjectWithData:data options:0 error:nil] mutableCopy];
    NSString *key = [self getAppKey:json];
    if (key) {
        Zhuge *zhuge = [Zhuge getInstanceForKey:key];
        if (zhuge) {
            [zhuge identify:uid properties:json];
        }
    } else {
        Zhuge *zhuge = [Zhuge sharedInstance];
        [zhuge identify:uid properties:json];
    }
}

-(void)autoTrack:(NSString *)uid Property:(NSString *)pro{
    NSData *data = [pro dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSMutableDictionary *property = [NSMutableDictionary dictionary];
    if (json) {
        [property addEntriesFromDictionary:json];
    }
    [property setObject:uid forKey:@"$eid"];
    NSString *key = [self getAppKey:property];
    if (key) {
        Zhuge *zhuge = [Zhuge getInstanceForKey:key];
        if (zhuge) {
            [zhuge autoTrack:property];
        }
    } else {
        Zhuge *zhuge = [Zhuge sharedInstance];
        [zhuge autoTrack:property];
    }
}

- (void)trackRevenue:(NSString *)eventName Property:(NSString *)pro {
    
}

-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message replyHandler:(void (^)(id _Nullable, NSString * _Nullable))replyHandler{
    if ([@"zhugeTracker" isEqualToString:message.name]) {
        ZGLogInfo(@"H5传递消息：%@",message.body);
        NSDictionary *type = message.body;
        if (![type isKindOfClass:[NSDictionary class]] || ![type objectForKey:@"type"]) {
            ZGLogDebug(@"不合法的JS消息： %@",message.body);
            replyHandler(@"",nil);
            return;
        }
        if ([type[@"type"] isEqualToString:@"track"]) {
            NSString *name = [type valueForKey:@"name"];
            id prop = [type valueForKey:@"prop"];
            NSString *appKey = [self getAppKey: prop];
            if (appKey) {
                Zhuge *zhuge = [Zhuge getInstanceForKey:appKey];
                if (zhuge) {
                    NSDictionary *eventPro = [self checkIfMergeAppSuperProToEventPro:prop sdkInstance:zhuge];
                    [zhuge track:name properties:eventPro];
                } else {
                    ZGLogError(@"未初始化的appkey:%@",appKey);
                }
            } else if([self hasDefaultInstance]){
                NSDictionary *eventPro = [self checkIfMergeAppSuperProToEventPro:prop sdkInstance:[Zhuge sharedInstance]];
                [[Zhuge sharedInstance] track:name properties:eventPro];
            }
            replyHandler(@"",nil);
        }else if ([type[@"type"] isEqualToString:@"identify"]){
            NSString *name = [type valueForKey:@"name"];
            id prop = [type valueForKey:@"prop"];
            NSString *appKey = [self getAppKey: prop];
            if (appKey) {
                Zhuge *zhuge = [Zhuge getInstanceForKey:appKey];
                if (zhuge) {
                    [zhuge identify:name properties:prop];
                } else {
                    ZGLogError(@"未初始化的appkey:%@",appKey);
                }
            } else if([self hasDefaultInstance]){
                [[Zhuge sharedInstance] identify:name properties:prop];
            }
            replyHandler(@"",nil);
        }else if ([type[@"type"] isEqualToString:@"revenue"]) {
            
//            [[Zhuge sharedInstance] trackRevenue:nil];
            replyHandler(@"",nil);
        }else if([type[@"type"] isEqualToString:@"autoTrack"]){
            NSString *name = [type valueForKey:@"name"];
            id prop = [type valueForKey:@"prop"];
            NSMutableDictionary *property = [NSMutableDictionary dictionary];
            if (prop) {
                [property addEntriesFromDictionary:prop];
            }
            [property setObject:name forKey:@"$eid"];
            NSString *appKey = [self getAppKey: prop];
            if (appKey) {
                Zhuge *zhuge = [Zhuge getInstanceForKey:appKey];
                if (zhuge) {
                    [zhuge autoTrack: property];
                } else {
                    ZGLogError(@"未初始化的appkey:%@",appKey);
                }
            } else if([self hasDefaultInstance]){
                [[Zhuge sharedInstance] autoTrack: property];
            }
            replyHandler(@"",nil);
        }else if ([type[@"type"] isEqualToString:@"dr"]) {
            
            NSString *name = [type valueForKey:@"name"];
            id prop = [type valueForKey:@"prop"];
            NSMutableDictionary *property = [NSMutableDictionary dictionary];
            if (prop) {
                [property addEntriesFromDictionary:prop];
            }
            [property setObject:name forKey:@"$eid"];
            NSString *appKey = [self getAppKey: prop];
            if (appKey) {
                Zhuge *zhuge = [Zhuge getInstanceForKey:appKey];
                if (zhuge) {
                    [zhuge trackDurationOnPage: property];
                } else {
                    ZGLogError(@"未初始化的appkey:%@",appKey);
                }
            } else if([self hasDefaultInstance]){
                [[Zhuge sharedInstance] trackDurationOnPage: property];
            }
            replyHandler(@"",nil);
        }else if ([type[@"type"] isEqualToString:@"getVersion"]){
            NSString *version = ZG_SDK_VERSION;
            replyHandler(version,nil);
        } else{
            replyHandler(@"",nil);
            ZGLogError(@"未识别的JS消息类型： %@",message.body);
        }
    }
    
}

-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    if ([@"zhugeTracker" isEqualToString:message.name]) {
        ZGLogInfo(@"H5传递消息：%@",message.body);
        NSDictionary *type = message.body;
        if (![type isKindOfClass:[NSDictionary class]] || ![type objectForKey:@"type"]) {
            ZGLogDebug(@"不合法的JS消息： %@",message.body);
            return;
        }
        if ([type[@"type"] isEqualToString:@"track"]) {
            NSString *name = [type valueForKey:@"name"];
            id prop = [type valueForKey:@"prop"];
            NSString *appKey = [self getAppKey: prop];
            if (appKey) {
                Zhuge *zhuge = [Zhuge getInstanceForKey:appKey];
                if (zhuge) {
                    NSDictionary *eventPro = [self checkIfMergeAppSuperProToEventPro:prop sdkInstance:zhuge];
                    [zhuge track:name properties:eventPro];
                } else {
                    ZGLogError(@"未初始化的appkey:%@",appKey);
                }
            } else if([self hasDefaultInstance]){
                NSDictionary *eventPro = [self checkIfMergeAppSuperProToEventPro:prop sdkInstance:[Zhuge sharedInstance]];
                [[Zhuge sharedInstance] track:name properties:eventPro];
            }
        }else if ([type[@"type"] isEqualToString:@"identify"]){
            NSString *name = [type valueForKey:@"name"];
            id prop = [type valueForKey:@"prop"];
            NSString *appKey = [self getAppKey: prop];
            if (appKey) {
                Zhuge *zhuge = [Zhuge getInstanceForKey:appKey];
                if (zhuge) {
                    [zhuge identify:name properties:prop];
                } else {
                    ZGLogError(@"未初始化的appkey:%@",appKey);
                }
            } else if([self hasDefaultInstance]){
                [[Zhuge sharedInstance] identify:name properties:prop];
            }
        }else if ([type[@"type"] isEqualToString:@"revenue"]) {
            
//            [[Zhuge sharedInstance] trackRevenue:nil];
        }else if([type[@"type"] isEqualToString:@"autoTrack"]){
            NSString *name = [type valueForKey:@"name"];
            id prop = [type valueForKey:@"prop"];
            NSMutableDictionary *property = [NSMutableDictionary dictionary];
            if (prop) {
                [property addEntriesFromDictionary:prop];
            }
            [property setObject:name forKey:@"$eid"];
            NSString *appKey = [self getAppKey: prop];
            if (appKey) {
                Zhuge *zhuge = [Zhuge getInstanceForKey:appKey];
                if (zhuge) {
                    [zhuge autoTrack: property];
                } else {
                    ZGLogError(@"未初始化的appkey:%@",appKey);
                }
            } else if([self hasDefaultInstance]){
                [[Zhuge sharedInstance] autoTrack: property];
            }
        }else if ([type[@"type"] isEqualToString:@"dr"]) {
            
            NSString *name = [type valueForKey:@"name"];
            id prop = [type valueForKey:@"prop"];
            NSMutableDictionary *property = [NSMutableDictionary dictionary];
            if (prop) {
                [property addEntriesFromDictionary:prop];
            }
            [property setObject:name forKey:@"$eid"];
            NSString *appKey = [self getAppKey: prop];
            if (appKey) {
                Zhuge *zhuge = [Zhuge getInstanceForKey:appKey];
                if (zhuge) {
                    [zhuge trackDurationOnPage: property];
                } else {
                    ZGLogError(@"未初始化的appkey:%@",appKey);
                }
            } else if([self hasDefaultInstance]){
                [[Zhuge sharedInstance] trackDurationOnPage: property];
            }
        }else if ([type[@"type"] isEqualToString:@"getVersion"]){
        } else{
            ZGLogError(@"未识别的JS消息类型： %@",message.body);
        }
    }
}

-(NSString *)getAppKey:(NSMutableDictionary *)dic{
    NSString *appKey =  [dic objectForKey:@"appKey"];
    if (appKey) {
        [dic removeObjectForKey:@"appKey"];
    }
    return appKey;
}

-(NSDictionary *)checkIfMergeAppSuperProToEventPro:(NSDictionary *)dic sdkInstance:(Zhuge *)sdk{
    if (!sdk.config.overwriteH5ProWithAppSuperPro) {
        return dic;
    }
    if (![dic isKindOfClass:[NSDictionary class]]) {
        return [NSDictionary dictionary];
    }
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:dic];
    NSDictionary *superPro = [sdk getSuperProperties];
    [result addEntriesFromDictionary:superPro];
    return result;
}
-(BOOL)hasDefaultInstance{
    return [[Zhuge allInstance] containsObject:[Zhuge sharedInstance]];
}
@end
