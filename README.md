LKDBHelper
==========

automatic database operation . use fmdb 
根据Model自动数据库 操作  不用写 繁琐的SQL语句了  

再也不用一个个去找字段 是否写错 格式 是否对应

yeah 总于有人star了  thanks  



1.使用方法跟 LKDaobase 差不多  不过 取消了 继承LKDaobase 的方式  采用了LKDBHelper 统一管理

2.加入了 表版本管理     比如  当你升级的时候  需要对表 进行升级   可重载

+(LKTableUpdateType)tableUpdateWithDBHelper:(LKDBHelper *)helper oldVersion:(int)oldVersion newVersion:(int)newVersion 
方法来  自己写操作 或者用默认的 删除旧表

3.每种操作 都有异步和同步 两种方式 可自行选择

具体 示例代码可下载源码自行查看


