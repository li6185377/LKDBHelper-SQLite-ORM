//
//  AppDelegate.m
//  iOS-Demo
//
//  Created by ljh on 16/5/31.
//  Copyright © 2016年 ljh. All rights reserved.
//

#import "AppDelegate.h"
#import <LKDBHelper.h>
#import "LKTestModels.h"

@interface AppDelegate()<UITextViewDelegate>
@property(strong,nonatomic)NSMutableString* ms;
@property(unsafe_unretained,nonatomic)UITextView* tv;
@end

@implementation AppDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.window endEditing:YES];
}
-(void)add:(NSString*)txt
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_ms appendString:@"\n"];
        [_ms appendString:txt];
        [_ms appendString:@"\n"];
        
        self.tv.text = _ms;
    });
}
#define addText(fmt, ...) [self add:[NSString stringWithFormat:fmt,##__VA_ARGS__]]

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [UIViewController new];

    self.ms = [NSMutableString string];
    CGRect frame = self.window.bounds;
    frame.origin.y = 20;
    UITextView* textview = [[UITextView alloc]initWithFrame:frame];
    textview.textColor = [UIColor blackColor];
    textview.delegate =self;
    [self.window.rootViewController.view addSubview:textview];
    self.tv = textview;
    [self.window makeKeyAndVisible];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self test];
    });
    return YES;
}
-(void)test
{
    addText(@"示例 开始 example start \n\n");
    
    ///获取 LKTest 类使用的 LKDBHelper
    LKDBHelper* globalHelper = [LKTest getUsingLKDBHelper];
    
    ///删除所有表   delete all table
    [globalHelper dropAllTable];
    
    addText(@"LKTest create table sql :\n%@\n",[LKTest getCreateTableSQL]);
    addText(@"LKTestForeign create table sql :\n%@\n",[LKTestForeign getCreateTableSQL]);
    
    //清空表数据  clear table data
    [LKDBHelper clearTableData:[LKTest class]];
    
    //初始化数据模型  init object
    LKTest* test = [[LKTest alloc]init];
    test.name = @"zhan san";
    test.age = 16;
    test.url = [NSURL URLWithString:@"http://url"];
    
    //外键  foreign key
    LKTestForeign* foreign = [[LKTestForeign alloc]init];
    foreign.postcode  = 123341;
    foreign.addid = 213214;
    
    test.address = foreign;
    
    
    ///复杂对象 complex object
    test.blah = @[@"1",@"2",@"3"];
    test.blah = @[@"0",@[@1],@{@"2":@2},foreign];
    test.hoho = @{@"array":test.blah,@"foreign":foreign,@"normal":@123456,@"date":[NSDate date]};
    
    ///other
    test.isGirl = YES;
    test.like = 'I';
    test.img = [UIImage imageNamed:@"Snip20130620_6.png"];
    test.date = [NSDate date];
    test.color = [UIColor orangeColor];
    test.error = @"nil";
    
    test.score = [[NSDate date] timeIntervalSince1970];
    
    test.data = [@"hahaha" dataUsingEncoding:NSUTF8StringEncoding];
    
    //    #error 目前LKDB  还不支持嵌套引用
    //    foreign.nestModel = test;
    //    test.nestModel = foreign;
    
    addText(@"%f",test.score);
    //同步 插入第一条 数据   synchronous insert the first
    [test saveToDB];
    //or
    //[globalHelper insertToDB:test];
    
    //更改主键继续插入   Insert the change after the primary key
    test.age = 17;
    [globalHelper insertToDB:test];
    
    //事物  transaction
    [globalHelper executeForTransaction:^BOOL(LKDBHelper *helper) {
        
        test.name = @"1";
        BOOL success = [helper insertToDB:test];
        
        test.name = @"2";
        success = [helper insertToDB:test];
        
        //重复主键   duplicate primary key
        test.name = @"1";
        test.rowid = 0;     //no new object,should set rowid:0
        BOOL insertSucceed = [helper insertWhenNotExists:test];
        
        //insert fail
        if(insertSucceed == NO)
        {
            ///rollback
            return NO;
        }
        else
        {
            ///commit
            return YES;
        }
    }];
    
    
    addText(@"同步插入 完成!  Insert completed synchronization");
    
    sleep(1);
    
    test.name = @"li si";
    [globalHelper insertToDB:test callback:^(BOOL isInsert) {
        addText(@"asynchronization insert complete: %@",isInsert>0?@"YES":@"NO");
    }];
    
    //查询   search
    NSMutableArray* searchResultArray = nil;
    
    [LKTest searchWithSQL:@"select * from @t,LKTestAddress"];
    
    addText(@"\n search one: \n");
    ///同步搜索 执行sql语句 把结果变为LKTest对象
    ///Synchronous search executes the SQL statement put the results into a LKTest object
    searchResultArray = [globalHelper searchWithSQL:@"select * from @t" toClass:[LKTest class]];
    for (id obj in searchResultArray) {
        addText(@"%@",[obj printAllPropertys]);
    }
    
    addText(@"\n search two: \n");
    ///搜索所有值     search all
    searchResultArray = [LKTest searchWithWhere:nil orderBy:nil offset:0 count:100];
    for (id obj in searchResultArray) {
        addText(@"%@",[obj printAllPropertys]);
    }
    
    addText(@"查询 单个 列   search single column");
    ///只获取name那列的值   search with column 'name' results
    NSArray* nameArray = [LKTest searchColumn:@"name" where:nil orderBy:nil offset:0 count:0];
    addText(@"%@",[nameArray componentsJoinedByString:@","]);
    
    
    ///
    addText(@"休息2秒 开始  为了说明 是异步插入的\n"
            "rest for 2 seconds to start is asynchronous inserted to illustrate");
    
    sleep(2);
    
    addText(@"休息2秒 结束 \n rest for 2 seconds at the end");
    
    NSArray *array = [globalHelper searchWithSQL:@"select * from LKTestTable" toClass:nil];
    NSLog(@"%@",array);
    
    //异步 asynchronous
    [globalHelper search:[LKTest class] where:@{@"name":@"zhan san",@"blah":@[@"1",@"3",@"5"]} orderBy:nil offset:0 count:100 callback:^(NSMutableArray *array) {
        
        addText(@"异步搜索 结束,  async search end");
        for (NSObject* obj in array) {
            addText(@"%@",[obj printAllPropertys]);
        }
        
        sleep(1);
        
        ///修改    update object
        LKTest* test2 = array.firstObject;
        test2.name = @"wang wu";
        
        [globalHelper updateToDB:test2 where:nil];
        
        addText(@"修改完成 , update completed ");
        
        ///all
        array =  [globalHelper search:[LKTest class] where:nil orderBy:nil offset:0 count:100];
        for (NSObject* obj in array) {
            addText(@"%@",[obj printAllPropertys]);
        }
        
        
        ///delete
        test2.rowid = 0;
        BOOL ishas = [globalHelper isExistsModel:test2];
        if(ishas)
        {
            //删除    delete
            [globalHelper deleteToDB:test2];
        }
        
        addText(@"删除完成, delete completed");
        sleep(1);
        
        ///all
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
