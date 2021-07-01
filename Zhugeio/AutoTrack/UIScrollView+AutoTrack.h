//
//  UIScrollView+AutoTrack.h
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/4/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITableView (AutoTrack)

- (void)zhugeio_setDelegate:(id <UITableViewDelegate>)delegate;

@end

@interface UICollectionView (AutoTrack)

- (void)zhugeio_setDelegate:(id <UICollectionViewDelegate>)delegate;

@end

@interface UIScrollView (AutoTrack)

@end

NS_ASSUME_NONNULL_END
