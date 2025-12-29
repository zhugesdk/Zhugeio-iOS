//
//  ZGSqliteManager.m
//  SQL3
//
//  Created by 郭超 on 2017/7/14.
//  Copyright © 2017年 Guo Chao. All rights reserved.
//

#import "ZGSqliteManager.h"
#import <sqlite3.h>
#define kZGCoreDataData @"data"
#define kZGCoreDataSid @"sid"
#define kZGSQL @"ZhugeSeeSQL"

@interface ZGSqliteManager ()
{
    sqlite3 *db;
    
}
@property(nonatomic,strong)NSString *databaseName;

@end

@implementation ZGSqliteManager

+ (instancetype)shareManager {
    static ZGSqliteManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc]init];
    });
    return manager;
}

- (NSString *)getDatabaseFilePath
{
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dataBaseFilePath = [docPath stringByAppendingPathComponent:@"ZhugeSQL.sqlite"];
    
    return dataBaseFilePath;
}


- (BOOL)openDataBase {
    BOOL resultBool = YES;
    
    //1.获取沙盒文件名
    NSString *fileName = [self getDatabaseFilePath];
    
    //2.创建(打开)数据库 （如果数据库不存在，会自动创建）
    int result = sqlite3_open(fileName.UTF8String, &db);
    /*代码解析：sqlite3_open()将根据文件路径打开数据库，如果不存在，则会创建一个新的数据库。如果result等于常量SQLITE_OK，则表示成功打开数据库
     sqlite3 *db：一个打开的数据库实例
     数据库文件的路径必须以C字符串(而非NSString)传入*/
    
    if (result == SQLITE_OK) {
        
        
        //创表（这里以创建一个学生表为例，学生包含姓名和年龄，id integer primary key auto increment 为学生表的主键，并且会更具学生数据条数的增加而自动增加）
        NSString *sql = [NSString stringWithFormat:@"create table if not exists %@ (id integer primary key autoincrement,%@ integer not NULL,%@ text not NULL);",kZGSQL,kZGCoreDataSid,kZGCoreDataData];
        
        char *errorMesg = NULL; // 用来存储错误信息
        
        //sqlite3_exec()可以执行任何SQL语句，比如创表、更新、插入和删除操作。但是一般不用它执行查询语句，因为它不会返回查询到的数据
        int result = sqlite3_exec(db, sql.UTF8String, NULL, NULL, &errorMesg);
        
        if (result == SQLITE_OK) {
            
            //            NSLog(@"成功创建表");
            
            return resultBool;
            
        }else {
            
            //            NSLog(@"创建表失败:%s",errorMesg);
            
            return resultBool;
        }
        
    }else {
        
        //NSLog(@"打开数据库失败");
        
        return resultBool;
    }
    
    return resultBool;
}
//添加数据
- (BOOL)addZGSeeCoreDataDic:(NSMutableDictionary *)zgSeedic dicNumber:(NSInteger )dicNum
{
    NSString * sql = kZGSQL;
    
    BOOL resultBool = [self openDataBase];
    
    if (resultBool == YES) {
        
        //定义编译sql语句的变量（数据句柄）
        sqlite3_stmt *stmt = NULL;
        //开始编译sql语句
        sqlite3_prepare_v2(db, sql.UTF8String, -1, &stmt, NULL);
        //执行sql语句
        resultBool = sqlite3_step(stmt);
        
        //插入语句（insert into 表名（字段1，字段2，..）values (字段1值，字段2值，..);）
        NSString *sqlName = [NSString
                             stringWithFormat:@"insert into %@ (sid,data) values ('%@','%@');",sql,
                             zgSeedic[kZGCoreDataSid],zgSeedic[kZGCoreDataData]];
        
        char *errorMesg = NULL;
        int result = sqlite3_exec(db, sqlName.UTF8String, NULL, NULL, &errorMesg);
        
        if (result == SQLITE_OK)
        {
            //关闭数据句柄和数据库
            sqlite3_finalize(stmt);
            sqlite3_close(db);
            return YES;
        }
        else
        {
            //关闭数据句柄和数据库
            sqlite3_finalize(stmt);
            sqlite3_close(db);
            return NO;
        }
        
        
        
    }
    
    
    [self deleteZGSeeCoreDataDicNumber:dicNum];
    
    return NO;
}

- (void)deleteZGSeeCoreDataDicNumber:(NSInteger )dicNum
{
    
    
    BOOL resultBool = [self openDataBase];
    
    if (resultBool == YES)
    {
        
        //查重
        NSMutableArray * listArray = [NSMutableArray array];
        NSString *distinctSql = [NSString stringWithFormat:@"select distinct %@ from %@",kZGCoreDataSid,kZGSQL];
        //2.定义一个stmt存放结果集
        sqlite3_stmt *stmt = NULL;
        //3.检测SQL语句的合法性
        int result = sqlite3_prepare_v2(db, distinctSql.UTF8String, -1, &stmt, NULL);
        if (result == SQLITE_OK)
        {
            
            //NSLog(@"查询语句合法");
            //先查重
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                //获得第几条的id
                long long sid = sqlite3_column_int64(stmt, 0);
                [listArray addObject:@(sid)];
            }
            
            //关闭数据句柄和数据库
            sqlite3_finalize(stmt);
        }
        else
        {
            //NSLog(@"查询语句非法");
        }
        
        //查重
        NSMutableArray * allArray = [NSMutableArray array];
        NSString * allSql = [NSString stringWithFormat:@"select %@ from %@",kZGCoreDataSid,kZGSQL];
        //2.定义一个stmt存放结果集
        sqlite3_stmt * allstmt = NULL;
        //3.检测SQL语句的合法性
        int allResult = sqlite3_prepare_v2(db, allSql.UTF8String, -1, &allstmt, NULL);
        if (allResult == SQLITE_OK)
        {
            
            //NSLog(@"查询语句合法");
            //先查重
            while (sqlite3_step(allstmt) == SQLITE_ROW) {
                //获得第几条的id
                long long sid = sqlite3_column_int64(allstmt, 0);
                [allArray addObject:@(sid)];
            }
            
            //关闭数据句柄和数据库
            sqlite3_finalize(allstmt);
        }
        else
        {
        }
        
        
        if (listArray.count > dicNum)
        {
            for (int i = 0; i<listArray.count-dicNum; i++)
            {
                NSString * deleteSql = [NSString stringWithFormat:@"delete from %@ where %@ = %@",kZGSQL,kZGCoreDataSid,listArray[i]];
                char *errorMesg = NULL;
                int deleteResult = sqlite3_exec(db, deleteSql.UTF8String, NULL, NULL, &errorMesg);
                
                if (deleteResult == SQLITE_OK)
                {
                    //                    NSLog(@"删除成功");
                }else {
                    //                    NSLog(@"删除失败");
                }
            }
        }
        sqlite3_close(db);
        
    }
    
}

//上传存储的数据
- (NSMutableArray *)uploaddataStoredNumData:(NSInteger)numData
{
    
    BOOL resultBool = [self openDataBase];
    
    if (resultBool == YES)
    {
        
        //查重
        NSMutableArray * listArray = [NSMutableArray array];
        NSString *distinctSql = [NSString stringWithFormat:@"select distinct %@ from %@",kZGCoreDataSid,kZGSQL];
        //2.定义一个stmt存放结果集
        sqlite3_stmt *stmt = NULL;
        //3.检测SQL语句的合法性
        int result = sqlite3_prepare_v2(db, distinctSql.UTF8String, -1, &stmt, NULL);
        if (result == SQLITE_OK)
        {
            
            //NSLog(@"查询语句合法");
            //先查重
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                //获得第几条的id
                long long sid = sqlite3_column_int64(stmt, 0);
                [listArray addObject:@(sid)];
            }
            
            //关闭数据句柄和数据库
            sqlite3_finalize(stmt);
        }
        else
        {
            //NSLog(@"查询语句非法");
        }
        //        NSLog(@"数据库有%ld",listArray.count);
        if (listArray.count>0)
        {
            for (int i = 0; i<listArray.count; i++)
            {
                //                NSLog(@"数据库有%ld条数据 数据sid是-----%@",listArray.count,listArray[i]);
            }
            
            NSMutableArray * allArray = [NSMutableArray array];
            NSString * allSql = [NSString stringWithFormat:@"select %@,%@ from %@ where %@ = %ld",kZGCoreDataSid,kZGCoreDataData,kZGSQL,kZGCoreDataSid,[listArray[0] longValue]];
            //2.定义一个stmt存放结果集
            sqlite3_stmt * allstmt = NULL;
            //3.检测SQL语句的合法性
            int allResult = sqlite3_prepare_v2(db, allSql.UTF8String, -1, &allstmt, NULL);
            if (allResult == SQLITE_OK)
            {
                
                //NSLog(@"查询语句合法");
                //先查重
                while (sqlite3_step(allstmt) == SQLITE_ROW) {
                    NSMutableDictionary * dic = [NSMutableDictionary dictionary];
                    //获取数据
                    long long sid = sqlite3_column_int64(allstmt, 0);
                    dic[@"sid"] = @(sid);
                    NSString * data = [NSString stringWithFormat:@"%s",sqlite3_column_text(allstmt, 1)];
                    dic[@"data"] = data;
                    [allArray addObject:dic];
                    
                }
                
                //关闭数据句柄和数据库
                sqlite3_finalize(allstmt);
                return allArray;
            }
            else
            {
                //NSLog(@"查询语句非法");
            }
        }
        sqlite3_close(db);
        
    }
    return nil;
}

//删除数据
- (void)deletezgSeeCoreDataSid:(NSString *)sid
{
    BOOL resultBool = [self openDataBase];
    
    if (resultBool == YES)
    {
        NSString * deleteSql = [NSString stringWithFormat:@"delete from %@ where %@ = %@",kZGSQL,kZGCoreDataSid,sid];
        char *errorMesg = NULL;
        int deleteResult = sqlite3_exec(db, deleteSql.UTF8String, NULL, NULL, &errorMesg);
        
        if (deleteResult == SQLITE_OK)
        {
            //NSLog(@"删除成功");
        }else {
            //NSLog(@"删除失败");
        }
        
        sqlite3_close(db);
    }
}


@end

