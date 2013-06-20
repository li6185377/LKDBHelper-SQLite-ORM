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
+(BOOL)isExistsWithModel:(NSObject*)model;

- (void)saveToDB;
- (void)deleteToDB;
@end