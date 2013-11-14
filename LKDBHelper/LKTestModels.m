//
//  LKTestModels.m
//  LKDBHelper
//
//  Created by upin on 13-7-12.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import "LKTestModels.h"

@implementation LKTest

//在类 初始化的时候
+(void)initialize
{
    //remove unwant property
    //比如 getTableMapping 返回nil 的时候   会取全部属性  这时候 就可以 用这个方法  移除掉 不要的属性
    [self removePropertyWithColumeName:@"error"];
    
    
    //simple set a colume as "LKSQLUserCalculate"
    //根据 属性名  来启用自己计算
    //[self setUserCalculateForCN:@"error"];
    
    
    //根据 属性类型  来启用自己计算
    //[self setUserCalculateForPTN:@"NSDictionary"];
}

// 将要插入数据库
+(void)dbWillInsert:(NSObject *)entity
{
    LKErrorLog(@"will insert : %@",NSStringFromClass(self));
}
//已经插入数据库
+(void)dbDidInserted:(NSObject *)entity result:(BOOL)result
{
    LKErrorLog(@"did insert : %@",NSStringFromClass(self));
}

// 重载    返回自己处理过的 要插入数据库的值
-(id)userGetValueForModel:(LKDBProperty *)property
{
    if([property.sqlColumeName isEqualToString:@"address"])
    {
        if(self.address == nil)
            return @"";
        [LKTestForeign insertToDB:self.address];
        return @(self.address.addid);
    }
    return nil;
}
// 重载    从数据库中  获取的值   经过自己处理 再保存
-(void)userSetValueForModel:(LKDBProperty *)property value:(id)value
{
    if([property.sqlColumeName isEqualToString:@"address"])
    {
        self.address = nil;
        
        NSMutableArray* array  = [LKTestForeign searchWithWhere:[NSString stringWithFormat:@"addid = %d",[value intValue]] orderBy:nil offset:0 count:1];
        
        if(array.count>0)
            self.address = [array objectAtIndex:0];
    }
}

//列属性
+(void)columeAttributeWithProperty:(LKDBProperty *)property
{
    if([property.sqlColumeName isEqualToString:@"MyAge"])
    {
        property.defaultValue = @"15";
    }
    else if([property.propertyName isEqualToString:@"date"])
    {
        // if you use unique,this property will also become the primary key
//        property.isUnique = YES;
        property.checkValue = @"MyDate > '2000-01-01 00:00:00'";
        property.length = 30;
    }
}

//手动 绑定sql列
+(NSDictionary *)getTableMapping
{
    //return nil
    return @{@"name":LKSQLInherit,
             @"MyAge":@"age",
             @"img":LKSQLInherit,
             @"MyDate":@"date",
             
             // version 2 after add
             @"color":LKSQLInherit,
             
             //version 3 after add
             @"address":LKSQLUserCalculate,
             @"error":LKSQLInherit
             };
}
//主键
+(NSString *)getPrimaryKey
{
    return @"name";
}
+(NSArray *)getPrimaryKeyUnionArray
{
    return @[@"name",@"MyAge"];
}
//表名
+(NSString *)getTableName
{
    return @"LKTestTable";
}
//表版本
+(int)getTableVersion
{
    return 3;
}
//升级
+(LKTableUpdateType)tableUpdateForOldVersion:(int)oldVersion newVersion:(int)newVersion
{
    switch (oldVersion) {
        case 1:
        {
            [self tableUpdateAddColumeWithPN:@"color"];
        }
        case 2:
        {
            [self tableUpdateAddColumeWithName:@"address" sqliteType:LKSQLText];
            //@"error" is removed
        }
            break;
    }
    return LKTableUpdateTypeCustom;
}
@end


@implementation LKTestForeign
+(NSString *)getPrimaryKey
{
    return @"addid";
}
+(NSString *)getTableName
{
    return @"LKTestAddress";
}
+(int)getTableVersion
{
    return 1;
}
@end





@implementation NSObject(PrintSQL)

+(NSString *)getCreateTableSQL
{
    LKModelInfos* infos = [self getModelInfos];
    NSString* primaryKey = [self getPrimaryKey];
    NSMutableString* table_pars = [NSMutableString string];
    for (int i=0; i<infos.count; i++) {
        
        if(i > 0)
            [table_pars appendString:@","];
        
        LKDBProperty* property =  [infos objectWithIndex:i];
        [self columeAttributeWithProperty:property];
        
        [table_pars appendFormat:@"%@ %@",property.sqlColumeName,property.sqlColumeType];
        
        if([property.sqlColumeType isEqualToString:LKSQLText])
        {
            if(property.length>0)
            {
                [table_pars appendFormat:@"(%d)",property.length];
            }
        }
        if(property.isNotNull)
        {
            [table_pars appendFormat:@" %@",LKSQLNotNull];
        }
        if(property.isUnique)
        {
            [table_pars appendFormat:@" %@",LKSQLUnique];
        }
        if(property.checkValue)
        {
            [table_pars appendFormat:@" %@(%@)",LKSQLCheck,property.checkValue];
        }
        if(property.defaultValue)
        {
            [table_pars appendFormat:@" %@ %@",LKSQLDefault,property.defaultValue];
        }
        if(primaryKey && [property.sqlColumeName isEqualToString:primaryKey])
        {
            [table_pars appendFormat:@" %@",LKSQLPrimaryKey];
        }
    }
    NSString* createTableSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@)",[self getTableName],table_pars];
    return createTableSQL;
}

@end