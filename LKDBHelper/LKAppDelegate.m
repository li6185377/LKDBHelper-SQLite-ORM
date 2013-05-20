//
//  LKAppDelegate.m
//  LKDBHelper
//
//  Created by upin on 13-4-15.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import "LKAppDelegate.h"


@implementation LKAppDelegate
-(void)m1:(NSString*)sql,...
{
    
}
-(void)m2:(NSString*)sql,...
{
    
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    NSLog(@"示例 开始 example start \n\n");

    //创建表  会根据表的版本号  来判断具体的操作 . create table need to manually call
    [[LKDBHelper sharedDBHelper] createTableWithModelClass:[LKTest class]];
    
    //清空表数据   clear table data
    [[LKDBHelper sharedDBHelper] clearTableData:[LKTest class]];
    
    //插入数据    insert table row
    LKTest* test = [[LKTest alloc]init];
    test.name = @"zhan san";
    test.age = 16;
    test.isGirl = YES;
    test.like = 'I';
    test.img = [UIImage imageNamed:@"41.png"];
    test.date = [NSDate date];
    test.color = [UIColor orangeColor];
    
    //插入第一条 数据   Insert the first
    [[LKDBHelper sharedDBHelper] insertToDB:test];

    //改个 主键 插入第2条数据   update primary colume value  Insert the second
    test.name = @"li si";
    BOOL isInsert = [[LKDBHelper sharedDBHelper] insertToDB:test];
    NSLog(@"插入完成 insert finished : %@",isInsert>0?@"YES":@"NO");
    
    //查询   search
    NSMutableArray* array = [LKTest searchWithWhere:nil orderBy:nil offset:0 count:100];
    for (NSObject* obj in array) {
        [obj printAllPropertys];
    }
    
    
    //修改    update
    LKTest* test2 = [array objectAtIndex:0];
    test2.name = @"wang wu";
    [[LKDBHelper sharedDBHelper] updateToDB:test2 where:nil];
    
    NSLog(@"修改完成 updated ");
    
    array =  [[LKDBHelper sharedDBHelper] search:[LKTest class] where:nil orderBy:nil offset:0 count:100];
    for (NSObject* obj in array) {
        [obj printAllPropertys];
    }
    
    test2.rowid = 0;

    BOOL ishas = [[LKDBHelper sharedDBHelper] isExistsModel:test2];
    if(ishas)
    {
        //删除    delete
        [[LKDBHelper sharedDBHelper] deleteToDB:test2];
    }
    
    NSLog(@"删除完成        deleted");
    
    array =  [[LKDBHelper sharedDBHelper] search:[LKTest class] where:nil orderBy:nil offset:0 count:100];
    for (NSObject* obj in array) {
        [obj printAllPropertys];
    }
    
        NSLog(@"示例 结束  example finished\n\n");
    
    
   
    //Expansion: Delete the picture is no longer stored in the database record
    NSLog(@"扩展:  删除已不再数据库中保存的 图片记录");
    //目前 已合并到LKDBHelper 中  就先写出来 给大家参考下
    
    [[LKDBHelper sharedDBHelper] clearNoneImage:[LKTest class] columes:[NSArray arrayWithObjects:@"img",nil]];
    
    
    [self.window makeKeyAndVisible];
    return YES;
}
@end

@implementation LKTest
+(void)dbWillInsert:(NSObject *)entity
{
//    NSLog(@"will insert : %@",NSStringFromClass(self));
}
+(void)dbDidInserted:(NSObject *)entity result:(BOOL)result
{
//    NSLog(@"did insert : %@",NSStringFromClass(self));
}

+(NSString *)getPrimaryKey
{
    return @"name";
}
+(NSString *)getTableName
{
    return @"LKTextTable";
}
+(int)getTableVersion
{
    return 2;
}
+(LKTableUpdateType)tableUpdateWithDBHelper:(LKDBHelper *)helper oldVersion:(int)oldVersion newVersion:(int)newVersion
{
    switch (oldVersion) {
        case 1:
        {
            [helper executeDB:^(FMDatabase *db) {
                 NSString* sql = @"alter table LKTextTable add column color text";
                [db executeUpdate:sql];
            }];
        }
            break;
    }
    return LKTableUpdateTypeCustom;
}
@end
