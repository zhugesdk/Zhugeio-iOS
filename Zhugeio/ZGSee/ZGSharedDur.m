//
//  ZGSharedDur.m
//  HelloZhuge
//
//  Created by jiaokang on 2018/9/5.
//  Copyright © 2018年 37degree. All rights reserved.
//

#import "ZGSharedDur.h"
@interface ZGSharedDur()
@property (nonatomic) NSDate *gapDate;
@property (nonatomic , copy) NSString *currentPageName;
@property (nonatomic,strong) NSDate *imageCreateDate;

@property (nonatomic, strong) NSData *pixData;
@property (nonatomic, strong) UIImage * pixImage;
@end

@implementation ZGSharedDur

+ (instancetype)shareInstance {
    
    static ZGSharedDur *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once (&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
    
//    static ZGSharedDur* dur = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        dur = [[self alloc] init];
//    });
//    return dur;
}
-(instancetype)init{
    if (self = [super init]) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}
-(void)keyboardWillShow:(NSNotification *)notication{
    self.isKeyboardShow = YES;
}
-(void)keyboardWillHide:(NSNotification *)notication{
    self.isKeyboardShow = NO;
}
-(void)dealloc{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}

-(void)updateCommanGapData{
    self.gapDate = [NSDate date];
}
-(NSString *)getCurrentGap {
    if (self.gapDate) {
        return [NSString stringWithFormat:@"%.2lf", [[NSDate date]timeIntervalSinceDate:self.gapDate]];
    }else{
        return @"0";
    }
}
- (CGFloat)durInterval {
    if (self.durDate == nil) {
        self.durDate = [NSDate date];
    }
    
    CGFloat dur = [[NSDate date] timeIntervalSinceDate:self.durDate];
    
    return dur;
}

- (NSString *)getViewToPath:(id)view{
    NSString * path = @"";

    for (UIView* next = view; next; next = next.superview) {
        
        path = [NSString stringWithFormat:@"%@_%ld_%@",next.class,(long)[self viewInIndexToSuperView:next],path];
        
    }
    return path;
    
}

- (NSInteger)viewInIndexToSuperView:(UIView *)view
{
    NSInteger index = 0;
    NSArray * viewAry = [view.superview subviews];
    
    //取同类元素的index
    NSInteger j = 0;
    
    for (int i = 0; i<viewAry.count; i++)
    {
        UIView * chileView = viewAry[i];
        if ([chileView.class isEqual:view.class])
        {
            if ([chileView isEqual:view]){
                index = j;
            }
            j++;
        }
    }
    return index;
    
}

- (UIViewController *)viewControllerToView:(UIView *)view {
    for (UIView* next = [view superview]; next; next = next.superview) {
        UIResponder *nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}
-(void)zhugeSetCurrentVC:(NSString *)name{
    self.currentPageName = name;
//    NSLog(@"set page name is %@",name);
}
-(BOOL)permitCreateImage{
    if (self.imageCreateDate) {
        NSDate *now = [NSDate date];
        NSTimeInterval timeInterval = [now timeIntervalSinceDate:self.imageCreateDate];
        if (timeInterval > 2) { //3秒内截一张
            self.imageCreateDate = now;
            return YES;
        }else{
            return NO;
        }
    }else{
        self.imageCreateDate = [NSDate date];
        return YES;
    }
}
- (NSString *)zhugeGetCurrentVC {
//    NSLog(@"return page name is %@",self.currentPageName);
    return self.currentPageName;
}

- (NSData *)pixData {
    @autoreleasepool {
        UIImage *pixImage;
            NSData *pixData;
        //  参照视图
            UIView * view = [UIApplication sharedApplication].windows.firstObject;
        //  参照视图总大小
            CGSize size = view.bounds.size;
        //  开启上下文，第二个参数设置是否不透明，第三个参数设置相对于设备屏幕缩放的比例
            UIGraphicsBeginImageContextWithOptions(size, YES,1.0);
        //  根据参照视图的大小设置要裁剪的矩形范围
            CGRect rect = CGRectMake(0, 0, size.width, size.height);
        //  iOS7以后renderInContext：由drawViewHierarchyInRect：afterScreenUpdates：替代
            [view drawViewHierarchyInRect:rect  afterScreenUpdates:NO];
        //  从上下文中,取出UIImage
            pixImage = UIGraphicsGetImageFromCurrentImageContext();
        //  结束上下文
            UIGraphicsEndImageContext();
        //  使用jpg编码指定图片，并指定压缩比例，0-1，1最清晰，0最小
            pixData = UIImageJPEGRepresentation(pixImage, 0.2);
            return pixData;
    }
}
@end
