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

@end
