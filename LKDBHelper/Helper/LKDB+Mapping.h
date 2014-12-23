//
//  LKDBProperty+KeyMapping.h
//  LKDBHelper
//
//  Created by LJH on 13-6-17.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import "LKDBUtils.h"

@interface NSObject(TableMapping)

/**
 *	@brief Overwrite in your models if your property names don't match your Table Column names.
 also use for set create table columns.
 
 @{ sql column name : ( model property name ) or LKDBInherit or LKDBUserCalculate}
 
 */
+(NSDictionary*)getTableMapping;

/***
 simple set a column as "LKSQL_Mapping_UserCalculate"
 column name
*/
+(void)setUserCalculateForCN:(NSString*)columnName;

///property type name
+(void)setUserCalculateForPTN:(NSString*)propertyTypeName;

///binding columnName to PropertyName
+(void)setTableColumnName:(NSString*)columnName bindingPropertyName:(NSString*)propertyName;

///remove unwanted binding property
+(void)removePropertyWithColumnName:(NSString*)columnName;
+(void)removePropertyWithColumnNameArray:(NSArray*)columnNameArray;
@end

@interface LKDBProperty:NSObject

@property(readonly,nonatomic)NSString* type;

@property(readonly,nonatomic)NSString* sqlColumnName;
@property(readonly,nonatomic)NSString* sqlColumnType;

@property(readonly,nonatomic)NSString* propertyName;
@property(readonly,nonatomic)NSString* propertyType;

///creating table's column
@property BOOL isUnique;
@property BOOL isNotNull;
@property(strong,nonatomic) NSString* defaultValue;
@property(strong,nonatomic) NSString* checkValue;
@property NSInteger length;


-(BOOL)isUserCalculate;
@end


@interface LKModelInfos : NSObject

-(id)initWithKeyMapping:(NSDictionary*)keyMapping propertyNames:(NSArray*)propertyNames propertyType:(NSArray*)propertyType primaryKeys:(NSArray*)primaryKeys;

@property(readonly,nonatomic)NSUInteger count;
@property(readonly,nonatomic)NSArray* primaryKeys;

-(LKDBProperty*)objectWithIndex:(NSInteger)index;
-(LKDBProperty*)objectWithPropertyName:(NSString*)propertyName;
-(LKDBProperty*)objectWithSqlColumnName:(NSString*)columnName;

@end