//
//  ZhugeAutoTrackUtils.m
//  HelloZhuge
//
//  Created by Zhugeio on 2019/7/20.
//  Copyright © 2019 37degree. All rights reserved.
//

#import "ZhugeAutoTrackUtils.h"

#import "Zhuge.h"
#import "ZGLog.h"
#import "UIView+ZGView.h"
#import "ZAViews.h"
#import "UIWindow+ZGView.h"

id isNil(id obj) {
    if (!obj) return [NSNull null];
    else            return obj;
}

@implementation ZhugeAutoTrackUtils

+ (NSString *)zhugeGetViewContent:(UIView *)view{
    if (!view || view.isHidden) {
        return @"";
    }
    
    if (view.zhugeioAttributesDonotTrackValue) {
        return @"";
    }

    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        return label.text?:@"";
    }
    if ([view isKindOfClass:[UITextView class]]) {
        UITextView *label = (UITextView *)view;
        return label.text?:@"";
    }
    if ([view isKindOfClass:[UITabBar class]]) {
        UITabBar *label = (UITabBar *)view;
        return label.selectedItem.title?:@"";
    }
    if ([view isKindOfClass:[UISearchBar class]]) {
        UISearchBar *label = (UISearchBar *)view;
        return label.text?:@"";
    }
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *label = (UIButton *)view;
        return label.titleLabel.text?:@"";
    }
    if ([view isKindOfClass:[UISwitch class]]) {
        UISwitch *label = (UISwitch *)view;
        return label.selected?@"YES":@"NO";
    }
    if ([view isKindOfClass:[UIStepper class]]) {
        UIStepper *label = (UIStepper *)view;
        return [NSString stringWithFormat:@"%g", label.value];
    }
    if ([view isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *label = (UISegmentedControl *)view;
        return [label titleForSegmentAtIndex:label.selectedSegmentIndex];
    }
    if ([view isKindOfClass:[UISlider class]]) {
        UISlider *label = (UISlider *)view;
        return [NSString stringWithFormat:@"%f", label.value];
    }
    
    
    NSMutableString *elementContent = [NSMutableString string];
    
    if ([view isKindOfClass:NSClassFromString(@"RTLabel")]) {   // RTLabel:https://github.com/honcheng/RTLabel
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([view respondsToSelector:NSSelectorFromString(@"text")]) {
            NSString *title = [view performSelector:NSSelectorFromString(@"text")];
            if (title.length > 0) {
                [elementContent appendString:title];
            }
        }
#pragma clang diagnostic pop
    } else if ([view isKindOfClass:NSClassFromString(@"YYLabel")]) {    // RTLabel:https://github.com/ibireme/YYKit
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([view respondsToSelector:NSSelectorFromString(@"text")]) {
            NSString *title = [view performSelector:NSSelectorFromString(@"text")];
            if (title.length > 0) {
                [elementContent appendString:title];
            }
        }
#pragma clang diagnostic pop
    } else {
        NSMutableArray<NSString *> *elementContentArray = [NSMutableArray array];
        for (UIView *subview in view.subviews) {
            NSString *temp = [ZhugeAutoTrackUtils zhugeGetViewContent:subview];
            if (temp.length > 0) {
                [elementContentArray addObject:temp];
            }
        }
        if (elementContentArray.count > 0) {
            [elementContent appendString:[elementContentArray componentsJoinedByString:@"-"]];
        }
    }
    
    return elementContent.length == 0 ? @"" : [elementContent copy];

}

+ (UIViewController *)zhugeGetViewControllerByView:(UIView *)view{
    return [self findNextViewControllerByResponder:view];
}

+ (UIViewController *)currentViewController {
    __block UIViewController *currentViewController = nil;
    void (^ block)(void) = ^{
        UIViewController *rootViewController = [UIWindow zg_currentWindow].rootViewController;
        currentViewController = [self findCurrentViewControllerFromRootViewController:rootViewController isRoot:YES];
    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
    
    return currentViewController;
}

+ (UIViewController *)findCurrentViewControllerFromRootViewController:(UIViewController *)viewController isRoot:(BOOL)isRoot {
    UIViewController *currentViewController = nil;
    if (viewController.presentedViewController) {
        viewController = [self findCurrentViewControllerFromRootViewController:viewController.presentedViewController isRoot:NO];
    }
    
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        currentViewController = [self findCurrentViewControllerFromRootViewController:[(UITabBarController *)viewController selectedViewController] isRoot:NO];
    } else if ([viewController isKindOfClass:[UINavigationController class]]) {
        // 根视图为UINavigationController
        currentViewController = [self findCurrentViewControllerFromRootViewController:[(UINavigationController *)viewController visibleViewController] isRoot:NO];
    } else if ([viewController respondsToSelector:NSSelectorFromString(@"contentViewController")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        UIViewController *tempViewController = [viewController performSelector:NSSelectorFromString(@"contentViewController")];
#pragma clang diagnostic pop
        if (tempViewController) {
            currentViewController = [self findCurrentViewControllerFromRootViewController:tempViewController isRoot:NO];
        }
    } else if (viewController.childViewControllers.count == 1 && isRoot) {
        currentViewController = [self findCurrentViewControllerFromRootViewController:viewController.childViewControllers.firstObject isRoot:NO];
    } else {
        currentViewController = viewController;
    }
    return currentViewController;
}

+ (UIViewController *)findNextViewControllerByResponder:(UIResponder *)responder {
    UIResponder *next = [responder nextResponder];
    do {
        if ([next isKindOfClass:UIViewController.class]) {
            UIViewController *vc = (UIViewController *)next;
            // 响应者链通常能直接找到视图所在的 ViewController。
            // 如果找到的是容器类控制器（Nav/Tab），我们循环穿透获取其当前显示的子控制器，
            // 这样能准确地匹配到深层嵌套下的业务逻辑和设置在子控制器上的 zhugeioAttributesVariable。
            while ([vc isKindOfClass:[UINavigationController class]] || [vc isKindOfClass:[UITabBarController class]]) {
                if ([vc isKindOfClass:[UINavigationController class]]) {
                    vc = [(UINavigationController *)vc topViewController];
                } else if ([vc isKindOfClass:[UITabBarController class]]) {
                    vc = [(UITabBarController *)vc selectedViewController];
                }
                if (!vc) break;
            }
            
            // 如果穿透后的子控制器仍然存在，则返回；否则返回原始容器
            return vc ?: (UIViewController *)next;
        }
    } while ((next = next.nextResponder));
    
    // 如果响应链没找到，最后尝试获取当前活跃的控制器
    return [self currentViewController];
}

+ (NSString *)zhugeGetViewPath:(UIView *)view{
    if (!view || ![view isKindOfClass:[UIView class]]) {
        return @"";
    }
    UIView *parent = nil;
    NSMutableArray *array = [NSMutableArray array];
    do {
        parent = [view superview];
        NSString *index = [self zhugeGetView:view indexInParent:parent];
        NSString *className =NSStringFromClass([view class]);
        NSString *item = [NSString stringWithFormat:@"%@[%@]",className,index];
        [array insertObject:item atIndex:0];
        view = parent;
    } while (view);
    
    return  [array componentsJoinedByString:@"/"];
}

+ (NSString *)zhugeGetView:(UIView *)child indexInParent:(UIView *)parent{
    if (!child || !parent) {
        return @"-1";
    }
    NSInteger cellIndex = [self globalIndexForIfCellView:child];
    if (cellIndex != NSNotFound) {
        return [NSString stringWithFormat:@"%ld",(long)cellIndex];
    }
    NSArray *subViews = [parent subviews];
    Class childClass = [child class];
    int index=0;
    for (NSUInteger i=0,length=[subViews count];i<length;i++) {
        UIView *brother = [subViews objectAtIndex:i];
        if (brother == child) {
            break;
        }
        if ([brother isMemberOfClass:childClass]) {
            index++;
        }
    }
    return [NSString stringWithFormat:@"%d",index];
}

+ (NSInteger)globalIndexForIfCellView:(UIView *)view {
    // UITableViewCell
    if ([view isKindOfClass:[UITableViewCell class]]) {
        UITableViewCell *cell = (UITableViewCell *)view;

        UIView *superview = cell.superview;
        if (![superview isKindOfClass:[UITableView class]]) return NSNotFound;

        UITableView *tableView = (UITableView *)superview;
        NSIndexPath *indexPath = [tableView indexPathForCell:cell];
        if (!indexPath) return NSNotFound;
        return [tableView zg_globalIndexForIndexPath:indexPath];
    }

    // UICollectionViewCell
    if ([view isKindOfClass:[UICollectionViewCell class]]) {
        UICollectionViewCell *cell = (UICollectionViewCell *)view;

        UIView *superview = cell.superview;
        if (![superview isKindOfClass:[UICollectionView class]]) return NSNotFound;

        UICollectionView *collectionView = (UICollectionView *)superview;
        NSIndexPath *indexPath = [collectionView indexPathForCell:cell];
        if (!indexPath) return NSNotFound;

        return [collectionView zg_globalIndexForIndexPath:indexPath];
    }
    // 既不是 UITableViewCell 也不是 UICollectionViewCell
    return NSNotFound;
}
+ (void)zhugeAutoTrackClick:(UIView *)view withController:(UIViewController *)controller andTag:( NSString *)tag{
    
    if([Zhuge autoTrackInstance].count <= 0){
        return;
    }
    
    if ([view isKindOfClass:[UIView class]] && view.zhugeioAttributesDonotTrack) {
        return;
    }
    
    @try {
        if (!view) {
            ZGLogError(@"autoTrackError illegal view %@ in %@",view?[view description]:@"null",tag);
            return;
        }
        NSString *content = @"";
        NSString *path = @"";
        if ([view isKindOfClass:[UIBarItem class]]) {
            path = NSStringFromClass([view class]);
            UIBarItem *item = (UIBarItem *)view;
            content = item.title;
        }else if([view isKindOfClass:[UIView class]]){
            content = [self zhugeGetViewContent:view];
            path = [self zhugeGetViewPath:view];
        }
        UIViewController *realController =controller?: [self zhugeGetViewControllerByView:view];
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        [data setObject:@"click" forKey:@"$eid"];
        NSString *url = @"";
        NSString *title = @"";
        if (realController) {
            url = [realController zhugeScreenName];
            title = [realController zhugeScreenTitle];
        }
        NSString *type = NSStringFromClass([view class]);
        [data setObject:isNil(url) forKey:@"$page_url"];
        [data setObject:isNil(type) forKey:@"$element_type"];
        [data setObject:isNil(path) forKey:@"$element_selector"];
        [data setObject:isNil(title) forKey:@"$page_title"];
        [data setObject:isNil(content) forKey:@"$element_content"];
        //        [data setObject:isNil(zhuge.ref) forKey:@"$ref"];
        
        // 合并页面属性（低优先级）
        if (realController && realController.zhugeioAttributesVariable && realController.zhugeioAttributesVariable.count > 0) {
            for (NSString *key in realController.zhugeioAttributesVariable) {
                id value = realController.zhugeioAttributesVariable[key];
                NSString *newKey = [NSString stringWithFormat:@"_%@",key];
                [data setValue:value forKey:newKey];
            }
        }
        
        // 合并View自身属性（高优先级）
        if ([view isKindOfClass:[UIView class]]) {
            if (view.zhugeioAttributesVariable && view.zhugeioAttributesVariable.count > 0) {
                for (NSString *key in view.zhugeioAttributesVariable) {
                    id value = view.zhugeioAttributesVariable[key];
                    NSString *newKey = [NSString stringWithFormat:@"_%@",key];
                    [data setValue:value forKey:newKey];
                }
            }
        }
        NSArray *array = [Zhuge autoTrackInstance];
        for (Zhuge *zhuge in array) {
            [zhuge autoTrack:data];
        }
    } @catch (NSException *exception) {
        ZGLogError(@"autoTrack exception %@: %@",[exception name],[exception reason]);
    }
}

@end


#pragma mark - Index

@implementation ZhugeAutoTrackUtils (IndexPath)

+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIScrollView<ZAAutoTrackViewProperty> *)object didSelectedAtIndexPath:(NSIndexPath *)indexPath {
    
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];

    id cell = nil;
    if ([object isKindOfClass:UITableView.class]) {
        UITableView *tableView = (UITableView *)object;
        cell = [tableView cellForRowAtIndexPath:indexPath];
        if (!cell) {
            [tableView layoutIfNeeded];
            cell = [tableView cellForRowAtIndexPath:indexPath];
        }
    } else if ([object isKindOfClass:UICollectionView.class]) {
        UICollectionView *collectionView = (UICollectionView *)object;
        cell = [collectionView cellForItemAtIndexPath:indexPath];
        if (!cell) {
            [collectionView layoutIfNeeded];
            cell = [collectionView cellForItemAtIndexPath:indexPath];
        }
    }
    if (!cell) {
        return nil;
    }

    if ([cell isKindOfClass:[UIView class]] && [cell zhugeioAttributesDonotTrack]) {
        return nil;
    }

    NSString *content = [ZhugeAutoTrackUtils zhugeGetViewContent:cell];
    NSString *path = [ZhugeAutoTrackUtils zhugeGetViewPath:cell];
    NSString *type = NSStringFromClass([cell superclass]);
    
    UIViewController *realController = [ZhugeAutoTrackUtils zhugeGetViewControllerByView:cell];
    NSString *url = @"";
    NSString *title = @"";
    if (realController) {
        url = [realController zhugeScreenName];
        title = [realController zhugeScreenTitle];
    }
    
    [properties setObject:isNil(url) forKey:@"$page_url"];
    [properties setObject:type forKey:@"$element_type"];
    [properties setObject:isNil(path) forKey:@"$element_selector"];
    [properties setObject:isNil(title) forKey:@"$page_title"];
    [properties setObject:isNil(content) forKey:@"$element_content"];
    [properties setObject:@"click" forKey:@"$eid"];
    
    // 合并页面属性（低优先级）
    if (realController && realController.zhugeioAttributesVariable && realController.zhugeioAttributesVariable.count > 0) {
        for (NSString *key in realController.zhugeioAttributesVariable) {
            id value = realController.zhugeioAttributesVariable[key];
            NSString *newKey = [NSString stringWithFormat:@"_%@",key];
            [properties setValue:value forKey:newKey];
        }
    }

    // 合并Cell自身属性（高优先级）
    if ([cell isKindOfClass:[UIView class]]) {
        UIView *view = (UIView *)cell;
        if (view.zhugeioAttributesVariable && view.zhugeioAttributesVariable.count > 0) {
            for (NSString *key in view.zhugeioAttributesVariable) {
                id value = view.zhugeioAttributesVariable[key];
                NSString *newKey = [NSString stringWithFormat:@"_%@",key];
                [properties setValue:value forKey:newKey];
            }
        }
    }

    return properties;
}

@end
