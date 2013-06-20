//
//  LKDBProperty+KeyMapping.m
//  LKDBHelper
//
//  Created by upin on 13-6-17.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import "LKDB+Mapping.h"

inline NSString *LKSQLTypeFromObjcType(NSString* objcType)
{
    if([LKSQLIntType rangeOfString:objcType].location != NSNotFound){
        return LKSQLInt;
    }
    if ([LKSQLFloatType rangeOfString:objcType].location != NSNotFound) {
        return LKSQLDouble;
    }
    if ([LKSQLBlobType rangeOfString:objcType].location != NSNotFound) {
        return LKSQLBlob;
    }
    
    return LKSQLText;
}

@implementation NSObject(TableMapping)
+(NSDictionary *)getTableMapping
{
    return nil;
}
@end

@interface LKDBProperty()
{
    __strong NSString* _type;
    
    __strong NSString* _sqlColumeName;
    __strong NSString* _sqlColumeType;
    
    __strong NSString* _propertyName;
    __strong NSString* _propertyType;
}
-(id)initWithType:(NSString*)type cname:(NSString*)cname ctype:(NSString*)ctype pname:(NSString*)pname ptype:(NSString*)ptype;
@end
@implementation LKDBProperty

//@synthesize type= _type;
//@synthesize sqlColumeName=_sqlColumeName;
//@synthesize sqlColumeType = _sqlColumeType;
//@synthesize propertyName=_propertyName;
//@synthesize propertyType=_propertyType;

-(id)initWithType:(NSString *)type cname:(NSString *)cname ctype:(NSString *)ctype pname:(NSString *)pname ptype:(NSString *)ptype
{
    self = [super init];
    if(self)
    {
        _type = type;
        _sqlColumeName = cname;
        _sqlColumeType = ctype;
        _propertyName = pname;
        _propertyType = ptype;
    }
    return self;
}
-(BOOL)isUserCalculate
{
    return (!_propertyName || [_propertyName isEqualToString:LKSQLUserCalculate]);
}
@end

@interface LKModelInfos()
{
    __strong NSMutableDictionary* _proNameDic;
    __strong NSMutableDictionary* _sqlNameDic;
}
@end

@implementation LKModelInfos
- (id)initWithKeyMapping:(NSDictionary *)keyMapping propertyNames:(NSArray *)propertyNames propertyType:(NSArray *)propertyType
{
    self = [super init];
    if (self) {
        
        _proNameDic = [[NSMutableDictionary alloc]init];
        _sqlNameDic = [[NSMutableDictionary alloc]init];
        
        NSString  *type,*colume_name,*colume_type,*property_name,*property_type;
        if(keyMapping.count>0)
        {
            NSArray* sql_names = keyMapping.allKeys;
            
            for (int i =0; i< sql_names.count; i++) {
                
                type = colume_name = colume_type = property_name = property_type = nil;
                
                colume_name = [sql_names objectAtIndex:i];
                NSString* mappingValue = [keyMapping objectForKey:colume_name];
                
                //如果 设置的 属性名 是空白的  自动转成 使用ColumeName
                if([LKDBUtils checkStringIsEmpty:mappingValue])
                {
                    NSLog(@"#ERROR sql colume name %@ mapping value is empty,automatically converted LKDBInherit",colume_name);
                    mappingValue = LKSQLInherit;
                }
                
                if([mappingValue isEqualToString:LKSQLUserCalculate])
                {
                    type = LKSQLUserCalculate;
                    colume_type = LKSQLText;
                }
                else
                {
                    
                    if([mappingValue isEqualToString:LKSQLInherit] || [mappingValue isEqualToString:LKSQLBinding])
                    {
                        type = LKSQLInherit;
                        property_name = colume_name;
                    }
                    else
                    {
                        type = LKSQLBinding;
                        property_name = mappingValue;
                    }
                    
                    int index = [propertyNames indexOfObject:property_name];
                    
                    NSAssert(index != NSNotFound, @"#ERROR TableMapping SQL colume name %@ not fount %@ property name",colume_name,property_name);
                    
                    property_type = [propertyType objectAtIndex:index];
                    colume_type = LKSQLTypeFromObjcType(property_type);
                }
                
                [self addDBPropertyWithType:type cname:colume_name ctype:colume_type pname:property_name ptype:property_type];
            }
        }
        else
        {
            for (int i=0; i<propertyNames.count; i++) {
                
                type = LKSQLInherit;
                
                property_name = [propertyNames objectAtIndex:i];
                colume_name = property_name;
                
                property_type = [propertyType objectAtIndex:i];
                colume_type = LKSQLTypeFromObjcType(property_type);
                
                [self addDBPropertyWithType:type cname:colume_name ctype:colume_type pname:property_name ptype:property_type];
            }
        }
    }
    return self;
}
-(void)addDBPropertyWithType:(NSString *)type cname:(NSString *)colume_name ctype:(NSString *)ctype pname:(NSString *)pname ptype:(NSString *)ptype
{
    LKDBProperty* db_property = [[LKDBProperty alloc]initWithType:type cname:colume_name ctype:ctype pname:pname ptype:ptype];
    
    if(db_property.propertyName)
    {
        [_proNameDic setObject:db_property forKey:db_property.propertyName];
    }
    if(db_property.sqlColumeName){
        [_sqlNameDic setObject:db_property forKey:db_property.sqlColumeName];
    }
}
-(int)count
{
    return _sqlNameDic.count;
}
-(LKDBProperty *)objectWithIndex:(int)index
{
    if(index < _sqlNameDic.count)
    {
        id key = [_sqlNameDic.allKeys objectAtIndex:index];
        return [_sqlNameDic objectForKey:key];
    }
    return nil;
}
-(LKDBProperty *)objectWithPropertyName:(NSString *)propertyName
{
    return [_proNameDic objectForKey:propertyName];
}
-(LKDBProperty *)objectWithSqlColumeName:(NSString *)columeName
{
    return [_sqlNameDic objectForKey:columeName];
}
@end