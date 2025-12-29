//
//  WKWebView+ZABridge.h
//  AFNetworking
//
//  Created by Good_Morning_ on 2021/4/20.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (ZABridge)

- (WKNavigation *)zhugeio_loadRequest:(NSURLRequest *)request;

- (WKNavigation *)zhugeio_loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL;

- (WKNavigation *)zhugeio_loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL;

- (WKNavigation *)zhugeio_loadData:(NSData *)data MIMEType:(NSString *)MIMEType characterEncodingName:(NSString *)characterEncodingName baseURL:(NSURL *)baseURL;

@end

NS_ASSUME_NONNULL_END
