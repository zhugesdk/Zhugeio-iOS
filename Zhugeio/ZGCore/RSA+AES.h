//
//  RSA+AES.h
//  ZhugeioAnanlytics
//
//  Created by GeGe on 2022/4/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RSA_AES : NSObject

/**
 * 随机生成16位aes加密的key
 */
+ (NSString *)randomly16BitString;

/**
 * rsa加密
 */
+ (NSString *)encryptUseRSA:(NSString *)str pubkey:(NSString *)pubkey;

/**
 * aes加密
 */
+ (NSString *)AES256Encrypt:(NSString *)plainText key:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
