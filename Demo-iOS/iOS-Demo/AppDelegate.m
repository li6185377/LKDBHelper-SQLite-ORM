//
//  AppDelegate.m
//  iOS-Demo
//
//  Created by ljh on 16/5/31.
//  Copyright © 2016年 ljh. All rights reserved.
//

#import "AppDelegate.h"
#import "LKTestModels.h"
#import <LKDBHelper.h>
#import <sqlite3.h>

@interface AppDelegate () <UITextViewDelegate>
@property (nonatomic, strong) NSMutableString *ms;
@property (nonatomic, unsafe_unretained) UITextView *tv;
@end

@implementation AppDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.window endEditing:YES];
}
- (void)add:(NSString *)txt {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_ms appendString:@"\n"];
        [_ms appendString:txt];
        [_ms appendString:@"\n"];
        
        self.tv.text = _ms;
    });
}
#define addText(fmt, ...) [self add:[NSString stringWithFormat:fmt, ##__VA_ARGS__]];

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [UIViewController new];

    self.ms = [NSMutableString string];
    CGRect frame = self.window.bounds;
    frame.origin.y = 20;
    UITextView *textview = [[UITextView alloc] initWithFrame:frame];
    textview.textColor = [UIColor blackColor];
    textview.delegate = self;
    [self.window.rootViewController.view addSubview:textview];
    self.tv = textview;
    [self.window makeKeyAndVisible];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self test];
    });
    return YES;
}
- (void)test {
    // ===== 性能对比测试 =====
    [self runBenchmarkWithOptimization:NO];
    [self runBenchmarkWithOptimization:YES];
}

- (void)runBenchmarkWithOptimization:(BOOL)enabled {
    NSString *dbPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                        enabled ? @"bench_opt.db" : @"bench_default.db"];
    [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[dbPath stringByAppendingString:@"-wal"] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[dbPath stringByAppendingString:@"-shm"] error:nil];
    
    LKDBHelper *helper = [[LKDBHelper alloc] initWithDBPath:dbPath];
    if (enabled) {
        helper.enablePerformanceOptimization = YES;
    }
    
    int const INSERT_COUNT = 50;
    int const QUERY_REPEAT = 50;
    
    // 1. 逐条插入
    CFAbsoluteTime t0 = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < INSERT_COUNT; i++) {
        LKTest *obj = [[LKTest alloc] init];
        obj.name = [NSString stringWithFormat:@"user_%d_with_long_name_padding", i];
        obj.age = i;
        obj.isGirl = (i % 2 == 0);
        obj.like = 'A' + (i % 26);
        obj.score = i * 1.5;
        obj.url = [NSURL URLWithString:[NSString stringWithFormat:@"https://example.com/user/%d", i]];
        obj.error = [NSString stringWithFormat:@"error_message_for_user_%d_detail", i];
        obj.date = [NSDate dateWithTimeIntervalSince1970:i * 86400];
        obj.frame = CGRectMake(i, i * 2, 100 + i, 200 + i);
        obj.frame1 = CGRectMake(i * 3, i * 4, 300, 400);
        obj.point = CGPointMake(i * 1.1, i * 2.2);
        obj.range = NSMakeRange(i, 10);
        obj.size = CGRectMake(0, 0, 320 + i, 480 + i);
        obj.blah = @[@"item1", @"item2", [NSString stringWithFormat:@"item_%d", i]];
        obj.hoho = @{@"key1": @"value1", @"index": @(i), @"desc": [NSString stringWithFormat:@"desc_%d", i]};
        [helper insertToDB:obj];
    }
    CFAbsoluteTime t1 = CFAbsoluteTimeGetCurrent();
    
    // 2. 全量查询（重复读取热数据）
    CFAbsoluteTime t2 = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < QUERY_REPEAT; i++) {
        [helper search:[LKTest class] where:nil orderBy:@"rowid" offset:0 count:INSERT_COUNT];
    }
    CFAbsoluteTime t3 = CFAbsoluteTimeGetCurrent();
    
    // 3. 随机条件查询（主键查询）
    CFAbsoluteTime t4 = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < 1000; i++) {
        int idx = arc4random_uniform(INSERT_COUNT);
        [helper search:[LKTest class] where:[NSString stringWithFormat:@"rowid = %d", idx + 1] orderBy:nil offset:0 count:1];
    }
    CFAbsoluteTime t5 = CFAbsoluteTimeGetCurrent();
    
    // 4. 范围查询
    CFAbsoluteTime t6 = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < 200; i++) {
        int start = arc4random_uniform(INSERT_COUNT - 20);
        NSString *where = [NSString stringWithFormat:@"rowid >= %d and rowid < %d", start + 1, start + 21];
        [helper search:[LKTest class] where:where orderBy:@"rowid" offset:0 count:20];
    }
    CFAbsoluteTime t7 = CFAbsoluteTimeGetCurrent();
    
    // 5. 逐条更新（主键条件）
    CFAbsoluteTime t8 = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < 20; i++) {
        LKTest *obj = [[LKTest alloc] init];
        obj.name = [NSString stringWithFormat:@"updated_%d_with_long_name", i];
        obj.age = i + 1000;
        obj.isGirl = (i % 2 != 0);
        obj.score = i * 3.14;
        obj.error = [NSString stringWithFormat:@"updated_error_%d", i];
        obj.date = [NSDate date];
        obj.frame = CGRectMake(i * 10, i * 20, 500, 600);
        obj.blah = @[@"updated1", @"updated2", @"updated3"];
        obj.hoho = @{@"updated": @YES, @"index": @(i)};
        [helper updateToDB:obj where:[NSString stringWithFormat:@"rowid = %d", i + 1]];
    }
    CFAbsoluteTime t9 = CFAbsoluteTimeGetCurrent();
    
    printf("\n========== %s ==========\n", enabled ? "优化开启" : "优化关闭（系统默认）");
    printf("逐条插入 %d 条: %.1f ms\n", INSERT_COUNT, (t1 - t0) * 1000);
    printf("全量查询 %d 次（每次 %d 条）: %.1f ms\n", QUERY_REPEAT, INSERT_COUNT, (t3 - t2) * 1000);
    printf("随机主键查询 1000 次: %.1f ms\n", (t5 - t4) * 1000);
    printf("范围查询 200 次（每次20条）: %.1f ms\n", (t7 - t6) * 1000);
    printf("逐条更新 20 次: %.1f ms\n", (t9 - t8) * 1000);
    double total = (t1-t0+t3-t2+t5-t4+t7-t6+t9-t8) * 1000;
    printf("总耗时: %.1f ms\n", total);
}

/*
    addText(@"LKTest create table sql :\n%@\n", [LKTest getCreateTableSQL]);
    addText(@"LKTestForeign create table sql :\n%@\n", [LKTestForeign getCreateTableSQL]);

    //清空表数据  clear table data
    [LKDBHelper clearTableData:[LKTest class]];

    //初始化数据模型  init object
    LKTest *test = [[LKTest alloc] init];
    test.name = @"zhan san";
    test.age = 16;
    test.url = [NSURL URLWithString:@"http://url"];

    //外键  foreign key
    LKTestForeign *foreign = [[LKTestForeign alloc] init];
    foreign.postcode = 123341;
    foreign.addid = 213214;

    test.address = foreign;


    ///复杂对象 complex object
    test.blah = @[@"1", @"2", @"3"];
    test.blah = @[@"0", @[@1], @{@"2": @2}, foreign];
    test.hoho = @{@"array": test.blah, @"foreign": foreign, @"normal": @123456, @"date": [NSDate date]};

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

    addText(@"%f", test.score);
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
        test.rowid = 0; //no new object,should set rowid:0
        BOOL insertSucceed = [helper insertWhenNotExists:test];

        //insert fail
        if (insertSucceed == NO) {
            // rollback
            addText(@"不可插入相同主键的数据!");
            return NO;
        } else {
            // commit
            return YES;
        }
    }];


    addText(@"Insert completed synchronization");

    sleep(1);

    test.name = @"li si";
    [globalHelper insertToDB:test
                    callback:^(BOOL isInsert) {
                        addText(@"asynchronization insert complete: %@", isInsert > 0 ? @"YES" : @"NO");
                    }];

    //查询   search
    NSMutableArray *searchResultArray = nil;

    [LKTest searchWithSQL:@"select * from LKTestAddress"];

    addText(@"\n search one: \n");
    ///同步搜索 执行sql语句 把结果变为LKTest对象
    ///Synchronous search executes the SQL statement put the results into a LKTest object
    searchResultArray = [globalHelper searchWithSQL:@"select * from @t" toClass:[LKTest class]];
    for (id obj in searchResultArray) {
        addText(@"%@", [obj printAllPropertys]);
    }

    addText(@"\n search two: \n");
    ///搜索所有值     search all
    searchResultArray = [LKTest searchWithWhere:nil orderBy:nil offset:0 count:100];
    for (id obj in searchResultArray) {
        addText(@"%@", [obj printAllPropertys]);
    }

    addText(@"查询 单个 列   search single column");
    ///只获取name那列的值   search with column 'name' results
    NSArray *nameArray = [LKTest searchColumn:@"name" where:nil orderBy:nil offset:0 count:0];
    addText(@"%@", [nameArray componentsJoinedByString:@","]);


    ///
    addText(@"休息25秒, 为了说明 是异步插入的\n, 测试自动关闭数据库连接的可用性"
             "rest for 2 seconds to start is asynchronous inserted to illustrate");

    /// 测试 自动关闭数据库连接
    sleep(25);

    addText(@"休息2秒 结束 \n rest for 2 seconds at the end");

    NSArray *array = [globalHelper searchWithSQL:@"select * from LKTestTable" toClass:nil];
    NSLog(@"%@", array);

    //异步 asynchronous
    [globalHelper search:[LKTest class]
                   where:@{@"name": @"zhan san"}
                 orderBy:nil
                  offset:0
                   count:100
                callback:^(NSMutableArray *array) {
                    addText(@"异步搜索 结束,  async search end");
                    for (NSObject *obj in array) {
                        addText(@"%@", [obj printAllPropertys]);
                    }

                    sleep(1);

                    ///修改    update object
                    LKTest *test2 = array.firstObject;
                    test2.name = @"wang wu";

                    [globalHelper updateToDB:test2 where:nil];

                    addText(@"修改完成 , update completed ");

                    ///all
                    array = [globalHelper search:[LKTest class] where:nil orderBy:nil offset:0 count:100];
                    for (NSObject *obj in array) {
                        addText(@"%@", [obj printAllPropertys]);
                    }


                    ///delete
                    test2.rowid = 0;
                    BOOL ishas = [globalHelper isExistsModel:test2];
                    if (ishas) {
                        //删除    delete
                        [globalHelper deleteToDB:test2];
                    }

                    addText(@"删除完成, delete completed");
                    sleep(1);

                    ///all
                    array = [globalHelper search:[LKTest class] where:nil orderBy:nil offset:0 count:100];
                    for (NSObject *obj in array) {
                        addText(@"%@", [obj printAllPropertys]);
                    }

                    addText(@"示例 结束  example finished\n\n");


                    //Expansion: Delete the picture is no longer stored in the database record
                    addText(@"扩展:  删除已不再数据库中保存的 图片记录 \n expansion: Delete the picture is no longer stored in the database record");
                    //目前 已合并到LKDBHelper 中  就先写出来 给大家参考下

                    [LKDBHelper clearNoneImage:[LKTest class] columns:[NSArray arrayWithObjects:@"img", nil]];
                }];
}
*/
@end
