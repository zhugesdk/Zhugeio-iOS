//
//  UIView+ZAAttributes.m
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/6/17.
//

#import "ZAViews.h"
#import <objc/runtime.h>
#import "Zhuge.h"


@implementation UIView(ZAExposure)

- (void)setZhugeioExpScale:(double)zhugeioExpScale {
    objc_setAssociatedObject(self, @"zhugeioExpScale", [NSNumber numberWithDouble:zhugeioExpScale], OBJC_ASSOCIATION_ASSIGN);
}

- (double)zhugeioExpScale {
    return [objc_getAssociatedObject(self, @"zhugeioExpScale") doubleValue];
}

- (void)zhugeioExpTrack:(NSString *)eventId {

    self.zhugeioAttributesValue = eventId;
    self.zhugeioAttributesDonotTrackExp = NO;
}

- (void)zhugeioExpTrack:(NSString *)eventId withNumber:(NSNumber *)number {
    self.zhugeioAttributesValue = eventId;
    self.zhugeioAttributesUniqueTag = number;
    self.zhugeioAttributesDonotTrackExp = NO;
}

- (void)zhugeioExpTrack:(NSString *)eventId withVariable:(NSDictionary<NSString *,id> *)variable {
    self.zhugeioAttributesValue = eventId;
    self.zhugeioAttributesVariable = variable;
    self.zhugeioAttributesDonotTrackExp = NO;
}

- (void)zhugeioExpTrack:(NSString *)eventId withNumber:(NSNumber *)number andVariable:(NSDictionary<NSString *,id> *)variable {
    self.zhugeioAttributesValue = eventId;
    self.zhugeioAttributesUniqueTag = number;
    self.zhugeioAttributesVariable = variable;
    self.zhugeioAttributesDonotTrackExp = NO;
}

- (void)zhugeioStopExpTrack {
    self.zhugeioAttributesDonotTrackExp = YES;
}

@end

@implementation UIView (ZAAttributes)

- (void)setZhugeioAttributesDonotTrack:(BOOL)zhugeioAttributesDonotTrack {
    objc_setAssociatedObject(self, @"zhugeioAttributesDonotTrack", [NSNumber numberWithBool:zhugeioAttributesDonotTrack], OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)zhugeioAttributesDonotTrack {
    return [objc_getAssociatedObject(self, @"zhugeioAttributesDonotTrack") boolValue];
}

- (void)setZhugeioAttributesDonotTrackExp:(BOOL)zhugeioAttributesDonotTrackExp {
    objc_setAssociatedObject(self, @"zhugeioAttributesDonotTrackExp", [NSNumber numberWithBool:zhugeioAttributesDonotTrackExp], OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)zhugeioAttributesDonotTrackExp {
    return [objc_getAssociatedObject(self, @"zhugeioAttributesDonotTrackExp") boolValue];
}


- (void)setZhugeioAttributesDonotTrackValue:(BOOL)zhugeioAttributesDonotTrackValue {
    objc_setAssociatedObject(self, @"zhugeioAttributesDonotTrackValue", [NSNumber numberWithBool:zhugeioAttributesDonotTrackValue], OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)zhugeioAttributesDonotTrackValue {
    return [objc_getAssociatedObject(self, @"zhugeioAttributesDonotTrackValue") boolValue];
}

- (void)setZhugeioAttributesValue:(NSString *)zhugeioAttributesValue {
    objc_setAssociatedObject(self, @"zhugeioAttributesValue", zhugeioAttributesValue, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)zhugeioAttributesValue {
    return objc_getAssociatedObject(self, @"zhugeioAttributesValue");
}

- (void)setZhugeioAttributesUniqueTag:(NSString *)zhugeioAttributesUniqueTag {
    objc_setAssociatedObject(self, @"zhugeioAttributesUniqueTag", zhugeioAttributesUniqueTag, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)zhugeioAttributesUniqueTag {
    return objc_getAssociatedObject(self, @"zhugeioAttributesUniqueTag");
}

- (void)setZhugeioAttributesInfo:(NSString *)zhugeioAttributesInfo {
    objc_setAssociatedObject(self, @"zhugeioAttributesInfo", zhugeioAttributesInfo, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)zhugeioAttributesInfo {
    return objc_getAssociatedObject(self, @"zhugeioAttributesInfo");
}


- (void)setZhugeioAttributesVariable:(NSDictionary *)zhugeioAttributesVariable {
    objc_setAssociatedObject(self, @"zhugeioAttributesVariable", zhugeioAttributesVariable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary *)zhugeioAttributesVariable {
    return objc_getAssociatedObject(self, @"zhugeioAttributesVariable");
}

@end
