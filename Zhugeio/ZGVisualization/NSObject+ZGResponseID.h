//
//  NSObject+ZGResponseID.h
//  ZGTestDemo
//
//  Created by 范奇 on 2023/2/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ZGResponseID)

// 响应的标识id
@property (nonatomic, copy) NSString *zg_responseID;

@end

NS_ASSUME_NONNULL_END
