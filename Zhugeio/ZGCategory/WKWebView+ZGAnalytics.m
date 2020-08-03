//
//  WKWebView+ZGAnalytics.m
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2020/5/14.
//  Copyright © 2020 GoodMorning. All rights reserved.
//

#import "WKWebView+ZGAnalytics.h"

#import <objc/runtime.h>
#import "Zhuge.h"
#import "Aspects.h"
#import "ZGUtils.h"

static CFAbsoluteTime _start;
static CFAbsoluteTime _end;

@implementation WKWebView (ZGAnalytics)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(setNavigationDelegate:);
        SEL swizzledSelector = @selector(zg_setNavigationDelegate:);
        //原有方法
        Method originalMethod = class_getInstanceMethod(self, originalSelector);
        //替换原有方法的新方法
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
        //先尝试給源SEL添加IMP，这里是为了避免源SEL没有实现IMP的情况
        BOOL didAddMethod = class_addMethod(self,originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));
        if (didAddMethod) {//添加成功：表明源SEL没有实现IMP，将源SEL的IMP替换到交换SEL的IMP
            class_replaceMethod(self,swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {//添加失败：表明源SEL已经有IMP，直接将两个SEL的IMP交换即可
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)zg_setNavigationDelegate:(id<WKNavigationDelegate>)delegate {
    [self zg_setNavigationDelegate:delegate];
    
    NSObject *obg = (NSObject *)delegate;
    if(![obg isKindOfClass:[NSObject class]]){
        return;
    }
    SEL sel = @selector(webView:didFinishNavigation:);
    [obg aspect_hookSelector:sel withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo){
        NSArray *arr = aspectInfo.arguments;
        if(arr.count>1){
            [self zg_webView:arr[0] didFinishNavigation:arr[1]];
        }
    } error:nil];
    
    SEL didStarSel = @selector(webView:didStartProvisionalNavigation:);
    [obg aspect_hookSelector:didStarSel withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo){
        NSArray *arr = aspectInfo.arguments;
        if(arr.count>1){
            [self zg_webView:arr[0] didStartProvisionalNavigation:arr[1]];
        }
    } error:nil];
    
}

// 判断链接是否允许跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction     decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {

}

// 拿到响应后决定是否允许跳转

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {

}

// 链接开始加载时调用
- (void)zg_webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if ([Zhuge sharedInstance].config.enableWebViewTrack == YES) {
        _start = CFAbsoluteTimeGetCurrent();
    }
    
}

// 收到服务器重定向时调用
- (void)zg_webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {

}

// 加载错误时调用
- (void)zg_webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    
}

// 当内容开始到达主帧时被调用（即将完成）
- (void)zg_webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {

}

// 加载完成
- (void)zg_webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if ([Zhuge sharedInstance].config.enableWebViewTrack == YES) {
        _end = CFAbsoluteTimeGetCurrent();
        [self trackWebViewPV:webView loadingTime:[NSString stringWithFormat:@"%0.3f",_end - _start]];
    }
}

// 在提交的主帧中发生错误时调用
- (void)zg_webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {

}

// 当webView需要响应身份验证时调用(如需验证服务器证书)
- (void)zg_webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge    completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable   credential))completionHandler {
    
}

// 当webView的web内容进程被终止时调用。(iOS 9.0之后)
- (void)zg_webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    
}


- (void)trackWebViewPV:(WKWebView *)webview loadingTime:(NSString *)loadingTime{
    Zhuge * zhuge = [Zhuge sharedInstance];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:@"pv" forKey:@"$eid"];
    [data setObject:isNil(webview.URL) forKey:@"$url"];
    [data setObject:isNil(webview.title) forKey:@"$page_title"];
//    [data setObject:isNil(zhuge.ref) forKey:@"$ref"];
    [data setObject:isNil(loadingTime) forKey:@"loading_time"];
    [zhuge autoTrack:data];
}



@end
