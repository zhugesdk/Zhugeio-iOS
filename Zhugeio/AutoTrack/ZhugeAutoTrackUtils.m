//
//  ZhugeAutoTrackUtils.m
//  HelloZhuge
//
//  Created by jiaokang on 2019/7/20.
//  Copyright © 2019 37degree. All rights reserved.
//

#import "ZhugeAutoTrackUtils.h"
#import "UIViewController+Zhuge.h"
#import "Zhuge.h"

@implementation ZhugeAutoTrackUtils
+ (NSString *)zhugeGetViewContent:(UIView *)view{
    if (!view || view.isHidden) {
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
+(UIViewController *)zhugeGetViewControllerByView:(UIView *)view{
    UIViewController *viewController = [self findNextViewControllerByResponder:view];
    if ([viewController isKindOfClass:UINavigationController.class]) {
        viewController = [self currentViewController];
    }
    return viewController;
}
+ (UIViewController *)currentViewController {
    __block UIViewController *currentViewController = nil;
    void (^ block)(void) = ^{
        UIViewController *rootViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
        currentViewController = [self findCurrentViewControllerFromRootViewController:rootViewController isRoot:YES];
    };
    
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {
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
            if ([vc isKindOfClass:UINavigationController.class]) {
                next = [(UINavigationController *)vc topViewController];
                break;
            } else if ([vc isKindOfClass:UITabBarController.class]) {
                next = [(UITabBarController *)vc selectedViewController];
                break;
            }
            UIViewController *parentVC = vc.parentViewController;
            if (parentVC) {
                if ([parentVC isKindOfClass:UINavigationController.class] ||
                    [parentVC isKindOfClass:UITabBarController.class] ||
                    [parentVC isKindOfClass:UIPageViewController.class] ||
                    [parentVC isKindOfClass:UISplitViewController.class]) {
                    break;
                }
            } else {
                break;
            }
        }
    } while ((next = next.nextResponder));
    return [next isKindOfClass:UIViewController.class] ? (UIViewController *)next : nil;
}

+(NSString *)zhugeGetViewPath:(UIView *)view{
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
+(NSString *)zhugeGetView:(UIView *)child indexInParent:(UIView *)parent{
    if (!child || !parent) {
        return @"-1";
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
+(void)zhugeAutoTrackClick:(UIView *)view withController:(UIViewController *)controller andTag:( NSString *)tag{
    @try {
        if (!view) {
            NSLog(@"autoTrackError illegal view %@ in %@",view?[view description]:@"null",tag);
            return;
        }
        Zhuge * zhuge = [Zhuge sharedInstance];
        NSString *content = @"";
        NSString *path = @"";
        if ([view isKindOfClass:[UIBarItem class]]) {
            path =NSStringFromClass([view class]);
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
        [data setObject:url forKey:@"$url"];
        [data setObject:type forKey:@"$element_type"];
        [data setObject:path forKey:@"$element_selector"];
        [data setObject:title forKey:@"$page_title"];
        [data setObject:content forKey:@"$element_content"];
        [zhuge autoTrack:data];
    } @catch (NSException *exception) {
        NSLog(@"autoTrack exception %@: %@",[exception name],[exception reason]);
    }
}
@end
