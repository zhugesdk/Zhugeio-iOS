//
//  UIApplication+Zhuge.h
//  HelloZhuge
//
//  Created by jiaokang on 2018/9/5.
//  Copyright © 2018年 37degree. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (Zhuge)
//全埋点代码
- (BOOL)zhuge_sendAction:(SEL _Nonnull )action
                      to:(nullable id)to
                    from:(nullable id)from
                forEvent:(nullable UIEvent *)event;


@end
