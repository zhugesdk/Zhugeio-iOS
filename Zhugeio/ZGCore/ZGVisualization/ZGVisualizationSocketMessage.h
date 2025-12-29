//
//  ZGVisualizationSocketMessage.h
//  ZhugeioAnanlytics
//
//  Created by 范奇 on 2023/2/23.
//

#import "ZGAbstractABTestDesignerMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZGVisualizationSocketMessage : ZGAbstractABTestDesignerMessage

/*
 
 普通消息: type5
 {
  "event": "pageData",
  "type":5,
  "payload":{
              "key1":"value1",
              "key2":"value2"
              "base64Data":"xxxxxxxxxxxxxxxxxxxxxxxxxxx"
              }
 }
 
 */


/// 设置可视化 socket消息实例对象
/// - Parameters:
///   - type: 可视化socket 消息type
///   - otherData: 非payload与type的其他数据
///   - payload: payload包裹请求体
- (instancetype)initWithType:(NSString *)type otherData:(NSDictionary *)otherData andPayload:(NSDictionary *)payload;

@end

NS_ASSUME_NONNULL_END
