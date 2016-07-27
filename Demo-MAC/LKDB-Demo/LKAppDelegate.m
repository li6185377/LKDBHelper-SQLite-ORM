//
//  LKAppDelegate.m
//  LKDB-Demo
//
//  Created by ljh on 14-3-26.
//  Copyright (c) 2014年 LJH. All rights reserved.
//

#import "LKAppDelegate.h"
#import "LKDBHelper.h"
#import "LKTestModels.h"

@interface LKAppDelegate()
@property(strong,nonatomic)NSMutableString* ms;

@end
@implementation LKAppDelegate



-(void)add:(NSString*)txt
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_ms appendString:@"\n"];
        [_ms appendString:txt];
        [_ms appendString:@"\n"];
        
        self.textView.string = _ms;
    });
}
#define addText(fmt, ...) [self add:[NSString stringWithFormat:fmt,##__VA_ARGS__]]

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSLog(@"%@",NSHomeDirectory());
    self.ms = [NSMutableString string];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self test];
    });
}
-(void)test
{
    addText(@"示例 开始 example start \n\n");
    
    //清空数据库
    LKDBHelper* globalHelper = [LKTest getUsingLKDBHelper];
    [globalHelper dropAllTable];
    
    addText(@"LKTest create table sql :\n%@\n",[LKTest getCreateTableSQL]);
    addText(@"LKTestForeign create table sql :\n%@\n",[LKTestForeign getCreateTableSQL]);
    
    //清空表数据   clear table data
    [LKDBHelper clearTableData:[LKTest class]];
    
    
    LKTestForeign* foreign = [[LKTestForeign alloc]init];
    foreign.address = @":asdasdasdsadasdsdas";
    foreign.postcode  = 123341;
    foreign.addid = 213214;
    
    //插入数据    insert table row
    LKTest* test = [[LKTest alloc]init];
    test.frame = CGRectMake(1, 2, 3, 4);
    test.frame1 = CGRectMake(5, 6, 7, 8);
    
    test.name = @"zhan san";
    test.age = 16;
    test.url = [NSURL URLWithString:@"http://xx"];
    
    //外键 foreign key
    test.address = foreign;
    
    test.isGirl = YES;
    test.like = 'I';
    test.img = [NSImage imageNamed:@"Snip20130620_6.png"];
    test.date = [NSDate date];
    test.color = [NSColor orangeColor];
    test.error = @"nil";
    
    test.score = [[NSDate date] timeIntervalSince1970];
    
    test.data = [@"hahaha" dataUsingEncoding:NSUTF8StringEncoding];
    
    addText(@"%f",test.score);
    //异步 插入第一条 数据   Insert the first
    [globalHelper insertToDB:test];
    
    //多主键 的插入成功
    test.age = 17;
    [globalHelper insertToDB:test];
    
    //事物  transaction
    [globalHelper executeDB:^(FMDatabase *db) {
        
        [db beginTransaction];
        
        test.name = @"1";
        [globalHelper insertToDB:test];
        
        test.name = @"2";
        [globalHelper insertToDB:test];
        
        //重复主键   duplicate primary key
        test.name = @"1";
        test.rowid = 0;     //no new object,should set rowid:0
        BOOL insertSucceed = [globalHelper insertWhenNotExists:test];
        
        //insert fail
        if(insertSucceed == NO)
            [db rollback];
        else
            [db commit];
        
    }];
    
    
    addText(@"同步插入 完成!  Insert completed synchronization");
    
    sleep(1);
    
    
    //改个 主键 插入第2条数据   update primary column value  Insert the second
    test.name = @"li si";
    [globalHelper insertToDB:test callback:^(BOOL isInsert) {
        addText(@"asynchronization insert complete: %@",isInsert>0?@"YES":@"NO");
    }];
    
    //查询   search
    addText(@"同步搜索    sync search");
    
    NSMutableArray* arraySync = [LKTest searchWithWhere:nil orderBy:nil offset:0 count:100];
    for (id obj in arraySync) {
        addText(@"%@",[obj printAllPropertys]);
    }
    
    //查询 单个 列   search single column
    addText(@"只获取name那列的值   search with column 'name' results");
    NSArray* nameArray = [LKTest searchColumn:@"name" where:nil orderBy:nil offset:0 count:0];
    addText(@"%@",[nameArray componentsJoinedByString:@","]);
    
    addText(@"休息2秒 开始  为了说明 是异步插入的\n"
            "rest for 2 seconds to start is asynchronous inserted to illustrate");
    
    sleep(2);
    
    addText(@"休息2秒 结束 \n rest for 2 seconds at the end");
    
    //异步
    [globalHelper search:[LKTest class] where:nil orderBy:nil offset:0 count:100 callback:^(NSMutableArray *array) {
        
        addText(@"异步搜索 结束,  async search end");
        for (NSObject* obj in array) {
            addText(@"%@",[obj printAllPropertys]);
        }
        
        sleep(1);
        
        //修改    update
        LKTest* test2 = [array objectAtIndex:0];
        test2.name = @"wang wu";
        
        [globalHelper updateToDB:test2 where:nil];
        
        addText(@"修改完成 , update completed ");
        
        array =  [globalHelper search:[LKTest class] where:nil orderBy:nil offset:0 count:100];
        for (NSObject* obj in array) {
            addText(@"%@",[obj printAllPropertys]);
        }
        
        test2.rowid = 0;
        
        BOOL ishas = [globalHelper isExistsModel:test2];
        if(ishas)
        {
            //删除    delete
            [globalHelper deleteToDB:test2];
        }
        
        addText(@"删除完成, delete completed");
        sleep(1);
        
        array =  [globalHelper search:[LKTest class] where:nil orderBy:nil offset:0 count:100];
        for (NSObject* obj in array) {
            addText(@"%@",[obj printAllPropertys]);
        }
        
        addText(@"示例 结束  example finished\n\n");
        
        
        
        //Expansion: Delete the picture is no longer stored in the database record
        addText(@"扩展:  删除已不再数据库中保存的 图片记录 \n expansion: Delete the picture is no longer stored in the database record");
        //目前 已合并到LKDBHelper 中  就先写出来 给大家参考下
        
        [LKDBHelper clearNoneImage:[LKTest class] columns:[NSArray arrayWithObjects:@"img",nil]];
    }];
}


@end
