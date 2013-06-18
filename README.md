#LKDBHelper
this is sqlite ORM (an automatic database operation) <br>
thread-safe and not afraid of recursive deadlock

Next Version Enhancements
-------------------

- sql column names and property name mapping ,column support "not null","unique","check","default"

#version 1.0
1, fix a recursive deadlock. <br>
2, rewrite the asynchronous operation - <br>
3, thread-safe <br>
4, various bug modified optimize cache to improve performance <br>
<br>
code using FMDatabase , can use the latest FMDatabase: https://github.com/ccgus/fmdb <br>
The entity class automatic operation data
#v1.0版本
1、修复了 递归死锁。   <br>
2、重写了 异步操作   <br>
3、线程安全   <br>
4、各种bug 修改,优化缓存,提高性能  <br>
<br>
低层采用FMDatabase 可自行使用最新的FMDatabase :https://github.com/ccgus/fmdb <br>
根据实体类 自动操作数据 <br>

## Automatic Reference Counting (ARC)
##example code can download the source code to look at it

- 需要重载下  你自己的实体类中的 +getTableName 方法  来设置表名 
  还可以 重载 + getTableVersion 来设置表版本 
- 根据Model自动数据库 操作  不用写 繁琐的SQL语句了  

- 再也不用一个个去找字段 是否写错 格式 是否对应

- 使用方法跟 LKDaobase 差不多  不过 取消了 继承LKDaobase 的方式  采用了LKDBHelper 统一管理

- 加入了 表版本管理     比如  当你升级的时候  需要对表 进行升级   可重载

+(LKTableUpdateType)tableUpdateWithDBHelper:(LKDBHelper *)helper oldVersion:(int)oldVersion newVersion:(int)newVersion 
方法来  自己写操作 或者用默认的 删除旧表

- 每种操作 都有异步和同步 两种方式 可自行选择

具体 示例代码可下载源码自行查看
```object-c
 Description of parameters "where"
 For example: 
        single:  @"rowid = 1"                         or      @{@"rowid":@1}
 
        more:    @"rowid = 1 and sex = 0"             or      @{@"rowid":@1,@"sex":@0}
                   
                    when where is "or" type , such as @"rowid = 1 or sex = 0"
                    you only use NSString
 
        array:   @"rowid in (1,2,3)"                  or      @{@"rowid":@[@1,@2,@3]}
            
        composite:  @"rowid in (1,2,3) and sex=0 "    or      @{@"rowid":@[@1,@2,@3],@"sex":@0}
 
        If you want to be judged , only use NSString
        For example: @"date >= '2013-04-01 00:00:00'"
```
```object-c

    //清空数据库
    [[LKDBHelper sharedDBHelper] dropAllTable];
    
    //创建表  会根据表的版本号  来判断具体的操作 . create table need to manually call
    [[LKDBHelper sharedDBHelper] createTableWithModelClass:[LKTest class]];
    [[LKDBHelper sharedDBHelper] createTableWithModelClass:[LKTestForeign class]];
    
    //清空表数据   clear table data
    [[LKDBHelper sharedDBHelper] clearTableData:[LKTest class]];
    
    
    LKTestForeign* foreign = [[LKTestForeign alloc]init];
    foreign.address = @":asdasdasdsadasdsdas";
    foreign.postcode  = 123341;
    foreign.addid = 213214;

    //插入数据    insert table row
    LKTest* test = [[LKTest alloc]init];
    test.name = @"zhan san";
    test.age = 16;
    
    //外键 foreign key
    test.address = foreign;
    
    test.isGirl = YES;
    test.like = 'I';
    test.img = [UIImage imageNamed:@"41.png"];
    test.date = [NSDate date];
    test.color = [UIColor orangeColor];
    
    // 插入第一条 数据   Insert the first row
    
    [[LKDBHelper sharedDBHelper] insertToDB:test];
    
    addText(@"同步插入 完成!");
    
    //改个 主键 插入第2条数据   update primary colume value ,  Insert the second
    test.name = @"li si";
    [[LKDBHelper sharedDBHelper] insertToDB:test callback:^(BOOL isInsert) {
        addText(@"异步插入 %@",isInsert>0?@"YES":@"NO");
    }];
    
    //查询   search
    addText(@"同步搜索");
    NSMutableArray* array = [LKTest searchWithWhere:nil orderBy:nil offset:0 count:100];
    for (NSObject* obj in array) {
        addText(@"%@",[obj printAllPropertys]);
    }
    
    addText(@"休息2秒 开始  为了说明 是异步插入的");
    sleep(2);
    addText(@"休息2秒 结束");
    //异步
    [[LKDBHelper sharedDBHelper] search:[LKTest class] where:nil orderBy:nil offset:0 count:100 callback:^(NSMutableArray *array) {
        
        addText(@"异步搜索 结束");
        for (NSObject* obj in array) {
            addText(@"%@",[obj printAllPropertys]);
        }
        sleep(1);
        
        //修改    update
        LKTest* test2 = [array objectAtIndex:0];
        test2.name = @"wang wu";
        [[LKDBHelper sharedDBHelper] updateToDB:test2 where:nil];
        
        addText(@"修改完成 updated ");
        
        array =  [[LKDBHelper sharedDBHelper] search:[LKTest class] where:nil orderBy:nil offset:0 count:100];
        for (NSObject* obj in array) {
            addText(@"%@",[obj printAllPropertys]);
        }
        
        test2.rowid = 0;
        
        BOOL ishas = [[LKDBHelper sharedDBHelper] isExistsModel:test2];
        if(ishas)
        {
            //删除    delete
            [[LKDBHelper sharedDBHelper] deleteToDB:test2];
        }
        
        addText(@"删除完成        deleted");
        sleep(1);
        
        array =  [[LKDBHelper sharedDBHelper] search:[LKTest class] where:nil orderBy:nil offset:0 count:100];
        for (NSObject* obj in array) {
            addText(@"%@",[obj printAllPropertys]);
        }
        
        addText(@"示例 结束  example finished\n\n");
        
        
        
        //Expansion: Delete the picture is no longer stored in the database record
        addText(@"扩展:  删除已不再数据库中保存的 图片记录");
        //目前 已合并到LKDBHelper 中  就先写出来 给大家参考下
        
        [[LKDBHelper sharedDBHelper] clearNoneImage:[LKTest class] columes:[NSArray arrayWithObjects:@"img",nil]];
    }];

```
