LKDBHelper
====================================
this is sqlite ORM (an automatic database operation) <br>
thread-safe and not afraid of recursive deadlock

新版 添加字段的时候  可以直接  定义属性就好了  不用再调用  [self tableUpdateAddColumnWithPN:@"color"]; 这种的方法了
#v1.1
* 支持 `列名` 和 `属性` 之间的绑定。<br>
* 你也可以 设置 列 的属性。<br>
* 当你列 映射 使用 `LKSQLUserCalculate` 值  。 就重载下面两个方法,由你决定插入到数据库中的数据<br>
`-(id)userGetValueForModel:(LKDBProperty *)property`<br>
`-(void)userSetValueForModel:(LKDBProperty *)property value:(id)value`<br>

* 还增加了两个添加列的方法,方便在表版本升级的时候调用。<br>
* 为了 支持多数据库 取消了 `shareDBHelper` 这个方法, <br>
改成 `[modelClass getUsingDBHelper]`  这样每个model 可以重载 , 选择要使用的数据库<br>
可以看 `NSObject+LKDBHelper` 里面 的方法<br>
#v1.1
* Support `column name`  binding  `attributes`. <br>
* You can also set the properties of the column. <br>
* When you use `LKSQLUserCalculate` column mapping value. To override the following two methods you decide to insert data in the database <br>
`- (id) userGetValueForModel: (LKDBProperty *) property` <br>
`- (void) userSetValueForModel: (LKDBProperty *) property value: (id) value` <br>

* Also added two ways to add columns for easy upgrades in the table when called. <br>
* In order to support multiple databases canceled `shareDBHelper` this method, <br>
Changed to `[modelClass getUsingDBHelper]` so that each model can be overloaded, select the database you want to use <br>
You can see `NSObject LKDBHelper` method inside <br>

------------------------------------
Requirements
====================================

* iOS 4.3+ 
* ARC only
* FMDB(https://github.com/ccgus/fmdb)

##Adding to your project

If you are using CocoaPods, then, just add this line to your PodFile<br>

```objective-c
pod 'LKDBHelper', :head
```



##Basic usage

1 . Create a new Objective-C class for your data model

```objective-c
@interface LKTest : NSObject
@property(copy,nonatomic)NSString* name;
@property int  age;
@property BOOL isGirl;

@property(strong,nonatomic)LKTestForeign* address;

@property char like;
@property(strong,nonatomic) UIImage* img;
@property(strong,nonatomic) NSDate* date;

@property(copy,nonatomic)NSString* error;
@property(copy,nonatomic)UIColor* color;
@end
```
2 . in the *.m file, overwirte getTableName function

```objective-c
+(NSString *)getTableName
{
    return @"LKTestTable";
}
```
3 . In your app start function

```objective-c
    LKDBHelper* globalHelper = [LKDBHelper getUsingLKDBHelper];
   
    //create table need to manually call! will check the version number of the table
    [globalHelper createTableWithModelClass:[LKTest class]];
```
4 . Initialize your model with data and insert to database

```objective-c
    LKTest* test = [[LKTest alloc]init];
    test.name = @"zhan san";
    test.age = 16;
    
    test.address = foreign;
    
    test.isGirl = YES;
    test.like = 'I';
    test.img = [UIImage imageNamed:@"41.png"];
    test.date = [NSDate date];
    test.color = [UIColor orangeColor];
    
    [globalHelper insertToDB:test];
    
```
5 . select 、 delete 、 update 、 isExists 、 rowCount ...

```objective-c
    select:
        
        NSMutableArray* array = [globalHelper search:[LKTest class] where:nil orderBy:nil offset:0 count:100];
        for (NSObject* obj in array) {
            addText(@"%@",[obj printAllPropertys]);
        }
        
    delete:
        
        [globalHelper deleteToDB:test];
        
    update:
        
        test.name = "rename";
        [globalHelper updateToDB:test where:nil];
        
    isExists:
        
        [globalHelper isExistsModel:test];
    
    rowCount:
        
        [globalHelper rowCount:[LKTest class] where:nil];
        
     
```
6 . Description of parameters "where"

```objective-c
 For example: 
        single:  @"rowid = 1"                         or      @{@"rowid":@1}
 
        more:    @"rowid = 1 and sex = 0"             or      @{@"rowid":@1,@"sex":@0}
                   
                    when where is "or" type , such as @"rowid = 1 or sex = 0"
                    you only use NSString
 
        array:   @"rowid in (1,2,3)"                  or      @{@"rowid":@[@1,@2,@3]}
            
        composite:  @"rowid in (1,2,3) and sex=0 "      or      @{@"rowid":@[@1,@2,@3],@"sex":@0}
 
        If you want to be judged , only use NSString
        For example: @"date >= '2013-04-01 00:00:00'"
```

##table mapping

overwirte getTableMapping Function

```objective-c
+(NSDictionary *)getTableMapping
{
    //return nil 
    return @{@"name":LKSQLInherit,
             @"MyAge":@"age",
             @"img":LKSQLInherit,
             @"MyDate":@"date",
             @"color":LKSQLInherit,
             @"address":LKSQLUserCalculate};
}
```

##table update

```objective-c
+(LKTableUpdateType)tableUpdateForOldVersion:(int)oldVersion newVersion:(int)newVersion
{
    switch (oldVersion) {
        case 1:
        {
            [self tableUpdateAddColumnWithPN:@"color"];
        }
        case 2:
        {
            [self tableUpdateAddColumnWithName:@"address" sqliteType:LKSQLText];
        }
            break;
    }
    return LKTableUpdateTypeCustom;
}
```
## set column attribute

```objective-c
+(void)columnAttributeWithProperty:(LKDBProperty *)property
{
    if([property.sqlColumnName isEqualToString:@"MyAge"])
    {
        property.defaultValue = @"15";
    }
    if([property.propertyName isEqualToString:@"date"])
    {
        property.isUnique = YES;
        property.checkValue = @"MyDate > '2000-01-01 00:00:00'";
        property.length = 30;
    }
}
```

##demo screenshot
![demo screenshot](https://github.com/li6185377/LKDBHelper-SQLite-ORM/raw/master/screenshot/Snip20130620_8.png)
<br>table test data<br>
![](https://github.com/li6185377/LKDBHelper-SQLite-ORM/raw/master/screenshot/Snip20130620_6.png)
<br>foreign key data<br>
![](https://github.com/li6185377/LKDBHelper-SQLite-ORM/raw/master/screenshot/Snip20130620_7.png)

----------
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

