//
//  UIView+ZAExpView.m
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/7/8.
//

#import "UIView+ZAExpView.h"
#import "Zhuge.h"
#import "ZhugeHeaders.h"

//static const UIView *previousView;
//static NSString * _previousEventName = @"";
//static NSString * _currentEventName = @"";

//static CFAbsoluteTime _previousEventTime = 0;
//static CFAbsoluteTime _currentEventTime = 0;

@implementation UIView (ZAExpView)

//([self isKindOfClass:[UITableView class]] ||
//    [self isKindOfClass:[UICollectionView class]]) &&

- (void)za_layoutSubviews {
    if ([self isKindOfClass:[UITableViewCell class]] || [self isKindOfClass:[UICollectionViewCell class]]) {
        if ( self.zhugeioAttributesValue &&
            !self.zhugeioAttributesDonotTrackExp &&
            [Zhuge sharedInstance].config.isEnableExpTrack) {
            [self trackExpEvent:self.zhugeioAttributesValue properties:self.zhugeioAttributesVariable];
        }
    }
    
    
    [self za_layoutSubviews];
}

- (void)trackExpEvent:(NSString *)eid properties:(NSDictionary *)pro {
    [[Zhuge sharedInstance] track:eid properties:pro];
}


@end
