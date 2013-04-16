//
//  LKAppDelegate.m
//  LKDBHelper
//
//  Created by upin on 13-4-15.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import "LKAppDelegate.h"


@implementation LKAppDelegate

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
            NSLog(@"示例 开始 \n\n");
    //创建表  会根据表的版本号  来判断具体的操作
    [[LKDBHelper sharedDBHelper] createTableWithModelClass:[LKTest class]];

    //清空表数据
    [[LKDBHelper sharedDBHelper] clearTableData:[LKTest class]];
    
    LKTest* test = [[[LKTest alloc]init] autorelease];
    test.name = @"zhan san";
    test.age = 16;
    test.isGirl = YES;
    test.like = 'I';
    test.img = [UIImage imageNamed:@"41.png"];
    test.date = [NSDate date];
    test.color = [UIColor orangeColor];
    [[LKDBHelper sharedDBHelper] insertToDB:test];
    test.name = @"li si";
    
    BOOL isInsert = [[LKDBHelper sharedDBHelper] insertToDB:test];
    NSLog(@"插入完成 %d",isInsert);
    
    NSMutableArray* array =  [[LKDBHelper sharedDBHelper] search:[LKTest class] where:nil orderBy:nil offset:0 count:100];
    for (NSObject* obj in array) {
        [obj printAllPropertys];
    }
    
    LKTest* test2 = [array objectAtIndex:0];
    test2.name = @"wang wu";
    
    [[LKDBHelper sharedDBHelper] updateToDB:test2 where:nil];
    NSLog(@"修改完成");
    array =  [[LKDBHelper sharedDBHelper] search:[LKTest class] where:nil orderBy:nil offset:0 count:100];
    for (NSObject* obj in array) {
        [obj printAllPropertys];
    }
    
    [[LKDBHelper sharedDBHelper] deleteToDB:test2];
    NSLog(@"删除完成");
    array =  [[LKDBHelper sharedDBHelper] search:[LKTest class] where:nil orderBy:nil offset:0 count:100];
    for (NSObject* obj in array) {
        [obj printAllPropertys];
    }
    
        NSLog(@"示例 结束 \n\n");
    
    
   
    NSLog(@"扩展:  删除已不再数据库中保存的 图片记录");
    //目前 还不知 如何  合并到LKDBHelper 中  就先写出来 给大家参考下
    
    //获取相应 实体类图片保存路径  可看NSObject + LKModel 源代码 得知位置
    NSString* dir =  [LKDBUtils getDirectoryForDocuments:[NSString stringWithFormat:@"dbimg/%@",NSStringFromClass([LKTest class])]];
    
    //获取该目录下所有文件名
    NSArray* files = [LKDBUtils getFilenamesWithDir:dir];
    __block NSArray* dbfiles;
    [[LKDBHelper sharedDBHelper] executeDB:^(FMDatabase *db) {

        //获取img列集合
        NSString* sql = @"select img from LKTextTable where img !='' ";
        
        NSMutableArray* tempfiles = [NSMutableArray arrayWithCapacity:6];
        FMResultSet* set = [db executeQuery:sql];
        while ([set next]) {
            //保存起来
            [tempfiles addObject:[set stringForColumnIndex:0]];
        }
        [set close];
        dbfiles = tempfiles;
    }];
    
    //遍历  当不再数据库记录中 就删除
    for (NSString* deletefile in files) {
        if([dbfiles indexOfObject:deletefile] == NSNotFound)
        {
            [LKDBUtils deleteWithFilepath:[dir stringByAppendingPathComponent:deletefile]];
        }
    }
    
    [self.window makeKeyAndVisible];
    return YES;
}
@end

@implementation LKTest
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
    return 3;
}
@end
