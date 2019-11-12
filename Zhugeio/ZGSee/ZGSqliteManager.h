//
//  ZGSqliteManager.h
//  HelloZhuge
//
//  Created by jiaokang on 2018/9/6.
//  Copyright © 2018年 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZGSqliteManager : NSObject

+ (instancetype)shareManager;

//创建并且打开数据库
- (BOOL)openDataBase;

//添加数据
- (BOOL)addZGSeeCoreDataDic:(NSMutableDictionary *)zgSeedic dicNumber:(NSInteger )dicNum;

//上传存储的数据
- (NSMutableArray *)uploaddataStoredNumData:(NSInteger)numData;

//删除数据
- (void)deletezgSeeCoreDataSid:(NSString *)sid;


@end
