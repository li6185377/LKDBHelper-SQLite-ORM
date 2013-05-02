//
//  LKDBHelper.h
//  upin
//
//  Created by Fanhuan on 12-12-6.
//  Copyright (c) 2012年 linggan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "LKDBUtils.h"
#import "NSObject+LKModel.h"

@interface LKDBHelper : NSObject
+(LKDBHelper*)sharedDBHelper;
//更换 数据库
-(void)setDBName:(NSString*)fileName;
//获得绑定的 fmdb queue
-(FMDatabaseQueue*)getBindingQueue;
//可获取 所有 通过LKDBHelper 创建的表名 和版本号
-(NSMutableDictionary*)getTableManager;
@end

@interface LKDBHelper(DatabaseManager)
//根据model 创建表
-(void)createTableWithModelClass:(Class)model;

//同步执行 数据库操作
-(void)executeDB:(void (^)(FMDatabase *db))block;

//删除全部表
-(void)dropAllTable;
//删除指定表
-(void)dropTableWithClass:(Class)modelClass;
+(NSString*)toDBType:(NSString*)type; //把Object-c 类型 转换为sqlite 类型
@end

@interface LKDBHelper(DatabaseExecute)
/**
 *	@brief	查询相应model 对应的表 的行数
 *
 *	@param 	modelClass      实体类
 *	@param 	where           约束:  可以是 NSString 或者 NSDictionary
 *
 *	@return	查询出来的行数
 */
-(int)rowCount:(Class)modelClass where:(id)where;
-(void)rowCount:(Class)modelClass where:(id)where callback:(void(^)(int))callback;

/**
 *	@brief	查询相应model 对应的表
 *
 *	@param 	modelClass      实体类
 *	@param 	where           约束:  可以是 NSString 或者 NSDictionary
 *	@param 	orderBy         排序  升序 asc 降序 desc   比如 可以传 @"rowid desc"
 *	@param 	offset          跳过多少行
 *	@param 	count           提取多少行
 *
 *	@return	返回查询完的 结果  是一个数组
 */
-(NSMutableArray*)search:(Class)modelClass where:(id)where orderBy:(NSString*)orderBy offset:(int)offset count:(int)count;
-(void)search:( Class)modelClass where:(id)where orderBy:(NSString*)orderBy offset:(int)offset count:(int)count callback:(void(^)(NSMutableArray*))block;


/**
 *	@brief	把实体 插入到相应的实体类表
 *
 *	@param 	model 	要插入的实体类
 *
 *	@return	插入是否成功
 */
-(BOOL)insertToDB:(NSObject*)model;
-(void)insertToDB:(NSObject*)model callback:(void(^)(BOOL))block;

/**
 *	@brief	当实体 主键不存在的时候 插入
 *
 *	@param 	model 	要插入的实体类
 *
 *	@return	插入是否成功
 */
-(BOOL)insertWhenNotExists:(NSObject*)model;
-(void)insertWhenNotExists:(NSObject*)model callback:(void(^)(BOOL))block;

/**
 *	@brief 根据条件更新   当where 传 nil 时  根据 rowid 或者 primary 列的值 更新数据
 *
 *	@param 	model 	要更新的实体类
 *	@param 	where 	约束:  可以是 NSString 或者 NSDictionary
 *
 *	@return	更新是否成功
 */
-(BOOL)updateToDB:(NSObject *)model where:(id)where;
-(void)updateToDB:(NSObject *)model where:(id)where callback:(void (^)(BOOL))block;


/**
 *	@brief	删除相应的数据  如果rowid == 0  会根据primary key 来删除
 *
 *	@param 	model 	要删除的 实体类类
 *
 *	@return	是否 删除成功
 */
-(BOOL)deleteToDB:(NSObject*)model;
-(void)deleteToDB:(NSObject*)model callback:(void(^)(BOOL))block;

/**
 *	@brief	根据where 条件删除数据
 *
 *	@param 	modelClass      相应的class
 *	@param 	where           约束:  可以是 NSString 或者 NSDictionary
 *
 *	@return	是否执行成功
 */
-(BOOL)deleteWithClass:(Class)modelClass where:(id)where;
-(void)deleteWithClass:(Class)modelClass where:(id)where callback:(void (^)(BOOL))block;

/**
 *	@brief  直接判断primary key 的值是否存在  （如果有rowid 就肯定存在 所以就不用rowid 判断了）
 *
 *	@param 	model 	查询的model
 *
 *	@return	是否有数据
 */
-(BOOL)isExistsModel:(NSObject*)model;
-(BOOL)isExistsClass:(Class)modelClass where:(id)where;


/**
 *	@brief	根据 实体类 清空数据
 *
 *	@param 	modelClass 	实体类
 */
-(void)clearTableData:(Class)modelClass;

-(void)clearNoneImage:(Class)modelClass columes:(NSArray*)columes;
-(void)clearNoneData:(Class)modelClass columes:(NSArray*)columes;
@end



