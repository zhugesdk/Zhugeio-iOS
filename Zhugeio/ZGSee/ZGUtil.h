//
//  ZGUtil.h
//  HelloZhuge
//
//  Created by jiaokang on 2018/9/6.
//  Copyright © 2018年 37degree. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface ZGUtil : NSObject

// RSA加密
+ (NSString *)encryptString:(NSString *)str publicKey:(NSString *)pubKey;

/**
 *  AES128加密
 *
 *  @param plainText 原文
 *
 *  @return 加密好的字符串
 */
+ (NSString *)AES128Encrypt:(NSData *)plainText sesKey:(NSString *)aesKey;
/**
 *  AES128解密
 *
 *  @param encryptText 密文
 *
 *  @return 明文
 */
+ (NSString *)AES128Decrypt:(NSData *)encryptText sesKey:(NSString *)aesKey;

@end
