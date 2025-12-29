//
//  ZGRequest.m
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2020/8/14.
//  Copyright © 2020 GoodMorning. All rights reserved.
//

#import "ZGRequest.h"

@implementation ZGRequest

+ (void)postRequestWithApi:(NSString *)url backupUrl:(NSString *)backupUrl parameters:(NSString *)parameters callback:(CompletionBlock)callback {

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setHTTPMethod:@"POST"];
    NSString * urlString = [parameters stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"#%<>[\\]^`{|}\"]+"].invertedSet];
    [request setHTTPBody:[urlString dataUsingEncoding:NSUTF8StringEncoding]];
    request.timeoutInterval =30;
        
    //使用全局的会话
    NSURLSession *session = [NSURLSession sharedSession];
    // 通过request初始化task
    NSURLSessionTask *task = [session dataTaskWithRequest:request
                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSLog(@"result == %@", [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil]);
     }];
    
    [task resume];
//        NSURLResponse *urlResponse = nil;
//        NSError *reqError = nil;
//        responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&reqError];
//        if (reqError) {
//            ZGLogDebug(@"error : %@",reqError);
//            retry++;
//            continue;
//        }
//        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) urlResponse;
//        NSInteger code = [httpResponse statusCode];
//        if (code == 200 && responseData != nil) {
//            NSString *response = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
//            ZGLogDebug(@"API响应: %@",response);
//            success = YES;
//        }else{
//            retry++;
//        }
}


+ (void)getRequestWithApi:(NSString *)url backupUrl:(NSString *)backupUrl parameters:(NSString *)parameters callback:(CompletionBlock)callback {
    
}

+ (void)requestData:(NSString *)url {
    
}

@end
