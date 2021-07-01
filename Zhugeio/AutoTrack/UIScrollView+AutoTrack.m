//
//  UIScrollView+AutoTrack.m
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/4/12.
//

#import "UIScrollView+AutoTrack.h"
#import "ZADelegateProxy.h"

@implementation UITableView (AutoTrack)

- (void)zhugeio_setDelegate:(id <UITableViewDelegate>)delegate {
    [self zhugeio_setDelegate:delegate];

    if (self.delegate == nil) {
        return;
    }
    
    // 使用委托类去 hook 点击事件方法
    [ZADelegateProxy proxyWithDelegate:self.delegate];
}
    

@end

@implementation UICollectionView (AutoTrack)

- (void)zhugeio_setDelegate:(id<UICollectionViewDelegate>)delegate {
    [self zhugeio_setDelegate:delegate];
    
    if (self.delegate == nil) {
        return;
    }
    
    // 使用委托类去 hook 点击事件方法
    [ZADelegateProxy proxyWithDelegate:self.delegate];
    
}

@end


@implementation UIScrollView (AutoTrack)



@end
