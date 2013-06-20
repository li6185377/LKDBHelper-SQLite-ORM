//
//  NSObject+TableManager.h
//  LKDBHelper
//
//  Created by upin on 13-6-20.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LKDBHelper;
typedef enum {
    LKTableUpdateTypeDefault = 1<<0,        //不操作 可能后续的操作会报错
    LKTableUpdateTypeDeleteOld = 1<<1,      //直接删除旧表  创建新表
    LKTableUpdateTypeCustom = 1<<2          //自定义 更新
}LKTableUpdateType;

@interface NSObject (TableManager)

+(int)getTableVersion;

/**
 *	@brief	overwrite in your models, operating table update
 */
+(LKTableUpdateType)tableUpdateForOldVersion:(int)oldVersion newVersion:(int)newVersion;

+(void)tableUpdateAddColumeWithPN:(NSString*)propertyName;
+(void)tableUpdateAddColumeWithName:(NSString*)columeName sqliteType:(NSString*)sqliteType;
@end


@interface LKTableManager : NSObject
-(id)initWithLKDBHelper:(LKDBHelper*)helper;

-(void)setTableName:(NSString*)name version:(int)version;
-(int)versionWithName:(NSString*)name;
-(void)clearTableInfos;
@end
