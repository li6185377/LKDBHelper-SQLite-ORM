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

/**
 
 Description of parameters "where"
 For example: 
        single:  @"rowid = 1"                         or      @{@"rowid":@1}
 
        more:    @"rowid = 1 and sex = 0"             or      @{@"rowid":@1,@"sex":@0}
                   
                    when where is "or" type , such as @"rowid = 1 or sex = 0"
                    you only use NSString
 
        array:   @"rowid in (1,2,3)"                  or      @{@"rowid":@[@1,@2,@3]}
            
        composite:  @"rowid in (1,2,3) and sex=0 "      or      @{@"rowid":@[@1,@2,@3],@"sex":@0}
 
        If you want to be judged , only use NSString
        For example: @"date >= '2013-04-01 00:00:00'"
*/

@interface LKDBHelper : NSObject

+(LKDBHelper*)sharedDBHelper;

//change database filepath : "documents/db/" + fileName + ".db"
-(void)setDBName:(NSString*)fileName;

/**
 *	@brief  execute database operations synchronously,not afraid of recursive deadlock  同步执行数据库操作 可递归调用
 */
-(void)executeDB:(void (^)(FMDatabase *db))block;

//get all by LKDBHelper create table name and version number
-(NSMutableDictionary*)getTableManager;
@end

@interface LKDBHelper(DatabaseManager)

//create table with entity class
-(void)createTableWithModelClass:(Class)model;

//drop all table
-(void)dropAllTable;

//drop table with entity class
-(void)dropTableWithClass:(Class)modelClass;

//Object-c type converted to SQLite type    把Object-c 类型 转换为sqlite 类型
+(NSString*)toDBType:(NSString*)type;
@end

@interface LKDBHelper(DatabaseExecute)

/**
 *	@brief	The number of rows query table
 *
 *	@param 	modelClass      entity class
 *	@param 	where           can use NSString or NSDictionary or nil
 *
 *	@return	rows number
 */
-(int)rowCount:(Class)modelClass where:(id)where;
-(void)rowCount:(Class)modelClass where:(id)where callback:(void(^)(int rowCount))callback;

/**
 *	@brief	query table
 *
 *	@param 	modelClass      entity class
 *	@param 	where           can use NSString or NSDictionary or nil
 
 *	@param 	orderBy         The Sort: Ascending "name asc",Descending "name desc"
                            For example: @"rowid desc"  or @"rowid asc"
 
 *	@param 	offset          Skip how many rows
 *	@param 	count           Limit the number
 *
 *	@return	query finished result is an array(model instance collection)
 */
-(NSMutableArray*)search:(Class)modelClass where:(id)where orderBy:(NSString*)orderBy offset:(int)offset count:(int)count;
-(void)search:( Class)modelClass where:(id)where orderBy:(NSString*)orderBy offset:(int)offset count:(int)count callback:(void(^)(NSMutableArray* array))block;


/**
 *	@brief	insert table
 *
 *	@param 	model 	you want to insert the entity
 *
 *	@return	the inserted was successful
 */
-(BOOL)insertToDB:(NSObject*)model;
-(void)insertToDB:(NSObject*)model callback:(void(^)(BOOL result))block;

/**
 *	@brief	insert when the entity primary key does not exist
 *
 *	@param 	model 	you want to insert the entity
 *
 *	@return	the inserted was successful
 */
-(BOOL)insertWhenNotExists:(NSObject*)model;
-(void)insertWhenNotExists:(NSObject*)model callback:(void(^)(BOOL result))block;

/**
 *	@brief update table
 *
 *	@param 	model 	you want to update the entity
 *	@param 	where 	can use NSString or NSDictionary or nil
                    when "where" is nil : update the value based on rowid colume or primary key colume
 *
 *	@return	the updated was successful
 */
-(BOOL)updateToDB:(NSObject *)model where:(id)where;
-(void)updateToDB:(NSObject *)model where:(id)where callback:(void (^)(BOOL result))block;
-(BOOL)updateToDB:(Class)modelClass set:(NSString*)sets where:(id)where;
/**
 *	@brief	delete table
 *
 *	@param 	model 	you want to delete entity
                    when entity property "rowid" == 0  based on the primary key to delete
 *
 *	@return	the deleted was successful
 */
-(BOOL)deleteToDB:(NSObject*)model;
-(void)deleteToDB:(NSObject*)model callback:(void(^)(BOOL result))block;

/**
 *	@brief	delete table with "where" constraint
 *
 *	@param 	modelClass      entity class
 *	@param 	where           can use NSString or NSDictionary,  can not is nil
 *
 *	@return	the deleted was successful
 */
-(BOOL)deleteWithClass:(Class)modelClass where:(id)where;
-(void)deleteWithClass:(Class)modelClass where:(id)where callback:(void (^)(BOOL result))block;

/**
 *	@brief   entity exists?
 *           for primary key colume 
            （if rowid > 0 would certainly exist so we do not rowid judgment）
 *	@param 	model 	entity
 *
 *	@return	YES: entity presence , NO: entity not exist
 */
-(BOOL)isExistsModel:(NSObject*)model;
-(BOOL)isExistsClass:(Class)modelClass where:(id)where;


/**
 *	@brief	Clear data based on the entity class
 *
 *	@param 	modelClass 	entity class
 */
-(void)clearTableData:(Class)modelClass;

   
/**
 *	@brief	Clear Unused Data File
            if you property has UIImage or NSData, will save their data in the (documents dir)
 *
 *	@param 	modelClass      entity class
 *	@param 	columes         UIImage or NSData Colume Name
 */
-(void)clearNoneImage:(Class)modelClass columes:(NSArray*)columes;
-(void)clearNoneData:(Class)modelClass columes:(NSArray*)columes;
@end


/*
    usage look LKDBHelper similar name funcation
    add entity class verification
*/
@interface NSObject(LKDBHelper)

//callback delegate
+(void)dbDidCreateTable:(LKDBHelper*)helper;

+(void)dbWillInsert:(NSObject*)entity;
+(void)dbDidInserted:(NSObject*)entity result:(BOOL)result;

+(void)dbWillUpdate:(NSObject*)entity;
+(void)dbDidUpdated:(NSObject*)entity result:(BOOL)result;

+(void)dbWillDelete:(NSObject*)entity;
+(void)dbDidIDeleted:(NSObject*)entity result:(BOOL)result;

//only simplify synchronous function
+(int)rowCountWithWhere:(id)where;
+(NSMutableArray*)searchWithWhere:(id)where orderBy:(NSString*)orderBy offset:(int)offset count:(int)count;
+(BOOL)insertToDB:(NSObject*)model;
+(BOOL)insertWhenNotExists:(NSObject*)model;
+(BOOL)updateToDB:(NSObject *)model where:(id)where;
+(BOOL)updateToDBWithSet:(NSString*)sets where:(id)where;
+(BOOL)deleteToDB:(NSObject*)model;
+(BOOL)deleteWithWhere:(id)where;
@end

