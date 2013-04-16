//
//  NSObject+LKModel.h
//  LKDBHelper
//
//  Created by upin on 13-4-15.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LKDBUtils.h"
#import <objc/runtime.h>
#define LKSQLText @"text"
#define LKSQLInt @"integer"
#define LKSQLDouble @"float"
#define LKSQLBlob @"blob"
#define LKSQLNull @"null"
#define LKSQLPrimaryKey @"primary key"
@class LKDBHelper;

typedef enum {
    LKTableUpdateTypeDefault = 1<<0,        // 直接删除旧表  创建新表
    LKTableUpdateTypeCustom = 1<<1          //自定义 更新
}LKTableUpdateType;

@interface NSObject (LKModel)

/**
 *	@brief  该类的所有属性
 是否上溯到NSObject类（不会获取NSObject 的属性）由isContainParent 方法返回  可在子类种重载此方法
 *
 *	@return	返回 该类的所有属性
 */
+(NSDictionary*)getPropertys;

/**
 *	@brief	设置getPropertys方法 是否上溯到 父类
 *
 *  @return
 */
+(BOOL)isContainParent;

/**
 *	@brief	主键名称 如果rowid<0 则跟据此名称update 和delete
 */
+(NSString*)getPrimaryKey;
/**
 *	@brief	表名 默认实体类名称
 */
+(NSString*)getTableName;

/**
 *	@brief	返回当前版本
 */
+(int)getTableVersion;

/**
 *	@brief	更新表结构
 *
 *	@param 	helper      helper
 *	@param 	oldVersion 	旧版本号
 *	@param 	newVersion 	新版本号
 *
 *	@return	更新策略
 */
+(LKTableUpdateType)tableUpdateWithDBHelper:(LKDBHelper*)helper oldVersion:(int)oldVersion newVersion:(int)newVersion;


/**
 *	@brief	打印所有的属性名称和数据
 */
-(void)printAllPropertys;

/**
 *	@brief	默认实现了 UIColor NSDate UIImage NSData 的数据转换存储
            子类 可重载  比如 可将  NSArray 和 NSDictionary 转成JSON 进行存储
 *
 *	@param 	key 	要返回的属性名称
 *
 *	@return	属性值
 */
-(id)modelGetValueWithKey:(NSString*)key type:(NSString *)columeType;


/**
 *	@brief	默认实现了 UIColor NSDate UIImage NSData 的数据转换存储 
            子类 可重载  比如 可将  NSArray 和 NSDictionary 转成JSON 进行存储
 *
 *	@param 	value 	要传入的 值
 *	@param 	key 	要设置属性的 名称
 *	@param 	type 	value 的类型
 */
-(void)modelSetValue:(id)value key:(NSString*)key type:(NSString*)type;

/**
 *	@brief   sqlite 中存储的rowid
 */
@property int rowid;


//获取保存的 图片和数据的文件夹路径
+(NSString*)getDBImageDir;
+(NSString*)getDBDataDir;
@end