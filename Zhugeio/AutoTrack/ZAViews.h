//
//  UIView+ZAAttributes.h
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/6/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface UIView (ZAExposure)

// 设置该节点被认定为可见的比例
// 节点在屏幕中展示的面积 >= 节点面积 * scale 则判定该节点可见,反之不可见
// scale 比例因子,范围[0-1];默认值为0,这里0的意义可理解为无限接近于0
// 如需要指定scale 请在API zhugeioExpTrack 调用之前调用
@property (nonatomic, assign)double zhugeioExpScale;

// 以下为元素展示打点事件
// 在元素展示前调用即可,Zhugeio负责监听元素展示并触发事件
// 事件类型为自定义事件(evt)
- (void)zhugeioExpTrack:(NSString *)eventId;

- (void)zhugeioExpTrack:(NSString *)eventId withNumber:(NSNumber *)number;

- (void)zhugeioExpTrack:(NSString *)eventId withVariable:(NSDictionary<NSString *, id> *)variable;

- (void)zhugeioExpTrack:(NSString *)eventId withNumber:(NSNumber *)number andVariable:(NSDictionary<NSString *, id> *)variable;

// 停止该元素展示追踪
// 通常应用于列表中的重用元素
// 例如您只想追踪列表中的第一行元素的展示,但当第四行出现时重用了第一行的元素,此时您可调用此函数避免事件触发
- (void)zhugeioStopExpTrack;

@end

// 该属性setter方法均使用 objc_setAssociatedObject实现
// 如果是自定义的View建议优先使用重写getter方法来实现 以提高性能

@interface UIView (ZAAttributes)

// 手动标识该view不要追踪，请在该view被初始化后立刻赋值
@property (nonatomic, assign)BOOL zhugeioAttributesDonotTrack;

// 手动标识该view不要追踪，请在该view被初始化后立刻赋值
@property (nonatomic, assign)BOOL zhugeioAttributesDonotTrackExp;

// 手动标识该view不要追踪它的值，默认是NO，特别的UITextView，UITextField，UISearchBar默认是YES
@property (nonatomic, assign)BOOL zhugeioAttributesDonotTrackValue;

// 手动标识该view的取值  比如banner广告条的id 可以放在banner按钮的任意view上
@property (nonatomic, copy)NSString* zhugeioAttributesValue;

// 手动标识SDCycleScrollView组件的bannerIds  如若使用,请在创建SDCycleScrollView实例对象后,立即赋值;(如果不进行手动设置,SDK默认会采集banner的imageName或者imageURL)
//@property (nonatomic, strong) NSArray<NSString *> * zhugeioSDCycleBannerIds;

// 手动标识该view的附加属性 该值可被子节点继承
@property (nonatomic, copy)NSString* zhugeioAttributesInfo;

// 手动标识该view的附加属性 该字典可被子节点继承
@property (nonatomic, strong)NSDictionary *zhugeioAttributesVariable;

// 手动标识该view的tag
// 这个tag必须是全局唯一的，在代码结构改变时也请保持不变
// 这个tag最好是常量，不要包含流水id、SKU-id、商品名称等易变的信息
// 请不要轻易设置这个属性，除非该view在view-tree里的位置不稳定，或者该view在软件的不同版本的view-tree里的位置不一致
@property (nonatomic, copy)NSString* zhugeioAttributesUniqueTag;

@end

NS_ASSUME_NONNULL_END
