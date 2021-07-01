//
//  WKWebView+ZABridge.m
//  AFNetworking
//
//  Created by Good_Morning_ on 2021/4/20.
//

#import "WKWebView+ZABridge.h"
#import "Zhuge.h"

@implementation WKWebView (ZABridge)

- (WKNavigation *)zhugeio_loadRequest:(NSURLRequest *)request {
    [[Zhuge sharedInstance] addScriptMessageHandlerWithWebView:self];
    
    return [self zhugeio_loadRequest:request];
}

- (WKNavigation *)zhugeio_loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL {
    [[Zhuge sharedInstance] addScriptMessageHandlerWithWebView:self];
    
    return [self zhugeio_loadHTMLString:string baseURL:baseURL];
}

- (WKNavigation *)zhugeio_loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL {
    [[Zhuge sharedInstance] addScriptMessageHandlerWithWebView:self];
    
    return [self zhugeio_loadFileURL:URL allowingReadAccessToURL:readAccessURL];
}

- (WKNavigation *)zhugeio_loadData:(NSData *)data MIMEType:(NSString *)MIMEType characterEncodingName:(NSString *)characterEncodingName baseURL:(NSURL *)baseURL {
    [[Zhuge sharedInstance] addScriptMessageHandlerWithWebView:self];
    
    return [self zhugeio_loadData:data MIMEType:MIMEType characterEncodingName:characterEncodingName baseURL:baseURL];
}


@end
