//
//  NSObject+LKDBHelper.m
//  LKDBHelper
//
//  Created by LJH on 13-6-8.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import "NSObject+LKDBHelper.h"

@implementation NSObject (LKDBHelper_Delegate)

+(void)dbDidCreateTable:(LKDBHelper *)helper tableName:(NSString*)tableName{}
+(void)dbDidAlterTable:(LKDBHelper*)helper tableName:(NSString*)tableName addColumns:(NSArray*)columns{}

+(void)dbDidInserted:(NSObject *)entity result:(BOOL)result{}
+(void)dbDidDeleted:(NSObject *)entity result:(BOOL)result{}
+(void)dbDidUpdated:(NSObject *)entity result:(BOOL)result{}
+(void)dbDidSeleted:(NSObject *)entity{}

+(BOOL)dbWillDelete:(NSObject *)entity{
    return YES;
}
+(BOOL)dbWillInsert:(NSObject *)entity{
    return YES;
}
+(BOOL)dbWillUpdate:(NSObject *)entity{
    return YES;
}
@end

@implementation NSObject(LKDBHelper)

#pragma mark - simplify synchronous function
+(BOOL)checkModelClass:(NSObject*)model
{
    if([model isMemberOfClass:self])
        return YES;
    
    NSLog(@"%@ can not use %@",NSStringFromClass(self),NSStringFromClass(model.class));
    return NO;
}
+(NSInteger)rowCountWithWhereFormat:(id)where, ...
{
    if ([where isKindOfClass:[NSString class]])
    {
        va_list list;
        va_start(list, where);
        where = [[NSString alloc]initWithFormat:where arguments:list];
        va_end(list);
    }
    return [[self getUsingLKDBHelper] rowCount:self where:where];
}
+(NSInteger)rowCountWithWhere:(id)where, ...
{
    if ([where isKindOfClass:[NSString class]])
    {
        va_list list;
        va_start(list, where);
        where = [[NSString alloc]initWithFormat:where arguments:list];
        va_end(list);
    }
    return [[self getUsingLKDBHelper] rowCount:self where:where];
}
+(NSMutableArray *)searchColumn:(id)columns where:(id)where orderBy:(NSString *)orderBy offset:(NSInteger)offset count:(NSInteger)count
{
    return [[self getUsingLKDBHelper] search:self column:columns where:where orderBy:orderBy offset:offset count:count];
}
+(NSMutableArray*)searchWithWhere:(id)where orderBy:(NSString*)orderBy offset:(NSInteger)offset count:(NSInteger)count{
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
+(BOOL)updateToDB:(NSObject *)model where:(id)where,...
{
    if([self checkModelClass:model])
    {
        if ([where isKindOfClass:[NSString class]])
        {
            va_list list;
            va_start(list, where);
            where = [[NSString alloc]initWithFormat:where arguments:list];
            va_end(list);
        }
        return [[self getUsingLKDBHelper] updateToDB:model where:where];
    }
    return NO;
}
+(BOOL)updateToDBWithSet:(NSString *)sets where:(id)where,...
{
    if ([where isKindOfClass:[NSString class]])
    {
        va_list list;
        va_start(list, where);
        where = [[NSString alloc]initWithFormat:where arguments:list];
        va_end(list);
    }
    return [[self getUsingLKDBHelper] updateToDB:self set:sets where:where];
}
+(BOOL)deleteToDB:(NSObject*)model
{
    if([self checkModelClass:model])
    {
        return [[self getUsingLKDBHelper] deleteToDB:model];
    }
    return NO;
}
+(BOOL)deleteWithWhere:(id)where,...
{
    if ([where isKindOfClass:[NSString class]])
    {
        va_list list;
        va_start(list, where);
        where = [[NSString alloc]initWithFormat:where arguments:list];
        va_end(list);
    }
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

-(BOOL)updateToDB
{
    if(self.rowid > 0)
    {
        return [self.class updateToDB:self where:nil];
    }
    else
    {
        return [self saveToDB];
    }
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