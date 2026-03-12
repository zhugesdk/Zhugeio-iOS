#import <Foundation/Foundation.h>

extern NSString *const kZhugeDbData;
extern NSString *const kZhugeDbLastId;

@interface ZhugeDbAdapter : NSObject

/**
 * 初始化数据库适配器
 * 数据库文件将命名为: zhuge_{appKey}.sqlite
 */
- (instancetype)initWithAppKey:(NSString *)appKey;

/**
 * 添加事件到数据库 (异步执行)
 *
 * @param event 要存储的事件字典 (将被转换为 JSON 字符串存储)
 */
- (void)addEvent:(NSDictionary *)event;

-(void)addAllEvent:(NSArray *)array;
/**
 * 获取最近的 50 条事件
 *
 * @return 一个字典，包含两个 key:
 *         @"last_id": (NSNumber) 当次读取的最后一条数据的 ID，用于删除。
 *         @"data": (NSArray) 包含解析后的 NSDictionary 事件数组。
 *         如果无数据返回 nil。
 */
- (NSDictionary *)getEvents;

/**
 * 删除指定 ID 及其之前的事件
 *
 * @param lastId getEvents 返回的 last_id (NSNumber)
 */
- (void)removeEventsWithLastId:(NSNumber *)lastId;

- (void)handleWillTerminate;

/**
 * 获取事件总数
 */
- (NSUInteger)eventCount;

@end
