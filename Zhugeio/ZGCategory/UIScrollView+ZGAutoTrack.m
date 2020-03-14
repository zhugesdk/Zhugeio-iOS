//
//  UIScrollView+ZGAutoTrack.m
//  HelloZhuge
//
//  Created by Good_Morning_ on 2019/12/31.
//  Copyright © 2019 37degree. All rights reserved.
//

#import "UIScrollView+ZGAutoTrack.h"
#import "ZGRuntimeHelper.h"
#import "UITableView+ZGAutoTrack.h"
#import "UICollectionView+ZGAutoTrack.h"


// return sel
#define GET_CLASS_CUSTOM_SEL(sel,class)  NSSelectorFromString([NSString stringWithFormat:@"%@_%@",NSStringFromClass(class),NSStringFromSelector(sel)])

@implementation UIScrollView (ZGAutoTrack)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self sel_exchangeFirstSel:@selector(setDelegate:) secondSel:@selector(zhuge_setDelegate:)];
    });
}

- (void)zhuge_setDelegate:(id<UIScrollViewDelegate>)delegate {
    
    if (![self isContainSel:GET_CLASS_CUSTOM_SEL(@selector(scrollViewWillBeginDragging:),[delegate class]) inClass:[delegate class]]) {
        [self swizzling_scrollViewWillBeginDragging:delegate];
    }
    
    if (![self isContainSel:GET_CLASS_CUSTOM_SEL(@selector(scrollViewDidEndDecelerating:),[delegate class]) inClass:[delegate class]]) {
        [self swizzling_scrollViewWillBeginDragging:delegate];
    }
    
    if ([self isKindOfClass:[UITableView class]]){
        if (![self isContainSel:GET_CLASS_CUSTOM_SEL(@selector(tableView:didSelectRowAtIndexPath:),[delegate class]) inClass:[delegate class]]) {
            [(UITableView *)self zhugeAutoTrack_tableViewDidSelectRowIndexPathInClass:delegate];
        }

    }

    if ([self isKindOfClass:[UICollectionView class]]){
        if (![self isContainSel:GET_CLASS_CUSTOM_SEL(@selector(collectionView:didSelectItemAtIndexPath:),[delegate class]) inClass:[delegate class]]) {
            [(UICollectionView *)self zhugeAutoTrack_collectionViewDidSelectItemIndexPathInClass:delegate];
        }
    }
    
    [self zhuge_setDelegate:delegate];
}

- (void)swizzling_scrollViewWillBeginDragging:(id<UIScrollViewDelegate>)delegate {
    // 为每个含tableView 和 collectionView的控件 增加swizzle delegate method
    [self class_addMethod:[delegate class]
                 selector:GET_CLASS_CUSTOM_SEL(@selector(scrollViewWillBeginDragging:),[delegate class])
                      imp:method_getImplementation(class_getInstanceMethod([self class],@selector(zhuge_scrollViewWillBeginDragging:)))
                    types:"v@:@"];

    // 检查页面是否已经实现了origin delegate method  如果没有手动加一个
    if (![self isContainSel:@selector(scrollViewWillBeginDragging:) inClass:[delegate class] ]) {
        [self class_addMethod:[delegate class]
                     selector:@selector(scrollViewWillBeginDragging:)
                          imp:nil
                        types:"v@"];
    }
    // 将swizzle delegate method 和 origin delegate method 交换
    [self sel_exchangeClass:[delegate class]
                   FirstSel:@selector(scrollViewWillBeginDragging:)
                  secondSel:GET_CLASS_CUSTOM_SEL(@selector(scrollViewWillBeginDragging:),[delegate class])];
}


/**
 swizzle method IMP
 @param scrollView scrollView description
 */
- (void)zhuge_scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    SEL sel = GET_CLASS_CUSTOM_SEL(@selector(scrollViewWillBeginDragging:),[self class]);
    if ([self respondsToSelector:sel]) {
        IMP imp = [self methodForSelector:sel];
        void (*func)(id, SEL,id) = (void *)imp;
        func(self, sel,scrollView);
    }
}

@end
