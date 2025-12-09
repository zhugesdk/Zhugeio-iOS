//
//  NSDictionary+ZhugeLog.m
//  ZhugeioAnanlytics
//
//  Created by kang on 2025/9/26.
//

#import "NSDictionary+ZhugeLog.h"

@implementation NSDictionary (ZhugeLog)

- (NSString *)descriptionWithLocale:(id)locale {
    return [self zhuge_descriptionWithIndent:0];
}

- (NSString *)zhuge_descriptionWithIndent:(NSUInteger)level {
    NSMutableString *indent = [NSMutableString string];
    for (NSUInteger i = 0; i < level; i++) {
        [indent appendString:@"    "]; // 4 空格缩进
    }
    
    NSMutableString *desc = [NSMutableString stringWithString:@"{\n"];
    for (id key in self) {
        id value = self[key];
        NSString *valueDesc;
        
        if ([value respondsToSelector:@selector(zhuge_descriptionWithIndent:)]) {
            valueDesc = [value zhuge_descriptionWithIndent:level + 1];
        } else {
            // 普通对象转成字符串时加引号
            valueDesc = [NSString stringWithFormat:@"\"%@\"", value];
        }
        
        [desc appendFormat:@"%@    \"%@\" = %@;\n", indent, key, valueDesc];
    }
    [desc appendFormat:@"%@}", indent];
    return desc;
}
@end
