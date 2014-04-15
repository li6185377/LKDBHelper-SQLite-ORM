//
//  NSObject+LKDBHelper.m
//  LKDBHelper
//
//  Created by upin on 13-6-8.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import "NSObject+LKDBHelper.h"


@implementation NSObject(LKDBHelper)

+(void)dbDidCreateTable:(LKDBHelper *)helper{}

+(void)dbDidDeleted:(NSObject *)entity result:(BOOL)result{}
+(void)dbDidInserted:(NSObject *)entity result:(BOOL)result{}
+(void)dbDidUpdated:(NSObject *)entity result:(BOOL)result{}

+(BOOL)dbWillDelete:(NSObject *)entity{
    return YES;
}
+(BOOL)dbWillInsert:(NSObject *)entity{
    return YES;
}
+(BOOL)dbWillUpdate:(NSObject *)entity{
    return YES;
}

#pragma mark - simplify synchronous function
+(BOOL)checkModelClass:(NSObject*)model
{
    if([model isMemberOfClass:self])
        return YES;
    
    NSLog(@"%@ can not use %@",NSStringFromClass(self),NSStringFromClass(model.class));
    return NO;
}

+(int)rowCountWithWhere:(id)where{
    return [[self getUsingLKDBHelper] rowCount:self where:where];
}
+(NSMutableArray *)searchColumn:(id)columns where:(id)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count
{
    return [[self getUsingLKDBHelper] search:self column:columns where:where orderBy:orderBy offset:offset count:count];
}
+(NSMutableArray*)searchWithWhere:(id)where orderBy:(NSString*)orderBy offset:(int)offset count:(int)count{
    return [[self getUsingLKDBHelper] search:self where:where orderBy:orderBy offset:offset count:count];
}
+(id)searchSingleWithWhere:(id)where orderBy:(NSString *)orderBy
{
    return [[self getUsingLKDBHelper] searchSingle:self where:where orderBy:orderBy];
}

+(BOOL)insertToDB:(NSObject*)model{
    
    if([self checkModelClass:model])
    {
        return [[self getUsingLKDBHelper] insertToDB:model];
    }
    return NO;
    
}
+(BOOL)insertWhenNotExists:(NSObject*)model{
    if([self checkModelClass:model])
    {
        return [[self getUsingLKDBHelper] insertWhenNotExists:model];
    }
    return NO;
}
+(BOOL)updateToDB:(NSObject *)model where:(id)where{
    if([self checkModelClass:model])
    {
        return [[self getUsingLKDBHelper] updateToDB:model where:where];
    }
    return NO;
}
+(BOOL)updateToDBWithSet:(NSString *)sets where:(id)where
{
    return [[self getUsingLKDBHelper] updateToDB:self set:sets where:where];
}
+(BOOL)deleteToDB:(NSObject*)model{
    if([self checkModelClass:model])
    {
        return [[self getUsingLKDBHelper] deleteToDB:model];
    }
    return NO;
}
+(BOOL)deleteWithWhere:(id)where{
    return [[self getUsingLKDBHelper] deleteWithClass:self where:where];
}
+(BOOL)isExistsWithModel:(NSObject *)model
{
    if([self checkModelClass:model])
    {
        return [[self getUsingLKDBHelper] isExistsModel:model];
    }
    return NO;
}

- (BOOL)saveToDB
{
    return [self.class insertToDB:self];
}
- (BOOL)deleteToDB
{
    return [self.class deleteToDB:self];
}
-(BOOL)isExistsFromDB
{
    return [self.class isExistsWithModel:self];
}
@end