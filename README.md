LKDBHelper
==========

automatic database operation . use fmdb 

1.使用方法跟 LKDaobase 差不多  不过 取消了 继承LKDaobase 的方式  采用了LKDBHelper 统一管理

2.加入了 表版本管理     比如  当你升级的时候  需要对表 进行升级   可重载

+(LKTableUpdateType)tableUpdateWithDBHelper:(LKDBHelper *)helper oldVersion:(int)oldVersion newVersion:(int)newVersion 
方法来  自己写操作 或者用默认的 删除旧表

3.每种操作 都有异步和同步 两种方式 可自行选择

具体 代码可下载源码自行查看

LKDBHelper[7892:c07] 示例 开始 


2013-04-15 20:47:36.893 LKDBHelper[7892:c07] 插入完成 1

2013-04-15 20:47:36.896 LKDBHelper[7892:c07] 


 name : zhan san 
 
 age : 16 
 
 isGirl : 1
 
 like : 73 
 
 img : img7841041540 
 
 date : 2013-04-15 12:47:36 +0000 
 
 error :  
 
 color : 1.000,0.500,0.000,1.000 
 
2013-04-15 20:47:36.896 LKDBHelper[7892:c07] 


 name : li si 
 
 age : 16 
 
 isGirl : 1 
 
 like : 73 
 
 img : img7841042986 
 
 date : 2013-04-15 12:47:36 +0000 
 
 error :  
 
 color : 1.000,0.500,0.000,1.000 
 
2013-04-15 20:47:36.899 LKDBHelper[7892:c07] 修改完成

2013-04-15 20:47:36.900 LKDBHelper[7892:c07] 


 name : wang wu 
 
 age : 16 
 
 isGirl : 1 
 
 like : 73 
 
 img : img7841041540 
 
 date : 2013-04-15 12:47:36 +0000 
 
 error :  
 
 color : 1.000,0.500,0.000,1.000 
 
2013-04-15 20:47:36.900 LKDBHelper[7892:c07] 


 name : li si 
 
 age : 16 
 
 isGirl : 1 
 
 like : 73 
 
 img : img7841042986 
 
 date : 2013-04-15 12:47:36 +0000 
 
 error :  
 
 color : 1.000,0.500,0.000,1.000 
 
2013-04-15 20:47:36.903 LKDBHelper[7892:c07] 删除完成

2013-04-15 20:47:36.904 LKDBHelper[7892:c07] 


 name : li si 
 
 age : 16 
 
 isGirl : 1 
 
 like : 73 
 
 img : img7841042986 
 
 date : 2013-04-15 12:47:36 +0000 
 
 error :  
 
 color : 1.000,0.500,0.000,1.000 
 
2013-04-15 20:47:36.904 LKDBHelper[7892:c07] 示例 结束 

