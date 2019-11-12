//
//  ZhugeJS.m
//  HelloZhuge
//
//  Created by jiaokang on 2016/10/18.
//  Copyright © 2016年 37degree. All rights reserved.
//

#import "ZhugeJS.h"
#import "Zhuge.h"
#import "ZGLog.h"
@implementation ZhugeJS

-(void)track:(NSString *)eventName Property:(NSString *)pro{

    Zhuge *zhuge = [Zhuge sharedInstance];
    NSData *data = [pro dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSMutableDictionary *mutableJson = [json mutableCopy];
    mutableJson[@"env_type"] = @"js";
    [zhuge track:eventName properties:mutableJson];

}

-(void)identify:(NSString *)uid Property:(NSString *)pro{
    
    Zhuge *zhuge = [Zhuge sharedInstance];
    NSData *data = [pro dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

    [zhuge identify:uid properties:json];
}
-(void)autoTrack:(NSString *)uid Property:(NSString *)pro{
    Zhuge *zhuge = [Zhuge sharedInstance];
    NSData *data = [pro dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSMutableDictionary *property = [NSMutableDictionary dictionary];
    if (json) {
        [property addEntriesFromDictionary:json];
    }
    [property setObject:uid forKey:@"$eid"];
    [zhuge autoTrack:property];
}

-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{

    if ([@"zhugeTracker" isEqualToString:message.name]) {
        ZhugeDebug(@"H5传递消息：%@",message.body);
        NSDictionary *type = message.body;
        if (![type isKindOfClass:[NSDictionary class]] || ![type objectForKey:@"type"]) {
            ZhugeDebug(@"不合法的JS消息： %@",message.body);
            return;
        }
        if ([type[@"type"] isEqualToString:@"track"]) {
            NSString *name = [type valueForKey:@"name"];
            id prop = [type valueForKey:@"prop"];
            [[Zhuge sharedInstance] track:name properties:prop];
        }else if ([type[@"type"] isEqualToString:@"identify"]){
            NSString *name = [type valueForKey:@"name"];
            id prop = [type valueForKey:@"prop"];
            [[Zhuge sharedInstance] identify:name properties:prop];
        }else if([type[@"type"] isEqualToString:@"autoTrack"]){
            NSString *name = [type valueForKey:@"name"];
            Zhuge *zhuge = [Zhuge sharedInstance];
            id prop = [type valueForKey:@"prop"];
            NSMutableDictionary *property = [NSMutableDictionary dictionary];
            if (prop) {
                [property addEntriesFromDictionary:prop];
            }
            [property setObject:name forKey:@"$eid"];
            [zhuge autoTrack:property];
        } else{
            ZhugeDebug(@"未识别的JS消息类型： %@",message.body);
        }
    }
}
@end
