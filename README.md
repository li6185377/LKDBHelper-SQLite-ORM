LKDBHelper
====================================
this is sqlite ORM (an automatic database operation) <br>
thread-safe and not afraid of recursive deadlock

------------------------------------
Requirements
====================================

* iOS 4.3+ 
* ARC only
* FMDB(https://github.com/ccgus/fmdb)

------------------------------------
Basic usage
====================================

1. Create a new Objective-C class for your data model

```
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
2. in the *.m file, overwirte getTableName function

```
+(NSString *)getTableName
{
    return @"LKTestTable";
}
```
3. In your app start function

```
    LKDBHelper* globalHelper = [LKDBHelper getUsingLKDBHelper];
   
    //create table need to manually call! will check the version number of the table
    [globalHelper createTableWithModelClass:[LKTest class]];
```
4. Initialize your model with data and insert to database

```
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
5. select 、 delete 、 update 、 isExists 、 rowCount ...

```
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
6. Description of parameters "where"

```
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

demo screenshot:

(https://github.com/li6185377/LKDBHelper-SQLite-ORM/blob/master/screenshot/Snip20130620_8.png?raw=true)
(https://github.com/li6185377/LKDBHelper-SQLite-ORM/blob/master/screenshot/Snip20130620_6.png?raw=true)
(https://github.com/li6185377/LKDBHelper-SQLite-ORM/blob/master/screenshot/Snip20130620_7.png?raw=true)

----------
Change-log
==========

**Version 1.1** @ 2012-6-20

- automatic table mapping
- support optional columns
- support colume attribute settings
- you can return colume content

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

