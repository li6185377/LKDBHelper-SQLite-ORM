//
//  LKDBProperty+KeyMapping.h
//  LKDBHelper
//
//  Created by upin on 13-6-17.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import "LKDBUtils.h"

static NSString* const LKSQLText        =   @"text";
static NSString* const LKSQLInt         =   @"integer";
static NSString* const LKSQLDouble      =   @"double";
static NSString* const LKSQLBlob        =   @"blob";

static NSString* const LKSQLNotNull     =   @"NOT NULL";
static NSString* const LKSQLPrimaryKey  =   @"PRIMARY KEY";
static NSString* const LKSQLDefault     =   @"DEFAULT";
static NSString* const LKSQLUnique      =   @"UNIQUE";
static NSString* const LKSQLCheck       =   @"CHECK";
static NSString* const LKSQLForeignKey  =   @"FOREIGN KEY";

static NSString* const LKSQLFloatType   =   @"float_double_decimal";
static NSString* const LKSQLIntType     =   @"int_char_short_long";
static NSString* const LKSQLBlobType    =   @"";

static NSString* const LKSQLInherit          =   @"LKDBInherit";
static NSString* const LKSQLBinding          =   @"LKDBBinding";
static NSString* const LKSQLUserCalculate    =   @"LKDBUserCalculate";

//Object-c type converted to SQLite type  把Object-c 类型 转换为sqlite 类型
extern inline NSString* LKSQLTypeFromObjcType(NSString *objcType);

@interface NSObject(TableMapping)

/**
 *	@brief Overwrite in your models if your property names don't match your Table Colume names.
 also use for set create table columes.
 
 @{ sql colume name : ( model property name ) or LKDBInherit or LKDBUserCalculate}
 
 */
+(NSDictionary*)getTableMapping;

@end

@interface LKDBProperty:NSObject

@property(readonly,nonatomic)NSString* type;

@property(readonly,nonatomic)NSString* sqlColumeName;
@property(readonly,nonatomic)NSString* sqlColumeType;

@property(readonly,nonatomic)NSString* propertyName;
@property(readonly,nonatomic)NSString* propertyType;

//创建表的时候 使用
@property BOOL isUnique;
@property BOOL isNotNull;
@property NSString* defaultValue;
@property NSString* checkValue;
@property int length;


-(BOOL)isUserCalculate;
@end


@interface LKModelInfos : NSObject

-(id)initWithKeyMapping:(NSDictionary*)keyMapping propertyNames:(NSArray*)propertyNames propertyType:(NSArray*)propertyType;

@property(readonly,nonatomic)int count;

-(LKDBProperty*)objectWithIndex:(int)index;
-(LKDBProperty*)objectWithPropertyName:(NSString*)propertyName;
-(LKDBProperty*)objectWithSqlColumeName:(NSString*)columeName;

@end