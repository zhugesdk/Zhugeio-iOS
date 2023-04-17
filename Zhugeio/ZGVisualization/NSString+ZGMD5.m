//
//  NSString+ZGMD5.m
//  ZGTestDemo
//
//  Created by 范奇 on 2023/2/23.
//

#import "NSString+ZGMD5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (ZGMD5)

- (NSString *)getZGSHA256Str
{
    //传入参数,转化成char
    const char *cStr = [self UTF8String];
    
    
    //开辟一个16字节的空间
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    /*
     extern unsigned char * CC_MD5(const void *data, CC_LONG len, unsigned char *md)官方封装好的加密方法
     把str字符串转换成了32位的16进制数列（这个过程不可逆转） 存储到了md这个空间中
     */
    CC_SHA256(cStr, (unsigned)strlen(cStr), result);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for( int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++ )
    {
        [output appendFormat:@"%02x", result[i]];
    }
    return output;
}


- (NSString *)getZGMD5Str
{
    //传入参数,转化成char
    const char *cStr = [self UTF8String];

    //开辟一个16字节的空间
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    /*
     extern unsigned char * CC_MD5(const void *data, CC_LONG len, unsigned char *md)官方封装好的加密方法
     把str字符串转换成了32位的16进制数列（这个过程不可逆转） 存储到了md这个空间中
     */
    CC_MD5(cStr, (unsigned)strlen(cStr), result);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for( int i = 0; i < CC_MD5_DIGEST_LENGTH; i++ )
    {
        [output appendFormat:@"%02x", result[i]];
    }
    return output;
}

@end
