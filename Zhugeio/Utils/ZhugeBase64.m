//
//  ZhugeBase64.m
//  HelloZhuge
//
//  Created by 郭超 on 2017/11/22.
//  Copyright © 2017年 37degree. All rights reserved.
//

#import "ZhugeBase64.h"


#pragma GCC diagnostic ignored "-Wselector"


#import <Availability.h>
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


@implementation NSData (ZhugeBase64)

+ (NSData *)zgDataWithBase64EncodedString:(NSString *)string {
    if (![string length]) return nil;
    
    NSData *decoded = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    
#if __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_9 || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    
    if (![NSData instancesRespondToSelector:@selector(initWithBase64EncodedString:options:)]) {
        decoded = [[self alloc] initWithBase64Encoding:[string stringByReplacingOccurrencesOfString:@"[^A-Za-z0-9+/=]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [string length])]];
    } else
        
#endif
        
{
        decoded = [[self alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    
    return [decoded length]? decoded: nil;
}

- (NSString *)zgBase64EncodedStringWithWrapWidth:(NSUInteger)wrapWidth {
    if (![self length]) return nil;
    
    NSString *encoded = nil;
    
#if __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_9 || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    
    if (![NSData instancesRespondToSelector:@selector(base64EncodedStringWithOptions:)])
    {
        encoded = [self base64Encoding];
    }
    else
        
#endif
#pragma clang diagnostic pop
        
    {
        switch (wrapWidth)
        {
            case 64:
            {
                return [self base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            }
            case 76:
            {
                return [self base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
            }
            default:
            {
                encoded = [self base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
            }
        }
    }
    
    if (!wrapWidth || wrapWidth >= [encoded length])
    {
        return encoded;
    }
    
    wrapWidth = (wrapWidth / 4) * 4;
    NSMutableString *result = [NSMutableString string];
    for (NSUInteger i = 0; i < [encoded length]; i+= wrapWidth)
    {
        if (i + wrapWidth >= [encoded length])
        {
            [result appendString:[encoded substringFromIndex:i]];
            break;
        }
        [result appendString:[encoded substringWithRange:NSMakeRange(i, wrapWidth)]];
        [result appendString:@"\r\n"];
    }
    
    return result;
}

- (NSString *)zgBase64EncodedString
{
    return [self zgBase64EncodedStringWithWrapWidth:0];
}

@end


@implementation NSString (ZhugeBase64)

+ (NSString *)zgStringWithBase64EncodedString:(NSString *)string
{
    NSData *data = [NSData zgDataWithBase64EncodedString:string];
    if (data)
    {
        return [[self alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (NSString *)zgBase64EncodedStringWithWrapWidth:(NSUInteger)wrapWidth
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    return [data zgBase64EncodedStringWithWrapWidth:wrapWidth];
}

- (NSString *)zgBase64EncodedString
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    return [data zgBase64EncodedString];
}

- (NSString *)zgBase64DecodedString
{
    return [NSString zgStringWithBase64EncodedString:self];
}

- (NSData *)zgBase64DecodedData
{
    return [NSData zgDataWithBase64EncodedString:self];
}

@end

