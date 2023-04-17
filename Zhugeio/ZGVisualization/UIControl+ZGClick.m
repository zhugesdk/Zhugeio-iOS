//
//  UIControl+ZGClick.m
//  ZGTestDemo
//
//  Created by 范奇 on 2023/2/23.
//

#import "UIControl+ZGClick.h"
#import <objc/runtime.h>
#import "ZGVisualizationManager.h"
#import "NSObject+ZGResponseID.h"
#import "Zhuge.h"

@implementation UIControl (ZGClick)

- (void)zg_addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents{
    self.zg_responseID = [NSString stringWithFormat:@"%@/%@/%lu",[target class],NSStringFromSelector(action),(unsigned long)controlEvents];
    [self zg_addTarget:target action:action forControlEvents:controlEvents];
}

@end
