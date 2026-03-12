#import "ZhugeDbAdapter.h"
#import "ZGLog.h"
#import <sqlite3.h>

NSString *const kZhugeDbData = @"data";
NSString *const kZhugeDbLastId = @"last_id";

static NSString *const kTableName = @"events";
static NSString *const kColId = @"_id";
static NSString *const kColData = @"data";
static NSString *const kColCreatedAt = @"created_at";
static const NSUInteger kMaxPendingEvents = 1000;
static const NSUInteger kMaxGetSize = 25;
static int const kDatabaseVersion = 1;

@interface ZhugeDbAdapter ()

@property (nonatomic, strong) NSString *dbPath;
@property (nonatomic, assign) sqlite3 *db;
@property (nonatomic, strong) dispatch_queue_t dbQueue;

// 缓冲队列相关
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *pendingEvents;
@property (nonatomic, assign) BOOL isFlushScheduled;

@end

@implementation ZhugeDbAdapter

- (instancetype)initWithAppKey:(NSString *)appKey {
    self = [super init];
    if (self) {
        // 创建串行队列保证数据库操作线程安全
        NSString *label = [NSString stringWithFormat:@"com.zhuge.db.queue.%@", appKey];
        _dbQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        _pendingEvents = [NSMutableArray array];
        _isFlushScheduled = NO;
        
        // 设置数据库路径: Library/Zhuge/zhuge_{appKey}.sqlite
        NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
        NSString *dirPath = [libraryPath stringByAppendingPathComponent:@"Zhuge"];
        
        // 确保目录存在
        if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSString *dbName = [NSString stringWithFormat:@"zhuge_%@.sqlite", appKey];
        _dbPath = [dirPath stringByAppendingPathComponent:dbName];
        
        [self openAndInitializeDatabase];
    }
    return self;
}

- (void)dealloc {
    [self closeDatabase];
}

#pragma mark - Database Lifecycle

- (void)openAndInitializeDatabase {
    dispatch_sync(self.dbQueue, ^{
        [self openDatabaseInternal];
    });
}

// 内部方法，必须在 dbQueue 中调用
- (void)openDatabaseInternal {
    // 1. 打开数据库
    if (sqlite3_open([self.dbPath UTF8String], &self->_db) != SQLITE_OK) {
        ZGLogError(@"Failed to open database.");
        return;
    }
    //添加超时时间
    sqlite3_busy_timeout(self->_db, 2000); // 2 秒，SDK 常用值
    
    // 开启 WAL 模式，提高并发性能
    sqlite3_exec(self->_db, "PRAGMA journal_mode=WAL;", NULL, NULL, NULL);
    
    // 2. 获取版本
    int currentVersion = 0;
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(self->_db, "PRAGMA user_version;", -1, &stmt, NULL) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            currentVersion = sqlite3_column_int(stmt, 0);
        }
        sqlite3_finalize(stmt);
    }
    
    // 3. 根据版本判断是否需要 onCreate 或 onUpgrade
    if (currentVersion < kDatabaseVersion) {
        BOOL success = [self onCreateOrUpgrade:self->_db oldVersion:currentVersion newVersion:kDatabaseVersion];
        if (success) {
            // 更新版本号
            NSString *sql = [NSString stringWithFormat:@"PRAGMA user_version = %d;", kDatabaseVersion];
            sqlite3_exec(self->_db, [sql UTF8String], NULL, NULL, NULL);
        } else {
            
        }
    }
}

- (void)closeDatabase {
    dispatch_sync(self.dbQueue, ^{
        if (self.db) {
            sqlite3_close(self.db);
            self.db = NULL;
        }
    });
}

- (BOOL)onCreateOrUpgrade:(sqlite3 *)db oldVersion:(int)oldVer newVersion:(int)newVer {
    char *errMsg;
    
    // 如果是版本 0 (新安装或旧版SDK)，执行建表
    // 使用 IF NOT EXISTS 以兼容旧版 SDK 已创建表的情况，避免数据丢失
    if (newVer == 1) {
        NSString *createSQL = [NSString stringWithFormat:
                               @"CREATE TABLE IF NOT EXISTS %@ ("
                               @"%@ INTEGER PRIMARY KEY AUTOINCREMENT, "
                               @"%@ TEXT NOT NULL, "
                               @"%@ INTEGER NOT NULL);",
                               kTableName, kColId, kColData, kColCreatedAt];
        
        if (sqlite3_exec(db, [createSQL UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
            ZGLogError(@"Create table failed: %s", errMsg);
            sqlite3_free(errMsg);
            return NO;
        }
    }
    
    return YES;
}

// 检查是否文件损坏，如果损坏则重建
// 必须在 dbQueue 中调用
- (void)checkDatabaseCorruption {
    int errorCode = sqlite3_errcode(self.db);
    if (errorCode == SQLITE_CORRUPT || errorCode == SQLITE_NOTADB) {
        ZGLogError(@"Database corruption detected (code %d). Recreating...", errorCode);
        
        // 1. 关闭现有连接
        if (self.db) {
            sqlite3_close(self.db); // 即使失败也强制置空
            self.db = NULL;
        }
        
        // 2. 尝试删除数据库文件
        NSError *error = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.dbPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.dbPath error:&error];
            if (error) {
                ZGLogError(@"Failed to delete corrupted database: %@", error);
                return; // 删除失败，无法继续，避免死循环
            }
        }
        
        // 3. 重新初始化 (新建空库)
        [self openDatabaseInternal];
        
        ZGLogDebug(@"Database recreated successfully.");
    }
}

#pragma mark - Public Methods

- (void)addEvent:(NSDictionary *)event {
    if (!event) return;
    
    // 异步执行，将事件加入内存缓冲，不阻塞主线程
    dispatch_async(self.dbQueue, ^{
        if (self.pendingEvents.count >= kMaxPendingEvents) {
            // 丢弃最旧的，保留最新的
            [self.pendingEvents removeObjectAtIndex:0];
        }
                
        [self.pendingEvents addObject:event];
        
        if (!self.isFlushScheduled) {
            self.isFlushScheduled = YES;
            // 延迟 0.1 秒执行写入 (Debounce)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), self.dbQueue, ^{
                [self flushPendingEvents];
            });
        }
    });
}

-(void)addAllEvent:(NSArray *)array{
    if (!array || array.count == 0) return;
    // 异步执行，将事件加入内存缓冲，不阻塞主线程
    dispatch_async(self.dbQueue, ^{
        [self.pendingEvents addObjectsFromArray:array];
        //这是给内部的数据迁移使用的，不检查缓冲区溢出
        if (!self.isFlushScheduled) {
            self.isFlushScheduled = YES;
            // 为了保持与 addEvent 一致的 Debounce 机制，建议也稍微延迟一点，或者直接执行
            // 这里为了尽快写入批量数据，选择较短的延迟或直接执行。
            // 考虑到批量导入量大，直接 dispatch_after 0.1s 可以合并后续可能的碎片调用
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), self.dbQueue, ^{
                [self flushPendingEvents];
            });
        }
    });
}

// 必须在 dbQueue 中调用
- (void)flushPendingEvents {
    if (self.pendingEvents.count == 0) {
        self.isFlushScheduled = NO;
        return;
    }
    
    // 取出当前所有待写入事件
    NSArray *eventsToWrite = [self.pendingEvents copy];
    self.isFlushScheduled = NO;
    
    // 开启事务批量写入
    if (sqlite3_exec(self.db, "BEGIN TRANSACTION", 0, 0, 0) != SQLITE_OK) {
        [self checkDatabaseCorruption];
        [self scheduleFlushIfNeeded];
        return;
    }
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@) VALUES (?, ?);", kTableName, kColData, kColCreatedAt];
    sqlite3_stmt *stmt;
    BOOL allSuccess = YES;

    if (sqlite3_prepare_v2(self.db, [sql UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
        
        for (NSDictionary *event in eventsToWrite) {
            // JSON 序列化
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:event options:0 error:&error];
            if (error || !jsonData) continue;
            
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            if (!jsonString) continue;
            
            long long timestamp = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
            
            sqlite3_bind_text(stmt, 1, [jsonString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int64(stmt, 2, timestamp);
            
            if (sqlite3_step(stmt) != SQLITE_DONE) {
                ZGLogError(@"Batch insert error: %s", sqlite3_errmsg(self.db));
                allSuccess = NO;
                break;
            }
            sqlite3_reset(stmt); // 重置语句以便复用
        }
        
        sqlite3_finalize(stmt);
    } else {
        allSuccess = NO;
        ZGLogError(@"Prepare statement failed: %s", sqlite3_errmsg(self.db));
    }
    // 任意失败 → rollback
    if (!allSuccess) {
        sqlite3_exec(self.db, "ROLLBACK", 0, 0, 0);
        [self scheduleFlushIfNeeded];
        return;
    }
    // 提交事务
    if (sqlite3_exec(self.db, "COMMIT", 0, 0, 0) != SQLITE_OK) {
        ZGLogError(@"Commit failed: %s", sqlite3_errmsg(self.db));
        sqlite3_exec(self.db, "ROLLBACK", 0, 0, 0); // 确保事务关闭，以便下次重试
        [self checkDatabaseCorruption];
        [self scheduleFlushIfNeeded];
    } else {
        [self.pendingEvents removeAllObjects];
    }
}

-(void)scheduleFlushIfNeeded{
    if (self.isFlushScheduled) return;
    
    self.isFlushScheduled = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                   self.dbQueue, ^{
        [self flushPendingEvents];
    });
}

// 应用退出时的同步强制写入
- (void)handleWillTerminate {
    // 使用 dispatch_sync 确保应用退出前执行完毕
    dispatch_sync(self.dbQueue, ^{
        [self flushPendingEvents];
    });
}

- (NSDictionary *)getEvents {
    __block NSMutableDictionary *result = nil;
    
    dispatch_sync(self.dbQueue, ^{
        NSString *sql = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@ ORDER BY %@ ASC LIMIT %lu;", kColId, kColData, kTableName, kColId, (unsigned long)kMaxGetSize];
        sqlite3_stmt *stmt;
        
        if (sqlite3_prepare_v2(self.db, [sql UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
            NSMutableArray *events = [NSMutableArray array];
            NSNumber *lastIdNum = nil;
            
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                // 读取 ID (int64)
                long long rowId = sqlite3_column_int64(stmt, 0);
                lastIdNum = @(rowId);
                
                // 读取 Data
                char *dataChars = (char *)sqlite3_column_text(stmt, 1);
                if (dataChars) {
                    NSString *jsonString = [NSString stringWithUTF8String:dataChars];
                    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                    
                    if (jsonData) {
                        NSError *jsonError;
                        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];
                        if (jsonDict) {
                            [events addObject:jsonDict];
                        }
                    }
                }
            }
            sqlite3_finalize(stmt);
            
            if (events.count > 0 && lastIdNum) {
                result = [NSMutableDictionary dictionary];
                [result setObject:lastIdNum forKey:kZhugeDbLastId];
                [result setObject:events forKey:kZhugeDbData];
                ZGLogDebug(@"Get %lu data from event, last id is %@", (unsigned long)events.count, lastIdNum);
            }
        } else {
            [self checkDatabaseCorruption];
        }
    });
    
    return result;
}

- (void)removeEventsWithLastId:(NSNumber *)lastId {
    if (!lastId || ![lastId isKindOfClass:[NSNumber class]]) {
        return;
    }
    long long lastIdVal = [lastId longLongValue];
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ <= ?;", kTableName, kColId];
    
    dispatch_sync(self.dbQueue, ^{
        sqlite3_stmt *stmt;
        if (sqlite3_prepare_v2(self.db, [sql UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(stmt, 1, lastIdVal);
            
            if (sqlite3_step(stmt) == SQLITE_DONE) {
                int deletedCount = sqlite3_changes(self.db);
                ZGLogDebug(@"Deleted events <= id %lld, success. Delete count: %d", lastIdVal, deletedCount);
            } else {
                ZGLogError(@"Failed to delete events: %s", sqlite3_errmsg(self.db));
                [self checkDatabaseCorruption];
            }
            sqlite3_finalize(stmt);
        }
    });
}

- (NSUInteger)eventCount {
    __block NSUInteger count = 0;
    dispatch_sync(self.dbQueue, ^{
        count = [self countInternal];
    });
    ZGLogInfo(@"current event count, %lu",count);
    return count;
}

#pragma mark - Helper Methods

- (void)executeUpdate:(NSString *)sql {
    dispatch_sync(self.dbQueue, ^{
        [self executeUpdateInternal:sql];
    });
}

// 内部调用，不加锁，防止死锁
- (void)executeUpdateInternal:(NSString *)sql {
    char *errMsg;
    if (sqlite3_exec(self.db, [sql UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
        ZGLogError(@"SQL error: %s", errMsg);
        sqlite3_free(errMsg);
        [self checkDatabaseCorruption];
    }
}

// 内部调用
- (NSUInteger)countInternal {
    NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@", kTableName];
    sqlite3_stmt *stmt;
    NSUInteger count = 0;
    
    if (sqlite3_prepare_v2(self.db, [sql UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            count = (NSUInteger)sqlite3_column_int(stmt, 0);
        }
        sqlite3_finalize(stmt);
    }
    return count;
}
@end
