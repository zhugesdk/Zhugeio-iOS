//
//  ZADelegageProxy.h
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/4/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZADelegateProxy : NSObject

/**
 对 TableView 和 CollectionView 的单元格选中方法进行代理

 @param delegate 代理：UITableViewDelegate、UICollectionViewDelegate 等
 */
+ (void)proxyWithDelegate:(id)delegate;

@end

@interface ZADelegateProxy (Utils)

+ (BOOL)isKVOClass:(Class _Nullable)cls;

+ (BOOL)isZhugeClass:(Class _Nullable)cls;

+ (NSString *)generateZhugeClassName:(id)obj;

@end

NS_ASSUME_NONNULL_END
