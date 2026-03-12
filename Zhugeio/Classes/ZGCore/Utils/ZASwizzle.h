//
//  NSObject+ZASwizzle.h
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/4/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ZASwizzle)

+ (BOOL)za_swizzleMethod:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError **)error_;
+ (BOOL)za_swizzleClassMethod:(SEL)origSel_ withClassMethod:(SEL)altSel_ error:(NSError **)error_;

+ (BOOL)za_swizzleMethod:(SEL)origSel_  withClass:(Class)altCla_ withMethod:(SEL)altSel_ error:(NSError **)error_;

@end

NS_ASSUME_NONNULL_END
