//
//  ZGNetworking.m
//  HelloZhuge
//
//  Created by Good_Morning_ on 2020/1/2.
//  Copyright © 2020 37degree. All rights reserved.
//

#import "ZGNetworking.h"

@implementation ZGNetworking


+ (void)requestWithUrl:(NSString *)url parameters:(NSString *)parameters method:(NSString *)method completionhandler:(void (^)(NSURLResponse * _Nonnull, NSData * _Nonnull, NSError * _Nonnull))complate {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];

    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    [request setHTTPMethod:method];
    
    NSString * urlString = [parameters stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"#%<>[\\]^`{|}\"]+"].invertedSet];
    [request setHTTPBody:[urlString dataUsingEncoding:NSUTF8StringEncoding]];
    
    request.timeoutInterval =30;
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        complate(response,data,error);
    }];
    
    [dataTask resume];
}


@end
