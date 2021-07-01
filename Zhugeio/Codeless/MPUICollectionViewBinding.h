//
//  MPCollectionViewBinding.h
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/6/7.
//

#import "ZGEventBinding.h"



@interface MPUICollectionViewBinding : ZGEventBinding

- (instancetype)init __unavailable;
- (instancetype)initWithEventName:(NSString *)eventName onPath:(NSString *)path withDelegate:(Class)delegateClass;

@end


