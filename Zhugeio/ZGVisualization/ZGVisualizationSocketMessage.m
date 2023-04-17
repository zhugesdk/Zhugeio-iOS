//
//  ZGVisualizationSocketMessage.m
//  ZhugeioAnanlytics
//
//  Created by 范奇 on 2023/2/23.
//

#import "ZGVisualizationSocketMessage.h"

@implementation ZGVisualizationSocketMessage
{
    NSDictionary *_payload;
    NSDictionary *_otherDataDict;
}

/// 设置可视化 socket消息实例对象
/// - Parameters:
///   - type: 可视化socket 消息type
///   - otherData: 非payload与type的其他数据
///   - payload: payload包裹请求体
- (instancetype)initWithType:(NSString *)type otherData:(NSDictionary *)otherData andPayload:(NSDictionary *)payload
{
    _otherDataDict = otherData ? otherData : @{};
    return [self initWithType:type andPayload:payload];
}

- (instancetype)initWithType:(NSString *)type
{
    return [self initWithType:type andPayload:@{}];
}

- (instancetype)initWithType:(NSString *)type andPayload:(NSDictionary *)payload
{
    if (self = [super initWithType:type]) {
        _payload = payload ? payload : @{};
    }
    return self;
}

- (NSData *)JSONData
{
    NSMutableDictionary * jsonObject = [NSMutableDictionary dictionary];
    [jsonObject setObject:self.type forKey:@"type"];
    NSMutableDictionary * dataDict = [NSMutableDictionary dictionaryWithDictionary:_otherDataDict];
    [dataDict setObject:[_payload copy] forKey:@"payload"];
    [jsonObject setObject:[dataDict copy] forKey:@"data"];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:(NSJSONWritingOptions)0 error:&error];
    if (error) {
        NSLog(@"Failed to serialize test designer message: %@", error);
    }

    return jsonData;
}

@end
