//
//  ZGUtils.m
//  HelloZhuge
//
//  Created by Good_Morning_ on 2019/12/31.
//  Copyright © 2019 37degree. All rights reserved.
//

#import "ZGUtils.h"


@implementation ZGUtils

+ (NSString *)getViewContent:(UIView *)view {
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
            NSString *temp = [ZGUtils getViewContent:subview];
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

@end
