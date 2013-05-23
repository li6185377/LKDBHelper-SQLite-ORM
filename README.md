#LKDBHelper
this is sqlite ORM (an automatic database operation) <br>
thread-safe and not afraid of recursive deadlock
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

```ruby 需要重载下  你自己的实体类中的 +getTableName 方法  来设置表名 
  还可以 重载 + getTableVersion 来设置表版本 ```

根据Model自动数据库 操作  不用写 繁琐的SQL语句了  

再也不用一个个去找字段 是否写错 格式 是否对应

yeah 总于有人star了  thanks  

1.使用方法跟 LKDaobase 差不多  不过 取消了 继承LKDaobase 的方式  采用了LKDBHelper 统一管理

2.加入了 表版本管理     比如  当你升级的时候  需要对表 进行升级   可重载

+(LKTableUpdateType)tableUpdateWithDBHelper:(LKDBHelper *)helper oldVersion:(int)oldVersion newVersion:(int)newVersion 
方法来  自己写操作 或者用默认的 删除旧表

3.每种操作 都有异步和同步 两种方式 可自行选择

具体 示例代码可下载源码自行查看


