//
//  LKAppDelegate.m
//  LKDBHelper
//
//  Created by upin on 13-4-15.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import "LKAppDelegate.h"

@interface LKAppDelegate()<UITextViewDelegate>
@property(strong,nonatomic)NSMutableString* ms;
@property(unsafe_unretained,nonatomic)UITextView* tv;
@end
@implementation LKAppDelegate
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
    // Override point for customization after application launch.
    self.ms = [NSMutableString string];
    UITextView* textview = [[UITextView alloc]init];
    textview.frame = CGRectMake(0, 20, 320, self.window.bounds.size.height);
    textview.textColor = [UIColor blackColor];
    textview.delegate =self;
    [self.window addSubview:textview];
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
    
    //清空数据库
    LKDBHelper* globalHelper = [LKDBHelper getUsingLKDBHelper];
    [globalHelper dropAllTable];
    
    //创建表  会根据表的版本号  来判断具体的操作 . create table need to manually call
    [globalHelper createTableWithModelClass:[LKTest class]];
    [globalHelper createTableWithModelClass:[LKTestForeign class]];
    
    //清空表数据   clear table data
    [LKDBHelper clearTableData:[LKTest class]];
    
    LKTestForeign* foreign = [[LKTestForeign alloc]init];
    foreign.address = @":asdasdasdsadasdsdas";
    foreign.postcode  = 123341;
    foreign.addid = 213214;
    
    //插入数据    insert table row
    LKTest* test = [[LKTest alloc]init];
    test.name = @"zhan san";
    test.age = 16;
    
    //外键
    test.address = foreign;
    
    test.isGirl = YES;
    test.like = 'I';
    test.img = [UIImage imageNamed:@"41.png"];
    test.date = [NSDate date];
    test.color = [UIColor orangeColor];
    
    //异步 插入第一条 数据   Insert the first
    
    [globalHelper insertToDB:test];
    
    addText(@"同步插入 完成!  Insert completed synchronization");
    sleep(1);
    
    
    //改个 主键 插入第2条数据   update primary colume value  Insert the second
    test.name = @"li si";
    [globalHelper insertToDB:test callback:^(BOOL isInsert) {
        addText(@"asynchronization insert complete: %@",isInsert>0?@"YES":@"NO");
    }];
    
    //查询   search
    addText(@"同步搜索    sync search");
    NSMutableArray* array = [LKTest searchWithWhere:nil orderBy:nil offset:0 count:100];
    for (NSObject* obj in array) {
        addText(@"%@",[obj printAllPropertys]);
    }
    
    addText(@"休息2秒 开始  为了说明 是异步插入的\n rest for 2 seconds to start is asynchronous inserted to illustrate");
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
        
        [LKDBHelper clearNoneImage:[LKTest class] columes:[NSArray arrayWithObjects:@"img",nil]];
    }];
}
@end

@implementation LKTest
+(void)dbWillInsert:(NSObject *)entity
{
    NSLog(@"will insert : %@",NSStringFromClass(self));
}
+(void)dbDidInserted:(NSObject *)entity result:(BOOL)result
{
    NSLog(@"did insert : %@",NSStringFromClass(self));
}
-(id)userGetValueForModel:(LKDBProperty *)property
{
    if([property.sqlColumeName isEqualToString:@"address"])
    {
        [LKTestForeign insertToDB:self.address];
        return @(self.address.addid);
    }
    return nil;
}
-(void)userSetValueForModel:(LKDBProperty *)property value:(id)value
{
    if([property.sqlColumeName isEqualToString:@"address"])
    {
        self.address = nil;
        
        NSMutableArray* array  = [LKTestForeign searchWithWhere:[NSString stringWithFormat:@"addid = %d",[value intValue]] orderBy:nil offset:0 count:1];

        if(array.count>0)
            self.address = [array objectAtIndex:0];
    }
}
+(void)columeAttributeWithProperty:(LKDBProperty *)property
{
    if([property.sqlColumeName isEqualToString:@"MyAge"])
    {
        property.defaultValue = @"15";
    }
    else if([property.propertyName isEqualToString:@"date"])
    {
        property.isUnique = YES;
        property.checkValue = @"MyDate > '2000-01-01 00:00:00'";
        property.length = 30;
    }
}
+(NSDictionary *)getTableMapping
{
    //return nil 
    return @{@"name":LKSQLInherit,
             @"MyAge":@"age",
             @"img":LKSQLInherit,
             @"MyDate":@"date",
             // version 2 after add
             @"color":LKSQLInherit,
             //version 3 after add
             @"address":LKSQLUserCalculate};
}
+(NSString *)getPrimaryKey
{
    return @"name";
}
+(NSString *)getTableName
{
    return @"LKTestTable";
}
+(int)getTableVersion
{
    return 3;
}
+(LKTableUpdateType)tableUpdateForOldVersion:(int)oldVersion newVersion:(int)newVersion
{
    switch (oldVersion) {
        case 1:
        {
            [self tableUpdateAddColumeWithPN:@"color"];
        }
        case 2:
        {
            [self tableUpdateAddColumeWithName:@"address" sqliteType:LKSQLText];
        }
            break;
    }
    return LKTableUpdateTypeCustom;
}
@end

@implementation LKTestForeign
+(NSString *)getPrimaryKey
{
    return @"addid";
}
+(NSString *)getTableName
{
    return @"LKTestAddress";
}
+(int)getTableVersion
{
    return 1;
}
@end
