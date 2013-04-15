//
//  LKDALBase.h
//  CarDaMan
//
//  Created by y h on 12-10-8.
//  Copyright (c) 2012年 LK. All rights reserved.
//

#import <Foundation/Foundation.h>


@class FMDatabase,FMResultSet,FMDatabaseQueue;




@interface NSObject(LKModelBase)
/**
 *	@brief  该类的所有属性
            是否上溯到NSObject类（不会获取NSObject 的属性）由isContainParent 方法返回  可在子类种重载此方法
 *
 *	@return	返回 该类的所有属性
 */
+(NSDictionary*)getPropertys;

/**
 *	@brief	设置getPropertys方法 是否上溯到 父类
 * 
 *  @return
 */
+(BOOL)isContainParent;

/**
 *	@brief	主键名称 如果rowid<0 则跟据此名称update 和delete
 */
+(NSString*)primaryKey;


/**
 *	@brief	打印所有的属性名称和数据
 */
-(void)printAllPropertys;

/**
 *	@brief   sqlite 中存储的rowid
 */
@property int rowid;
@end

@interface LKDAOBase : NSObject


-(id)initWithDBQueue:(FMDatabaseQueue*)queue;
@property(retain,nonatomic)FMDatabaseQueue* bindingQueue;
@property(retain,nonatomic)NSMutableDictionary* propertys;  //绑定的model属性集合
@property(retain,nonatomic)NSMutableArray* columeNames; //列名
@property(retain,nonatomic)NSMutableArray* columeTypes; //列类型

-(void)executeDB:(void (^)(FMDatabase *db))block; //同步执行 数据库操作

//清楚创建表的历史记录
+(void)clearCreateHistory;
//返回表名  所有 Dao 都必须重载此方法
+(NSString*)getTableName;

//返回绑定的Model Class
+(Class)getBindingModelClass;

//返回 create table parameter 语句
-(NSString*)getParameterString;

//创建数据库
-(void)createTable;

-(int)rowCountWhere:(id)where;
//where 支持 dic 和 string  两种类型
-(void)rowCount:(void(^)(int))callback where:(id)where;

//基本sql语句  where 条件 要自己写  比如  @"rowid = 2"
-(void)searchWhere:(NSString*)where orderBy:(NSString*)columeName offset:(int)offset count:(int)count callback:(void(^)(NSArray*))block;
-(NSArray*)searchWhere:(NSString *)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count;

//查询的条件以 key-value 模式传入
-(void)searchWhereDic:(NSDictionary*)where orderBy:(NSString *)orderby offset:(int)offset count:(int)count callback:(void (^)(NSArray *))block;
-(NSArray*)searchWhereDic:(NSDictionary*)where orderBy:(NSString *)orderby offset:(int)offset count:(int)count;

//把 model 插入到 数据库
-(void)insertToDB:(NSObject*)model callback:(void(^)(BOOL))block;
-(BOOL)insertToDB:(NSObject*)model;

//根据条件更新   当where 传 nil 时  根据 rowid 或者 primary 列的值
-(void)updateToDB:(NSObject *)model where:(id)where callback:(void (^)(BOOL))block;
-(BOOL)updateToDB:(NSObject *)model where:(id)where;

//删除
-(void)deleteToDB:(NSObject*)model callback:(void(^)(BOOL))block;
//根据where 条件删除数据
-(void)deleteToDBWithWhere:(NSString*)where callback:(void (^)(BOOL))block;
-(void)deleteToDBWithWhereDic:(NSDictionary*)where callback:(void (^)(BOOL))block;


//当 NSDictionary 的value 是NSArray 类型时  使用 in 语句   where  name in (value1,value2)

//清空表数据
-(void)clearTableData;

-(void)isExistsModel:(NSObject*)model callback:(void(^)(BOOL))block;
-(BOOL)isExistsModel:(NSObject*)model;

-(void)isExistsWithWhere:(NSString*)where callback:(void (^)(BOOL))block;
-(BOOL)isExistsWithWhere:(NSString *)where;



//判断string 是否为 nil 或 空字符串
+(BOOL)checkStringNotEmpty:(NSString*)string;

//当 model 的属性值为nil 时  返回 @""  可重载 更改返回参数值
-(id)safetyGetModel:(NSObject*) model valueKey:(NSString*)valueKey;
//给子类或者 扩展类 重载用  一般用于 NSArray 和 NSDictionary 转成JSON 进行存储
-(void)safetySetModel:(NSObject*)model key:(NSString*)key value:(id)value type:(NSString*)type;
@end
