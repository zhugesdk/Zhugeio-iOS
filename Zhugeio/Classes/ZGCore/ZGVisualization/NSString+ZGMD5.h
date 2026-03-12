//
//  NSString+ZGMD5.h
//  ZGTestDemo
//
//  Created by 范奇 on 2023/2/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (ZGMD5)

- (NSString *)getZGSHA256Str;

- (NSString *)getZGMD5Str;
@end

NS_ASSUME_NONNULL_END
