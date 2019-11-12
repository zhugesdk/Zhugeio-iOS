//
//  ZhugeCompres.m
//  HelloZhuge
//
//  Created by 郭超 on 2017/11/22.
//  Copyright © 2017年 37degree. All rights reserved.
//

#import "ZhugeCompres.h"
#import "zlib.h"
#import <Foundation/Foundation.h>

@implementation NSData (ZhugeCompres)
- (NSData *)zgZlibDeflate {
    if ([self length] == 0) return self;
    
    z_stream strm;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconversion"
    
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef *)[self bytes];
#pragma clang diagnostic ignored "-Wshorten-64-to-32"
    strm.avail_in = [self length];
    
    // Compresssion Levels:
    //   Z_NO_COMPRESSION
    //   Z_BEST_SPEED
    //   Z_BEST_COMPRESSION
    //   Z_DEFAULT_COMPRESSION
    
    if (deflateInit(&strm, Z_DEFAULT_COMPRESSION) != Z_OK) return nil;
    
    NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chuncks for expansion
    
    do {
        
        if (strm.total_out >= [compressed length])
            [compressed increaseLengthBy: 16384];
        
        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = [compressed length] - strm.total_out;
        
        deflate(&strm, Z_FINISH);
        
    } while (strm.avail_out == 0);
    
    deflateEnd(&strm);
#pragma clang diagnostic pop
    [compressed setLength: strm.total_out];
    return [NSData dataWithData: compressed];
}

@end

