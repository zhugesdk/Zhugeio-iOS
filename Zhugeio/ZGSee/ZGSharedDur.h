//
//  ZGSharedDur.h
//  HelloZhuge
//
//  Created by jiaokang on 2018/9/5.
//  Copyright © 2018年 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "zlib.h"
@interface ZGSharedDur : NSObject


//日期
@property (nonatomic,strong) NSDate * durDate;
@property (nonatomic) BOOL isKeyboardShow;

+ (instancetype)shareInstance;

//计算页面停留时长
- (CGFloat) durInterval;

//获取View路径
- (NSString *)getViewToPath:(id)view;

//获取view所在的VC
- (UIViewController *)viewControllerToView:(UIView *)view;

-(void) zhugeSetCurrentVC:(NSString *)name;
//获取当前的控制器
- (NSString *)zhugeGetCurrentVC;
//截图
- (NSData *)pixData;

-(void)updateCommanGapData;
-(NSString *)getCurrentGap;
-(BOOL)permitCreateImage;
@end
