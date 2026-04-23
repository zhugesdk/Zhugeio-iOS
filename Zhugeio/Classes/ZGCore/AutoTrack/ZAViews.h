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

- (void)zhugeioExpTrack:(NSString *)eventId withVariable:(NSDictionary<NSString *, id> *)variable;

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

// 手动标识该view不要追踪曝光，请在该view被初始化后立刻赋值
@property (nonatomic, assign)BOOL zhugeioAttributesDonotTrackExp;

// 手动标识该view不要追踪它的值，默认是NO，特别的UITextView，UITextField，UISearchBar默认是YES
@property (nonatomic, assign)BOOL zhugeioAttributesDonotTrackValue;

// 手动标识该view的取值  比如banner广告条的id 可以放在banner按钮的任意view上
@property (nonatomic, copy)NSString* zhugeioAttributesValue;

// 手动标识该view的附加属性
// 全埋点点击事件中，属性合并规则如下：
// 1. ViewController 上的 zhugeioAttributesVariable 会自动合并到该 VC 下所有 view 的点击事件中（低优先级）
// 2. View 自身的 zhugeioAttributesVariable 优先级高于 ViewController（同 key 时 View 覆盖 VC）
// 3. 自定义属性的 key 在上报时会被自动加上 '_' 前缀，例如 @{@"productId": @"123"} 上报时 key 为 "_productId"
@property (nonatomic, strong)NSDictionary *zhugeioAttributesVariable;

@end

NS_ASSUME_NONNULL_END
