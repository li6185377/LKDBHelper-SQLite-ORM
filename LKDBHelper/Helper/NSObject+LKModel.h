//
//  NSObject+LKModel.h
//  LKDBHelper
//
//  Created by upin on 13-4-15.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@class LKDBProperty;
@class LKModelInfos;
@class LKDBHelper;

#pragma mark- 表结构
@interface NSObject(LKTabelStructure)

// overwrite in your models, return # table name #
+(NSString*)getTableName;
+(BOOL)getAutoUpdateSqlColumn;

// overwrite in your models, set column attribute
+(void)columnAttributeWithProperty:(LKDBProperty*)property;

/**
 *	@brief	overwrite in your models, if your table has primary key
 return # column name  #
 
 主键列名 如果rowid<0 则跟据此名称update 和delete
 */
+(NSString*)getPrimaryKey;

//return multi primary key    返回联合主键
+(NSArray*) getPrimaryKeyUnionArray;

@property int rowid;

/**
 *	@brief   get saved pictures and data file path,can overwirte
 
 获取保存的 图片和数据的文件路径
 */
+(NSString*)getDBImagePathWithName:(NSString*)filename;
+(NSString*)getDBDataPathWithName:(NSString*)filename;
@end



#pragma mark- 表数据操作
@interface NSObject(LKTableData)

/**
 *	@brief      overwrite in your models,return insert sqlite table data
 *
 *
 *	@return     property the data after conversion
 */
-(id)userGetValueForModel:(LKDBProperty*)property;

/**
 *	@brief	overwrite in your models,return insert sqlite table data
 *
 *	@param 	property        will set property
 *	@param 	value           sqlite value (normal value is NSString type)
 */
-(void)userSetValueForModel:(LKDBProperty*)property value:(id)value;

+(NSDateFormatter*)getModelDateFormatter;
//lkdbhelper use
-(id)modelGetValue:(LKDBProperty*)property;
-(void)modelSetValue:(LKDBProperty*)property value:(id)value;

-(id)singlePrimaryKeyValue;
-(BOOL)singlePrimaryKeyValueIsEmpty;
-(LKDBProperty*)singlePrimaryKeyProperty;
@end

@interface NSObject (LKModel)

//return model use LKDBHelper , default return global LKDBHelper;
+(LKDBHelper*)getUsingLKDBHelper;

/**
 *	@brief  返回 该Model 的基础信息
 *
 */
+(LKModelInfos*)getModelInfos;

/**
 *	@brief Containing the super class attributes	设置是否包含 父类 的属性
 */
+(BOOL)isContainParent;

/**
 *	@brief log all property 	打印所有的属性名称和数据
 */
-(NSString*)printAllPropertys;
-(NSString*)printAllPropertysIsContainParent:(BOOL)containParent;

@end