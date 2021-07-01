//
//  MPCollectionViewBinding.m
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/6/7.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "MPUICollectionViewBinding.h"
#import "MPSwizzler.h"
#import "NSThread+Helpers.h"
#import "ZhugeHeaders.h"
#import "Zhuge.h"


@implementation MPUICollectionViewBinding

+ (NSString *)typeName {
    return @"ui_collection_view";
}

+ (ZGEventBinding *)bindingWithJSONObject:(NSDictionary *)object {
    
    NSString *path = object[@"path"];
    if (![path isKindOfClass:[NSString class]] || path.length < 1) {
        NSLog(@"must supply a view path to bind by");
        return nil;
    }

    NSString *eventName = object[@"event_name"];
    if (![eventName isKindOfClass:[NSString class]] || eventName.length < 1 ) {
        NSLog(@"binding requires an event name");
        return nil;
    }

    Class collectionDelegate = NSClassFromString(object[@"collection_delegate"]);
    if (!collectionDelegate) {
        NSLog(@"binding requires a collection_delegate class");
        return nil;
    }
    
    return [[MPUICollectionViewBinding alloc] initWithEventName:eventName onPath:path withDelegate:collectionDelegate];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

+(ZGEventBinding *)bindngWithJSONObject:(NSDictionary *)object {
    return [self bindingWithJSONObject:object];;
}

#pragma clang diagnostic pop

- (instancetype)initWithEventName:(NSString *)eventName onPath:(NSString *)path {
    
    return [self initWithEventName:eventName onPath:path withDelegate:nil];

}

- (instancetype)initWithEventName:(NSString *)eventName onPath:(NSString *)path withDelegate:(Class)delegateClass {
    
    if (self = [super initWithEventName:eventName onPath:path]) {
        [self setSwizzleClass:delegateClass];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"UICollectionView Event Tracking: '%@' for '%@'", [self eventName], [self path]];
}

#pragma mark -- Executing Actions

- (void)execute {
    
    if (!self.running && self.swizzleClass != nil) {
        void (^block)(id, SEL, id, id) = ^(id view, SEL command, UICollectionView *collectionView, NSIndexPath *indexPath) {
            [NSThread mp_safelyRunOnMainThreadSync:^{
                NSObject *root = [Zhuge sharedUIApplication].keyWindow.rootViewController;
                // select targets based off path
                if (collectionView && [self.path isLeafSelected:collectionView fromRoot:root]) {
                    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
                    NSString *content = [ZhugeAutoTrackUtils zhugeGetViewContent:cell];
                    NSString *label = (cell && content) ? content : @"";
                    [[self class] track:[self eventName]
                             properties:@{
                                          @"Cell Index": [NSString stringWithFormat: @"%ld", (unsigned long)indexPath.row],
                                          @"Cell Section": [NSString stringWithFormat: @"%ld", (unsigned long)indexPath.section],
                                          @"Cell Label": label
                                          }];
                }
            }];
        };
        
        [MPSwizzler swizzleSelector:@selector(collectionView:didSelectItemAtIndexPath:)
                            onClass:self.swizzleClass
                          withBlock:block
                              named:self.name];
        self.running = true;
    }
}

- (void)stop {
    if (self.running && self.swizzleClass != nil) {
        [MPSwizzler unswizzleSelector:@selector(collectionView:didSelectItemAtIndexPath:)
                              onClass:self.swizzleClass
                                named:self.name];
        self.running = false;
    }
}

- (UICollectionView *)parentTableView:(UIView *)cell {
    // iterate up the view hierarchy to find the table containing this cell/view
    UIView *aView = cell.superview;
    while (aView != nil) {
        if ([aView isKindOfClass:[UICollectionView class]]) {
            return (UICollectionView *)aView;
        }
        aView = aView.superview;
    }
    return nil; // this view is not within a tableView
}

@end
