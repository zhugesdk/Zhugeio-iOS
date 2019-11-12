//
//  UIGestureRecognizer+Zhuge.h
//  HelloZhuge
//
//  Created by jiaokang on 2019/7/21.
//  Copyright © 2019 37degree. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface UIGestureRecognizer (Zhuge)

@end


@interface UITapGestureRecognizer (Zhuge)

- (instancetype)zhuge_initWithTarget:(id)target action:(SEL)action;

- (void)zhuge_addTarget:(id)target action:(SEL)action;

@end


@interface UILongPressGestureRecognizer (Zhuge)

- (instancetype)zhuge_initWithTarget:(id)target action:(SEL)action;

- (void)zhuge_addTarget:(id)target action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
