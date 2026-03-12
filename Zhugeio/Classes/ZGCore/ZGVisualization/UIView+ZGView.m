//
//  UIView+ZGView.m
//  ZGTestDemo
//
//  Created by 范奇 on 2023/2/23.
//

#import "UIView+ZGView.h"
#import <objc/runtime.h>
#import "ZGVisualizedTool.h"
#import "NSObject+ZGResponseID.h"
#import "ZGVisualizationManager.h"
#import "NSString+ZGMD5.h"

static const void *kZGStableViewIDKey = &kZGStableViewIDKey;

@implementation UIView (ZGView)

static char * ZGSupViewIndex = "ZGSupViewIndex";
static char * ZGSupViewZIndex = "ZGSupViewZIndex";
- (NSInteger)zgSupViewIndex{
    return [(NSNumber *)objc_getAssociatedObject(self, &ZGSupViewIndex) integerValue];
}

- (void)setZgSupViewIndex:(NSInteger)zgSupViewIndex {
    objc_setAssociatedObject(self, &ZGSupViewIndex, @(zgSupViewIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)zgSupViewZIndex{
    return [(NSNumber *)objc_getAssociatedObject(self, &ZGSupViewZIndex) integerValue];
}

- (void)setZgSupViewZIndex:(NSInteger)zgSupViewZIndex {
    objc_setAssociatedObject(self, &ZGSupViewZIndex, @(zgSupViewZIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController *)parentController
{
    UIResponder *responder = [self nextResponder];
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}
- (NSString *)zgStableViewID {

    /// ---- 1. 先从缓存取 ----
    NSString *cached = objc_getAssociatedObject(self, kZGStableViewIDKey);
    if (cached) {
        return cached;
    }

    /// ---- 2. 生成新的 ID ----
    NSString *path = [self zgStableViewPath];
    NSString *sign = [path getZGSHA256Str];

    /// ---- 3. 写入缓存 ----
    objc_setAssociatedObject(self, kZGStableViewIDKey, sign, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    return sign;
}

- (NSString *)zgStableViewPath {

    NSMutableArray *elements = [NSMutableArray array];
    [elements addObject:[self elementNameForView:self]];
    UIView *view = self.superview;

    while (view) {
        if (![self shouldIgnoreView:view]) {
            [elements addObject:[self elementNameForView:view]];
        }
        view = view.superview;
    }

    return [[[elements reverseObjectEnumerator] allObjects]
            componentsJoinedByString:@"/"];
}

#pragma mark - Ignore Layer

- (BOOL)shouldIgnoreView:(UIView *)view {

    NSString *className = NSStringFromClass([view class]);

    // 1. UIKit 内部类
    if ([className hasPrefix:@"_"]) return YES;

    // 2. LayoutGuide 忽略
    if ([view isKindOfClass:[UILayoutGuide class]]) return YES;

    // 3. ScrollIndicator 忽略
    if ([className containsString:@"Indicator"]) return YES;

    // 4. UIStackView 内部视图（不是 UIStackView 本身）
    if (![view isKindOfClass:[UIStackView class]] &&
        [className containsString:@"StackView"]) {
        return YES;
    }

    // 5. 仅包含一个 subview 的容器视图，且没 identifier
    if (view.subviews.count == 1 &&
        view.accessibilityIdentifier.length == 0 &&
        ![view isKindOfClass:[UITableViewCell class]] &&
        ![view isKindOfClass:[UICollectionViewCell class]]) {
        return YES;
    }

    return NO;
}

#pragma mark - View Element

- (NSString *)elementNameForView:(UIView *)view {

    NSString *className = NSStringFromClass([view class]);

    if (view == self){ //我们需要即能匹配同类兄弟节点，又能精准匹配自身。所以对于当前节点，就不加索引
        return [NSString stringWithFormat:@"%@", className];
    }

    // 1. accessibilityIdentifier 优先
    if (view.accessibilityIdentifier.length > 0) {
        return [NSString stringWithFormat:@"%@[%@]", className, view.accessibilityIdentifier];
    }

    // 2. UITableViewCell 处理 section,row
    if ([view isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self indexPathForTableViewCell:(UITableViewCell *)view];
        if (indexPath) {
            return [NSString stringWithFormat:@"%@[%ld,%ld]",
                    className,
                    (long)indexPath.section,
                    (long)indexPath.row];
        }
    }

    // 3. UICollectionViewCell 处理 section,item
    if ([view isKindOfClass:[UICollectionViewCell class]]) {
        NSIndexPath *indexPath = [self indexPathForCollectionViewCell:(UICollectionViewCell *)view];
        if (indexPath) {
            return [NSString stringWithFormat:@"%@[%ld,%ld]",
                    className,
                    (long)indexPath.section,
                    (long)indexPath.item];
        }
    }

    // 4. 默认：superview 中的 index
    NSUInteger idx = [view.superview.subviews indexOfObject:view];
    return [NSString stringWithFormat:@"%@[%lu]", className, (unsigned long)idx];
}

#pragma mark - indexPath

- (NSIndexPath *)indexPathForTableViewCell:(UITableViewCell *)cell {
    UIView *v = cell.superview;
    while (v) {
        if ([v isKindOfClass:[UITableView class]]) {
            return [(UITableView *)v indexPathForCell:cell];
        }
        v = v.superview;
    }
    return nil;
}

- (NSIndexPath *)indexPathForCollectionViewCell:(UICollectionViewCell *)cell {
    UIView *v = cell.superview;
    while (v) {
        if ([v isKindOfClass:[UICollectionView class]]) {
            return [(UICollectionView *)v indexPathForCell:cell];
        }
        v = v.superview;
    }
    return nil;
}

-(BOOL)zg_isVisible {
    //兼容只有window的情况
    if(![self isKindOfClass:[UIWindow class]]){
        if (!(self.window && self.superview)) {
            return NO;
        }
    }
   if(self.alpha <= 0.01 || self.isHidden) {
       return NO;
   }
    //宽或者高为0时.不可见
    if(self.bounds.size.width <= 0 || self.bounds.size.height <= 0){
        return NO;
    }
    
   // 计算 view 在 keyWindow 上的坐标
   CGRect rect = [self convertRect:self.bounds toView:nil];
   // 若 size 为 CGSizeZero
   if (CGRectIsNull(rect) || CGSizeEqualToSize(rect.size, CGSizeZero)) {
       return NO;
   }
   return YES;
}


// 判断一个 view 是否会触发可视化埋点事件
- (BOOL)zg_isAutoTrackAppClick {
    // 判断是否被覆盖
    if ([ZGVisualizedTool zg_isCoveredForView:self]) {
        return NO;
    }
    
    /*
     fq: UITextView 这里未做考量.可以在入口处customGestureViews中添加
     */
    
    if ([self isKindOfClass:UIControl.class]) {
        // UISegmentedControl 高亮渲染内部嵌套的 UISegment
        if ([self isKindOfClass:UISegmentedControl.class]) {
            return NO;
        }

        // 部分控件，响应链中不采集 $AppClick 事件
        if ([self isKindOfClass:UITextField.class]) {
            return NO;
        }

        UIControl *control = (UIControl *)self;
        BOOL userInteractionEnabled = control.userInteractionEnabled;
        BOOL enabled = control.enabled;
        UIControlEvents appClickEvents = UIControlEventTouchUpInside | UIControlEventValueChanged;
        if (@available(iOS 9.0, *)) {
            appClickEvents = appClickEvents | UIControlEventPrimaryActionTriggered;
        }
        BOOL containEvents = appClickEvents & control.allControlEvents;
        if (containEvents && userInteractionEnabled && enabled) { // 可点击
            return YES;
        }
    } else if ([self isKindOfClass:UIImageView.class] || [self isKindOfClass:UILabel.class] || [ZGVisualizationManager zg_customGestureViewsHasContainCurrentView:self]) {
        /*
         ps: 暂只采集 UILabel 和 UIImageView,但不能使用UIView.否则UIScrollView自带手势的就会全屏展示.影响就是给UIView添加手势的识别不了.
         若需要添加其他类型的.可设置[Zhuge sharedInstance].config.customGestureViews = @[@"ZGTestGestureView"];
         */
        // UISegmentedControl 嵌套 UISegment 作为选项单元格，特殊处理
        if ([NSStringFromClass(self.class) isEqualToString:@"UISegment"]) {
            return YES;
        }
        if (self.userInteractionEnabled && self.gestureRecognizers.count > 0) {
            __block BOOL enableGestureClick = NO;
            [self.gestureRecognizers enumerateObjectsUsingBlock:^(__kindof UIGestureRecognizer *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                // 目前 $AppClick 只采集 UITapGestureRecognizer 和 UILongPressGestureRecognizer
                if ([obj isKindOfClass:UITapGestureRecognizer.class] || [obj isKindOfClass:UILongPressGestureRecognizer.class]) {
                    self.zg_responseID = obj.zg_responseID;
                    *stop = YES;
                    enableGestureClick = YES;
                }
            }];
            return enableGestureClick;
        } else {
            return NO;
        }
    } else if ([self isKindOfClass:UITableViewCell.class]) {
        UITableView *tableView = (UITableView *)[self superview];
        self.zg_responseID = tableView.zg_responseID;
        do {
            if ([tableView isKindOfClass:UITableView.class]) {
                if (tableView.delegate && [tableView.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
                    return YES;
                }
            }
        } while ((tableView = (UITableView *)[tableView superview]));

        return NO;
    } else if ([self isKindOfClass:UICollectionViewCell.class]) {
        UICollectionView *collectionView = (UICollectionView *)[self superview];
        //设置唯一标识
        self.zg_responseID = collectionView.zg_responseID;
        if ([collectionView isKindOfClass:UICollectionView.class]) {
            if (collectionView.delegate && [collectionView.delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
                return YES;
            }
        }
        return NO;
    }
    return NO;
}


@end

@implementation UICollectionView (ZGElementCell)

- (NSArray *)zg_subElements {
    NSArray *subviews = self.subviews;
    NSMutableArray *newSubviews = [NSMutableArray array];
    // 只需要遍历可见 Cell
    NSArray *visibleCells = self.visibleCells;
    for (UIView *view in subviews) {
        if (!view.zg_isVisible) {
            continue;
        }
        if ([view isKindOfClass:UICollectionViewCell.class]) {
            if ([visibleCells containsObject:view]) {
                [newSubviews addObject:view];
            }
        } else {
            [newSubviews addObject:view];
        }
    }
    return newSubviews;
}

- (NSInteger)zg_globalIndexForIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) return NSNotFound;

    NSInteger numberOfSections = self.numberOfSections;
    if (indexPath.section >= numberOfSections) return NSNotFound;

    NSInteger index = 0;
    for (NSInteger s = 0; s < indexPath.section; s++) {
        index += [self numberOfItemsInSection:s];
    }

    index += indexPath.item;

    return index;
}

@end


@implementation UITableView (ZGElementCell)

- (NSArray *)zg_subElements {
    NSArray *subviews = self.subviews;
    NSMutableArray *newSubviews = [NSMutableArray array];
    // 只需要遍历可见 Cell
    NSArray *visibleCells = self.visibleCells;
    for (UIView *view in subviews) {
        if (!view.zg_isVisible) {
            continue;
        }
        if ([view isKindOfClass:UITableViewCell.class]) {
            if ([visibleCells containsObject:view]) {
                [newSubviews addObject:view];
            }
        } else {
            [newSubviews addObject:view];
        }
    }
    return newSubviews;
}
- (NSInteger)zg_globalIndexForIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) return NSNotFound;

    NSInteger numberOfSections = self.numberOfSections;
    if (indexPath.section >= numberOfSections) return NSNotFound;

    NSInteger index = 0;
    for (NSInteger s = 0; s < indexPath.section; s++) {
        index += [self numberOfRowsInSection:s];
    }
    index += indexPath.row;

    return index;
}
@end
