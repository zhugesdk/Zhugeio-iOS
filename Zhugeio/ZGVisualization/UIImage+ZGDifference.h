//
//  UIImage+ZGDifference.h
//  ZGTestDemo
//
//  Created by 范奇 on 2023/2/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (ZGDifference)


/// 获取图像对象的特定值
-(NSString *)getCurrentImgSign;

// 获取图片唯一标识.准确度还行.可作为图片唯一标识
-(NSString *)getShortCurrentShowImgSign;

@end

NS_ASSUME_NONNULL_END
