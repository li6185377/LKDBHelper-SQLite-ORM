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

+(void)dbDidIDeleted:(NSObject *)entity result:(BOOL)result{}
+(void)dbWillDelete:(NSObject *)entity{}

+(void)dbDidInserted:(NSObject *)entity result:(BOOL)result{}
+(void)dbWillInsert:(NSObject *)entity{}

+(void)dbDidUpdated:(NSObject *)entity result:(BOOL)result{}
+(void)dbWillUpdate:(NSObject *)entity{}

#pragma mark - simplify synchronous function
+(BOOL)checkModelClass:(NSObject*)model
{
    if([model isKindOfClass:self])
        return YES;
    
    NSLog(@"%@ can not use %@",NSStringFromClass(self),NSStringFromClass(model.class));
    return NO;
}

+(int)rowCountWithWhere:(id)where{
    return [[self getUsingLKDBHelper] rowCount:self where:where];
}

+(NSMutableArray*)searchWithWhere:(id)where orderBy:(NSString*)orderBy offset:(int)offset count:(int)count{
    return [[self getUsingLKDBHelper] search:self where:where orderBy:orderBy offset:offset count:count];
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

- (void)saveToDB
{
    [self.class insertToDB:self];
}

- (void)deleteToDB
{
    [self.class deleteToDB:self];
}
@end