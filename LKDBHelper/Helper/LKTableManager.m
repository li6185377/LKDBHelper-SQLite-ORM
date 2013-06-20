//
//  NSObject+LKTableUpdate.m
//  LKDBHelper
//
//  Created by upin on 13-6-19.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import "LKTableManager.h"
#import "LKDBHelper.h"

@interface LKTableManager()
@property(strong,nonatomic)NSMutableDictionary* tableInfos;
@property(weak,nonatomic)LKDBHelper* dbhelper;
@end
@implementation LKTableManager
- (id)initWithLKDBHelper:(LKDBHelper *)helper
{
    self = [super init];
    if (self) {
        
        self.dbhelper = helper;
        self.tableInfos = [NSMutableDictionary dictionaryWithCapacity:0];
        [helper executeDB:^(FMDatabase *db) {
            
            [db executeUpdate:@"CREATE TABLE IF NOT EXISTS LKTableManager(table_name text primary key,version integer)"];
            
            FMResultSet* set = [db executeQuery:@"select table_name,version from LKTableManager"];
            
            while ([set next]) {
                [_tableInfos setObject:[NSNumber numberWithInt:[set intForColumnIndex:1]] forKey:[set stringForColumnIndex:0]];
            }
            
            [set close];
        }];
    }
    return self;
}
-(int)versionWithName:(NSString *)name
{
    return [[_tableInfos objectForKey:name] intValue];
}
-(void)setTableName:(NSString *)name version:(int)version
{
    [_tableInfos setObject:[NSNumber numberWithInt:version] forKey:name];
    [_dbhelper executeDB:^(FMDatabase *db) {
        NSString* replaceSQL = [NSString stringWithFormat:@"replace into LKTableManager(table_name,version) values('%@',%d)",name,version];
        [db executeUpdate:replaceSQL];
    }];
}
-(void)clearTableInfos
{
    [_dbhelper executeDB:^(FMDatabase *db) {
        NSString* deleteSQL = [NSString stringWithFormat:@"delete from LKTableManager"];
        [db executeUpdate:deleteSQL];
    }];
    [self.tableInfos removeAllObjects];
}
@end
