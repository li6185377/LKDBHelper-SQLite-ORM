//
//  NSObject+LKDBHelper.h
//  LKDBHelper
//
//  Created by upin on 13-6-8.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LKDBHelper.h"

@class LKDBHelper;
@interface NSObject(LKDBHelper)

//callback delegate
+(void)dbDidCreateTable:(LKDBHelper*)helper;

+(BOOL)dbWillInsert:(NSObject*)entity;
+(void)dbDidInserted:(NSObject*)entity result:(BOOL)result;

+(BOOL)dbWillUpdate:(NSObject*)entity;
+(void)dbDidUpdated:(NSObject*)entity result:(BOOL)result;

+(BOOL)dbWillDelete:(NSObject*)entity;
+(void)dbDidDeleted:(NSObject*)entity result:(BOOL)result;


//only simplify synchronous function
+(int)rowCountWithWhere:(id)where;

+(NSMutableArray*)searchColumn:(id)columns where:(id)where orderBy:(NSString*)orderBy offset:(int)offset count:(int)count;
+(NSMutableArray*)searchWithWhere:(id)where orderBy:(NSString*)orderBy offset:(int)offset count:(int)count;
+(id)searchSingleWithWhere:(id)where orderBy:(NSString*)orderBy;

+(BOOL)insertToDB:(NSObject*)model;
+(BOOL)insertWhenNotExists:(NSObject*)model;
+(BOOL)updateToDB:(NSObject *)model where:(id)where;
+(BOOL)updateToDBWithSet:(NSString*)sets where:(id)where;
+(BOOL)deleteToDB:(NSObject*)model;
+(BOOL)deleteWithWhere:(id)where;
+(BOOL)isExistsWithModel:(NSObject*)model;

- (BOOL)saveToDB;
- (BOOL)deleteToDB;
- (BOOL)isExistsFromDB;

@end