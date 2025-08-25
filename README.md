
LKDBHelper
====================================
全自动的 SQLite ORM 框架

1、线程安全，不怕递归死锁

2、线上日活超千万，极佳的代码稳定性。（线上App直接用pod依赖，相同github代码）

3、长期保持迭代，iOS 5 ~ iOS 26 系统均无问题。

简书：不定时更新  [http://www.jianshu.com/users/376b950a20ec](http://www.jianshu.com/users/376b950a20ec/latest_articles) 

# 2.0的超级大升级

全面支持 __NSArray__,__NSDictionary__, __ModelClass__, __NSNumber__, __NSString__, __NSDate__, __NSData__, __UIColor__, __UIImage__, __CGRect__, __CGPoint__, __CGSize__, __NSRange__, __int__,__char__,__float__, __double__, __long__.. 等属性的自动化操作(插入和查询)


# 数据库损坏修复工具

当出现数据库损坏错误：`SQLITE_CORRUPT`、`database disk image is malformed` ，可以使用 `LKDBRecover.xcframework` 进行修复，具体API请查看头文件。

原理：基于 sqlite3.org 的源码中 recover API （ LKDBRecover.xcframework 基于 3.49.1 版本，日期：2025-02-18） ：https://sqlite.org/src/file/ext/recover/sqlite3recover.c


------------------------------------

Requirements
====================================

* iOS 12.0+ 
* ARC only
* FMDB(https://github.com/ccgus/fmdb)

由于 FMDB 限制，需要支持 iOS12 之前系统，自行限定到 FMDB(2.7.5) 和 LKDBHelper (2.6.3)

## Adding to your project

If you are using CocoaPods, then, just add this line to your Podfile <br>

```objective-c
pod 'LKDBHelper'
```

Before iOS12

```objective-c
pod 'LKDBHelper', '2.6.3'
pod 'FMDB', '2.7.5'
```


If you are using encryption, Order can not be wrong <br>

```objective-c
pod 'FMDB/SQLCipher'
pod 'LKDBHelper'
```

@property(strong,nonatomic)NSString* encryptionKey;

## Basic usage

1. Create a new Objective-C class for your data model

```objective-c
@interface LKTest : NSObject
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSUInteger age;
@property (nonatomic, assign) BOOL isGirl;

@property (nonatomic, strong) LKTestForeign *address;
@property (nonatomic, strong) NSArray *blah;
@property (nonatomic, strong) NSDictionary *hoho;

@property (nonatomic, assign) char like;
...
```
2. in the *.m file, overwirte getTableName function  (option)

```objective-c
+ (NSString *)getTableName {
    return @"LKTestTable";
}
```
3. in the *.m file, overwirte callback function (option)

```objective-c
@interface NSObject (LKDBHelper_Delegate)

+ (void)dbDidCreateTable:(LKDBHelper *)helper tableName:(NSString *)tableName;
+ (void)dbDidAlterTable:(LKDBHelper *)helper tableName:(NSString *)tableName addColumns:(NSArray *)columns;

+ (BOOL)dbWillInsert:(NSObject *)entity;
+ (void)dbDidInserted:(NSObject *)entity result:(BOOL)result;

+ (BOOL)dbWillUpdate:(NSObject *)entity;
+ (void)dbDidUpdated:(NSObject *)entity result:(BOOL)result;

+ (BOOL)dbWillDelete:(NSObject *)entity;
+ (void)dbDidDeleted:(NSObject *)entity result:(BOOL)result;

///data read finish
+ (void)dbDidSeleted:(NSObject *)entity;

@end

```
4. Initialize your model with data and insert to database  

```objective-c
    LKTestForeign *foreign = [[LKTestForeign alloc] init];
    foreign.address = @":asdasdasdsadasdsdas";
    foreign.postcode  = 123341;
    foreign.addid = 213214;
    
    //插入数据    insert table row
    LKTest *test = [[LKTest alloc] init];
    test.name = @"zhan san";
    test.age = 16;
    
    //外键 foreign key
    test.address = foreign;
    test.blah = @[@"1", @"2", @"3"];
    test.blah = @[@"0", @[@1] ,@{ @"2" : @2 }, foreign];
    test.hoho = @{@"array" : test.blah, @"foreign" : foreign, @"normal" : @123456, @"date" : [NSDate date]};
    
    //同步 插入第一条 数据   Insert the first
    [test saveToDB];
    //or
    //[globalHelper insertToDB:test];
    
```
5. select 、 delete 、 update 、 isExists 、 rowCount ...

```objective-c
    select:
        
        NSMutableArray *array = [LKTest searchWithWhere:nil orderBy:nil offset:0 count:100];
        for (id obj in array) {
            addText(@"%@",[obj printAllPropertys]);
        }
        
    delete:
        
        [LKTest deleteToDB:test];
        
    update:
        
        test.name = "rename";
        [LKTest updateToDB:test where:nil];
        
    isExists:
        
        [LKTest isExistsWithModel:test];
    
    rowCount:
        
        [LKTest rowCountWithWhere:nil];
        
     
```
6. Description of parameters "where"

```objective-c
 For example: 
        single:  @"rowid = 1"                         or      @{ @"rowid" : @1 }
 
        more:    @"rowid = 1 and sex = 0"             or      @{ @"rowid" : @1, @"sex" : @0 }
                   
                    when where is "or" type , such as @"rowid = 1 or sex = 0"
                    you only use NSString
 
        array:   @"rowid in (1,2,3)"                  or      @{ @"rowid" : @[@1, @2, @3] }
            
        composite:  @"rowid in (1,2,3) and sex=0 "      or      @{ @"rowid" : @[@1, @2, @3], @"sex" : @0}
 
        If you want to be judged , only use NSString
        For example: @"date >= '2013-04-01 00:00:00'"
```

## table mapping

overwirte getTableMapping Function (option)

```objective-c
//手动or自动 绑定sql列
+ (NSDictionary *)getTableMapping {
    return @{ @"name" : LKSQL_Mapping_Inherit,
              @"MyAge" : @"age",
              @"img" : LKSQL_Mapping_Inherit,
              @"MyDate" : @"date",
              
              // version 2 after add
              @"color" : LKSQL_Mapping_Inherit,
              
              //version 3 after add
              @"address" : LKSQL_Mapping_UserCalculate,
              @"error" : LKSQL_Mapping_Inherit
              };
}
```

## table update (option)

```objective-c
// 表结构更新回调
+ (void)dbDidAlterTable:(LKDBHelper *)helper tableName:(NSString *)tableName addColumns:(NSArray *)columns {
    for (int i = 0; i < columns.count; i++) {
        LKDBProperty *p = [columns objectAtIndex:i];
        if ([p.propertyName isEqualToString:@"error"]) {
            [helper executeDB:^(FMDatabase *db) {
                NSString *sql = [NSString stringWithFormat:@"update %@ set error = name", tableName];
                [db executeUpdate:sql];
            }];
        }
    }
    LKErrorLog(@"your know %@", columns);
}
```
## set column attribute (option)

```objective-c
// 定制化列属性
+ (void)columnAttributeWithProperty:(LKDBProperty *)property {
    if ([property.sqlColumnName isEqualToString:@"MyAge"]) {
        property.defaultValue = @"15";
    } else if ([property.propertyName isEqualToString:@"date"]) {
        // if you use unique,this property will also become the primary key
        //        property.isUnique = YES;
        property.checkValue = @"MyDate > '2000-01-01 00:00:00'";
        property.length = 30;
    }
}
```

## demo screenshot
![demo screenshot](https://github.com/li6185377/LKDBHelper-SQLite-ORM/raw/master/screenshot/Snip20130620_8.png)
<br>table test data<br>
![](https://github.com/li6185377/LKDBHelper-SQLite-ORM/raw/master/screenshot/Snip20130620_6.png)
<br>foreign key data<br>
![](https://github.com/li6185377/LKDBHelper-SQLite-ORM/raw/master/screenshot/Snip20130620_7.png)

----------
# Use in swift

Remember to override the class function `getTableName` for model.

Change-log
==========

**Version 1.1** @ 2012-6-20

- automatic table mapping
- support optional columns
- support column attribute settings
- you can return column content

**Version 1.0** @ 2013-5-19

- overwrite and rename LKDBHelper
- property type support: UIColor,NSDate,UIImage,NSData,CGRect,CGSize,CGPoint,int,float,double,NSString,short,char,bool,NSInterger..
- fix a recursive deadlock. 
- rewrite the asynchronous operation - 
- thread-safe 
- various bug modified optimize cache to improve performance 
- test and demos
- bug fixes, speed improvements

**Version 0.0.1** @ 2012-10-1

- Initial release with LKDAOBase


-------

License
=======

This code is distributed under the terms and conditions of the MIT license. 

-------

Contribution guidelines
=======

* if you are fixing a bug you discovered, please add also a unit test so I know how exactly to reproduce the bug before merging

-------

Contributors
=======

Author: Jianghuai Li

Contributors: waiting for you to join

