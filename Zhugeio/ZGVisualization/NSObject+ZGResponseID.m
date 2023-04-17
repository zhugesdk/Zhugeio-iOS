//
//  NSObject+ZGResponseID.m
//  ZGTestDemo
//
//  Created by 范奇 on 2023/2/23.
//

#import "NSObject+ZGResponseID.h"
#import <objc/runtime.h>

@implementation NSObject (ZGResponseID)

static char * ZGResponseID = "ZGResponseID";

-(NSString *)zg_responseID{
    return objc_getAssociatedObject(self, &ZGResponseID);
}

-(void)setZg_responseID:(NSString *)zg_responseID
{
    objc_setAssociatedObject(self, &ZGResponseID, zg_responseID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
