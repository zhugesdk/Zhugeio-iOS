//
//  UICollectionView+ZGAnalytics.m
//  XSSuperDemo-OC
//
//  Created by Good_Morning_ on 2020/3/26.
//  Copyright © 2020 GoodMorning. All rights reserved.
//

#import "UICollectionView+ZGAnalytics.h"
#import <objc/runtime.h>
#import "Aspects.h"
#import "Zhuge.h"
#import "ZhugeAutoTrackUtils.h"

@implementation UICollectionView (ZGAnalytics)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(setDelegate:);
        SEL swizzledSelector = @selector(zg_setDelegate:);
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

- (void)zg_setDelegate:(id<UICollectionViewDelegate>)delegate {
    [self zg_setDelegate:delegate];
    if([NSStringFromClass([delegate class]) isEqualToString:@"TUICandidateGrid"]){
        return;
    }
    
    NSObject *obg = (NSObject *)delegate;
    if(![obg isKindOfClass:[NSObject class]]){
        return;
    }
    SEL sel = @selector(collectionView:didSelectItemAtIndexPath:);
    [obg aspect_hookSelector:sel withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo){
        NSArray *arr = aspectInfo.arguments;
        if(arr.count>1){
            [self zg_collectionView:arr[0] didSelectItemAtIndexPath:arr[1]];
        }
    } error:nil];
    
}

- (void)zg_collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([[Zhuge sharedInstance].config autoTrackEnable]) {
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        Zhuge * zhuge = [Zhuge sharedInstance];
        NSString *content = content = [ZhugeAutoTrackUtils zhugeGetViewContent:cell];;
        NSString *path = [ZhugeAutoTrackUtils zhugeGetViewPath:cell];
        NSString *type = @"UICollectionViewCell";
        
        UIViewController *realController = [ZhugeAutoTrackUtils zhugeGetViewControllerByView:cell];
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        NSString *url = @"";
        NSString *title = @"";
        if (realController) {
            url = NSStringFromClass(realController.class);
            if (realController.title) {
                title = realController.title;
            } else {
                title = [ZhugeAutoTrackUtils zhugeGetViewContent: realController.navigationItem.titleView];
            }
        }
    
        [data setObject:isNil(url) forKey:@"$url"];
        [data setObject:type forKey:@"$element_type"];
        [data setObject:isNil(path) forKey:@"$element_selector"];
        [data setObject:isNil(title) forKey:@"$page_title"];
        [data setObject:isNil(content) forKey:@"$element_content"];
        [data setObject:@"click" forKey:@"$eid"];
        [zhuge autoTrack:data];
    }
}

@end
