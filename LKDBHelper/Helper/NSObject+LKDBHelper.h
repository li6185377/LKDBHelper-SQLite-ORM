//
//  NSObject+LKDBHelper.h
//  LKDBHelper
//
//  Created by LJH on 13-6-8.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LKDBHelper.h"

@class LKDBHelper;

@interface NSObject(LKDBHelper_Delegate)

+(void)dbDidCreateTable:(LKDBHelper*)helper tableName:(NSString*)tableName;
+(void)dbDidAlterTable:(LKDBHelper*)helper tableName:(NSString*)tableName addColumns:(NSArray*)columns;

+(BOOL)dbWillInsert:(NSObject*)entity;
+(void)dbDidInserted:(NSObject*)entity result:(BOOL)result;

+(BOOL)dbWillUpdate:(NSObject*)entity;
+(void)dbDidUpdated:(NSObject*)entity result:(BOOL)result;

+(BOOL)dbWillDelete:(NSObject*)entity;
+(void)dbDidDeleted:(NSObject*)entity result:(BOOL)result;

///data read finish
+(void)dbDidSeleted:(NSObject*)entity;

@end

//only simplify synchronous function
@interface NSObject(LKDBHelper_Execute)

/**
 *  返回行数
 *
 *  @param where type can NSDictionary or NSString
 *
 *  @return  row count
 */
+(NSInteger)rowCountWithWhere:(id)where,...;
+(NSInteger)rowCountWithWhereFormat:(id)where,...;

/**
 *  搜索
 *
 *  @param columns type can NSArray or NSString(Search for a specific column.  Search only one, only to return the contents of the column collection)
 
 *  @param where   where type can NSDictionary or NSString
 *  @param orderBy
 *  @param offset
 *  @param count
 *
 *  @return model collection  or   contents of the columns collection
 */
+(NSMutableArray*)searchColumn:(id)columns where:(id)where orderBy:(NSString*)orderBy offset:(NSInteger)offset count:(NSInteger)count;
+(NSMutableArray*)searchWithWhere:(id)where orderBy:(NSString*)orderBy offset:(NSInteger)offset count:(NSInteger)count;
+(id)searchSingleWithWhere:(id)where orderBy:(NSString*)orderBy;

+(BOOL)insertToDB:(NSObject*)model;
+(BOOL)insertWhenNotExists:(NSObject*)model;
+(BOOL)updateToDB:(NSObject *)model where:(id)where,...;
+(BOOL)updateToDBWithSet:(NSString*)sets where:(id)where,...;
+(BOOL)deleteToDB:(NSObject*)model;
+(BOOL)deleteWithWhere:(id)where,...;
+(BOOL)isExistsWithModel:(NSObject*)model;

- (BOOL)updateToDB;
- (BOOL)saveToDB;
- (BOOL)deleteToDB;
- (BOOL)isExistsFromDB;

@end