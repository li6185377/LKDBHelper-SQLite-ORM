//
//  LKDBHelper.m
//  upin
//
//  Created by Fanhuan on 12-12-6.
//  Copyright (c) 2012年 linggan. All rights reserved.
//

#import "LKDBHelper.h"

@interface LKDBHelper()
@property(strong,nonatomic)FMDatabaseQueue* bindingQueue;
@property(copy,nonatomic)NSString* dbname;
@property(strong,nonatomic)NSMutableDictionary* tableManager;
@end

@implementation LKDBHelper
+(LKDBHelper *)sharedDBHelper
{
    static LKDBHelper* dbhelper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dbhelper = [[self alloc]init];
    });
    return dbhelper;
}
-(FMDatabaseQueue *)getBindingQueue
{
    return self.bindingQueue;
}
- (id)init
{
    self = [super init];
    if (self) {
        [self setDBName:@"LKDB"];   
    }
    return self;
}
-(void)setDBName:(NSString *)fileName
{
    if([self.dbname isEqualToString:fileName] == NO)
    {
        if(! [fileName hasSuffix:@".db"])
        {
            self.dbname = [NSString stringWithFormat:@"%@.db",fileName];
        }
        else
        {
            self.dbname = fileName;
        }
        [self.bindingQueue close];
        self.bindingQueue = [[FMDatabaseQueue alloc]initWithPath:[LKDBUtils getPathForDocuments:self.dbname inDir:@"db"]];
        
        
        //获取表版本管理
        self.tableManager = [NSMutableDictionary dictionaryWithCapacity:0];
        [self executeDB:^(FMDatabase *db) {
            [db executeUpdate:@"CREATE TABLE IF NOT EXISTS LKTableManager(table_name text primary key,version integer)"];
            FMResultSet* set = [db executeQuery:@"select table_name,version from LKTableManager"];
            while ([set next]) {
                [_tableManager setObject:[NSNumber numberWithInt:[set intForColumnIndex:1]] forKey:[set stringForColumnIndex:0]];
            }
            [set close];
        }];
    }
}

//当 NSDictionary 的value 是NSArray 类型时  使用 in 语句   where  name in (value1,value2)
-(NSString*)dictionaryToSqlWhere:(NSDictionary*)dic andValues:(NSMutableArray*)values
{
    NSMutableString* wherekey = [NSMutableString stringWithCapacity:0];
    if(dic != nil && dic.count >0 )
    {
        NSArray* keys = dic.allKeys;
        for (int i=0; i< keys.count;i++) {
            
            NSString* key = [keys objectAtIndex:i];
            id va = [dic objectForKey:key];
            if([va isKindOfClass:[NSArray class]])
            {
                if(wherekey.length > 0)
                {
                    [wherekey appendString:@" and "];
                }
                [wherekey appendFormat:@" %@ in(",key];
                NSArray* vlist = va;
                for (int j=0; j<vlist.count; j++) {
                    [wherekey appendString:@" ? "];
                    if(j != vlist.count-1)
                    {
                        [wherekey appendString:@","];
                    }
                    else
                    {
                        [wherekey appendString:@") "];
                    }
                    [values addObject:[vlist objectAtIndex:j]];
                }
            }
            else
            {
                if(wherekey.length > 0)
                {
                    [wherekey appendFormat:@" and %@ = ? ",key];
                }
                else
                {
                    [wherekey appendFormat:@" %@ = ? ",key];
                }
                [values addObject:va];
            }
            
        }
    }
    return wherekey;
}
-(NSMutableDictionary *)getTableManager
{
    return self.tableManager;
}
-(void)dealloc
{
    [self.bindingQueue close];
}
@end
@implementation LKDBHelper(DatabaseManager)
const static NSString* normaltypestring = @"floatdoublelongshort";
const static NSString* inttypesstring = @"intcharshort";
const static NSString* blobtypestring = @"NSDataUIImage";
//把Object-c 类型 转换为sqlite 类型
+(NSString *)toDBType:(NSString *)type
{
    if([inttypesstring rangeOfString:type].location != NSNotFound)
    {
        return LKSQLInt;
    }
    if ([normaltypestring rangeOfString:type].location != NSNotFound) {
        return LKSQLDouble;
    }
    if ([blobtypestring rangeOfString:type].location != NSNotFound) {
        return LKSQLBlob;
    }
    return LKSQLText;
}

-(void)executeDB:(void (^)(FMDatabase *db))block
{
    __block BOOL lock = YES;
    [self.bindingQueue inDatabase:^(FMDatabase *db) {
        block(db);
        lock = NO;
    }];
    while (lock) {}
}
-(void)dropAllTable
{
    [self.bindingQueue inDatabase:^(FMDatabase* db){
        FMResultSet* set = [db executeQuery:@"select name from sqlite_master where type='table'"];
        NSMutableArray* dropTables = [NSMutableArray arrayWithCapacity:0];
        while ([set next]) {
            [dropTables addObject:[set stringForColumnIndex:0]];
        }
        [set close];
        for (NSString* tableName in dropTables) {
            NSString* dropTable = [NSString stringWithFormat:@"drop table %@",tableName];
            [db executeUpdate:dropTable];
        }
    }];
}
-(void)dropTableWithClass:(Class)modelClass
{
    [self.bindingQueue inDatabase:^(FMDatabase *db) {
        NSString* dropTable = [NSString stringWithFormat:@"drop table %@",[modelClass getTableName]];
        [db executeUpdate:dropTable];
    }];
}
-(void)createTableWithModelClass:(Class)modelClass
{
    NSString* tableName = [modelClass getTableName];
    if([LKDBUtils checkStringIsEmpty:tableName])
    {
        //如果 返回的表名为空  就提示
        NSLog(@"ERROR TableName is None! with model %@",NSStringFromClass(modelClass));
        return;
    }
    int version = [[self.tableManager objectForKey:tableName] intValue];
    int newVersion = [modelClass getTableVersion];
    if(newVersion != version && version > 0)
    {
        LKTableUpdateType updateType = [modelClass tableUpdateWithDBHelper:self oldVersion:version newVersion:newVersion];
        switch (updateType) {
            case LKTableUpdateTypeDefault:
            {
                [self dropTableWithClass:modelClass];
            }
                break;
            case LKTableUpdateTypeCustom:
            {
                return;
            }
                break;
        }
    }
    if(version == newVersion)
    {
        //已创建表 就跳过
        return;
    }
    
    
    NSDictionary* dic  = [modelClass getPropertys];
    NSString* primaryKey = [modelClass getPrimaryKey];
    
    NSArray* pronames = [dic objectForKey:@"name"];
    NSArray* protypes = [dic objectForKey:@"type"];
    NSMutableArray* sqltypes = [dic objectForKey:@"sqltype"];
    [sqltypes removeAllObjects];
    
    for (int i =0; i<pronames.count; i++) {
        NSString* columeName = [pronames objectAtIndex:i];
        NSString* columeType = [protypes objectAtIndex:i];
        if([primaryKey isEqualToString:columeName])
        {
            [sqltypes addObject:[NSString stringWithFormat:@"%@ %@",[LKDBHelper toDBType:columeType],LKSQLPrimaryKey]];
        }
        else
        {
            [sqltypes addObject:[LKDBHelper toDBType:columeType]];
        }
    }
    
    //拼接 创建表语句
    NSMutableString* pars = [NSMutableString string];
    for (int i=0; i<pronames.count; i++) {
        [pars appendFormat:@"%@ %@",[pronames objectAtIndex:i],[sqltypes objectAtIndex:i]];
        if(i+1 !=pronames.count)
        {
            [pars appendString:@","];
        }
    }
    
    NSString* createTable = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@)",tableName,pars];
    
    __block BOOL isCreated = NO;
    [self executeDB:^(FMDatabase *db) {
       isCreated = [db executeUpdate:createTable];
    }];
    if(isCreated)
    {
        [self.tableManager setObject:tableName forKey:[NSNumber numberWithInt:newVersion]];
        [self executeDB:^(FMDatabase *db) {
            [db executeUpdate:[NSString stringWithFormat:@"replace into LKTableManager(table_name,version) values('%@',%d)",tableName,newVersion]];
        }];
    }
}

@end
@implementation LKDBHelper(DatabaseExecute)

#pragma mark - row count operation
-(int)rowCount:(Class)modelClass where:(id)where
{
    __block int result= 0;
    [self executeDB:^(FMDatabase *db) {
        result = [self rowCount:modelClass where:where db:db];
    }];
    return result;
}
-(void)rowCount:(Class)modelClass where:(id)where callback:(void (^)(int))callback
{
    [self.bindingQueue inDatabase:^(FMDatabase *db) {
        callback([self rowCount:modelClass where:where db:db]);
    }];
}
-(int)rowCount:(Class)modelClass where:(id)where db:(FMDatabase*)db
{
    NSMutableString* rowCountSql = [NSMutableString stringWithFormat:@"select count(rowid) from %@ ",[modelClass getTableName]];
    FMResultSet* resultSet = nil;
    if([where isKindOfClass:[NSString class]] && [LKDBUtils checkStringIsEmpty:where]==NO)
    {
        [rowCountSql appendFormat:@" where %@",where];
        resultSet = [db executeQuery:rowCountSql];
    }
    else if([where isKindOfClass:[NSDictionary class]])
    {
        NSMutableArray* valuesarray = [NSMutableArray array];
        NSString* ww = [self dictionaryToSqlWhere:where andValues:valuesarray];
        [rowCountSql appendFormat:@" where %@",ww];
        resultSet = [db executeQuery:rowCountSql withArgumentsInArray:valuesarray];
    }
    else
    {
        resultSet = [db executeQuery:rowCountSql];
    }
    int result = 0;
    if([resultSet next])
    {
        result =  [resultSet intForColumnIndex:0];
    }
    [resultSet close];
    return result;
}
#pragma mark- search operation
-(NSMutableArray *)search:(Class)modelClass where:(id)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count db:(FMDatabase*)db
{
    NSMutableString* query = [NSMutableString stringWithFormat:@"select rowid,* from %@ ",[modelClass getTableName]];
    NSMutableArray* values = nil;
    if([where isKindOfClass:[NSString class]] && [LKDBUtils checkStringIsEmpty:where]==NO)
    {
        [query appendFormat:@" where %@ ",where];
    }
    else if ([where isKindOfClass:[NSDictionary class]] && [where count] > 0)
    {
        values = [NSMutableArray arrayWithCapacity:[where count]];
        NSString* wherekey = [self dictionaryToSqlWhere:where andValues:values];
        [query appendFormat:@" where %@ ",wherekey];
    }
    
    [self sqlString:query AddOder:orderBy offset:offset count:count];
    
    __block NSMutableArray* results = nil;
    if(db == nil)
    {
        [self executeDB:^(FMDatabase *db) {
            results = [self executeSql:query values:values db:db Class:modelClass];
        }];
    }
    else
    {
        results = [self executeSql:query values:values db:db Class:modelClass];
    }
    return results;
}
-(NSMutableArray *)search:(Class)modelClass where:(id)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count
{
    return [self search:modelClass where:where orderBy:orderBy offset:offset count:count db:nil];
}
-(void)search:(Class)modelClass where:(id)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count callback:(void (^)(NSMutableArray *))block
{
    [self.bindingQueue inDatabase:^(FMDatabase *db) {
        block([self search:modelClass where:where orderBy:orderBy offset:offset count:count db:db]);
    }];
}
-(NSMutableArray*)executeSql:(NSString*)sql values:(NSArray*)values db:(FMDatabase*)db Class:(Class) modelClass
{
    FMResultSet* set = nil;
    if(values == nil)
    {
        set = [db executeQuery:sql];
    }
    else
    {
        set = [db executeQuery:sql withArgumentsInArray:values];
    }
    return [self executeResult:set Class:modelClass];
}
-(void)sqlString:(NSMutableString*)sql AddOder:(NSString*)orderby offset:(int)offset count:(int)count
{
    if([LKDBUtils checkStringIsEmpty:orderby] == NO)
    {
        [sql appendFormat:@" order by %@ ",orderby];
    }
    [sql appendFormat:@" limit %d offset %d ",count,offset];
}
- (NSMutableArray *)executeResult:(FMResultSet *)set Class:(Class)modelClass
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:0];
    NSDictionary* dic  = [modelClass getPropertys];
    
    NSArray* pronames = [dic objectForKey:@"name"];
    NSArray* protypes = [dic objectForKey:@"type"];
    
    while ([set next]) {
        NSObject* bindingModel = [[modelClass alloc]init];
        bindingModel.rowid = [set intForColumnIndex:0];
        for (int i=0; i< pronames.count; i++) {
            NSString* columeName = [pronames objectAtIndex:i];
            NSString* columeType = [protypes objectAtIndex:i];
            id value = nil;
            if([normaltypestring rangeOfString:columeType].location != NSNotFound)
            {
                value = [NSNumber numberWithDouble:[set doubleForColumn:columeName]];
            }
            else if([inttypesstring rangeOfString:columeType].location != NSNotFound)
            {
                value = [NSNumber numberWithInt:[set intForColumn:columeName]];
            }
            else
            {
                value = [set stringForColumn:columeName];
            }
            [bindingModel modelSetValue:value key:columeName type:columeType];
        }
        [array addObject:bindingModel];
    }
    [set close];
    return array;
}
#pragma mark- insert operation
-(BOOL)insertToDB:(NSObject *)model
{
    return [self insertToDB:model db:nil];
}
-(void)insertToDB:(NSObject *)model callback:(void (^)(BOOL))block
{
    [self.bindingQueue inDatabase:^(FMDatabase *db) {
        BOOL result = [self insertToDB:model db:db];
        if(block != nil)
        {
            block(result);
        }
    }];
}

-(BOOL)insertWhenNotExists:(NSObject *)model
{
    if([self isExistsModel:model]==NO)
    {
        return [self insertToDB:model];
    }
    return NO;
}
-(void)insertWhenNotExists:(NSObject *)model callback:(void (^)(BOOL))block
{
    if([self isExistsModel:model]==NO)
    {
        [self insertToDB:model callback:block];
    }
}

-(BOOL)insertToDB:(NSObject*)model db:(FMDatabase*)db{
    if(model == nil)
    {
        NSLog(@"LKDBHelper Insert Fail 。。 Model = nil");
        return false;
    }
    Class modelClass = model.class;
    NSDictionary* dic  = [modelClass getPropertys];
    NSArray* pronames = [dic objectForKey:@"name"];
    NSArray* protypes = [dic objectForKey:@"type"];
    
    NSMutableString* insertKey = [NSMutableString stringWithCapacity:0];
    NSMutableString* insertValuesString = [NSMutableString stringWithCapacity:0];
    
    NSMutableArray* insertValues = [NSMutableArray arrayWithCapacity:pronames.count];
    for (int i=0; i<pronames.count; i++) {
        
        NSString* columeName = [pronames objectAtIndex:i];
        NSString* columeType = [protypes objectAtIndex:i];
        
        [insertKey appendFormat:@"%@,", columeName];
        [insertValuesString appendString:@"?,"];
        id value = [model modelGetValueWithKey:columeName type:columeType];
        if(value == nil)
        {
            value = @"";
        }
        [insertValues addObject:value];
    }
    //删除尾部的 "," 号
    [insertKey deleteCharactersInRange:NSMakeRange(insertKey.length - 1, 1)];
    [insertValuesString deleteCharactersInRange:NSMakeRange(insertValuesString.length - 1, 1)];
    
    //拼接insertSQL 语句  采用 replace 插入
    NSString* insertSQL = [NSString stringWithFormat:@"replace into %@(%@) values(%@)",[modelClass getTableName],insertKey,insertValuesString];
    
    __block BOOL execute = NO;
    __block int lastInsertRowId = 0;
    if(db == nil)
    {
        [self executeDB:^(FMDatabase *db) {
            execute = [db executeUpdate:insertSQL withArgumentsInArray:insertValues];
            lastInsertRowId= db.lastInsertRowId;
        }];
    }
    else
    {
        execute = [db executeUpdate:insertSQL withArgumentsInArray:insertValues];
        lastInsertRowId= db.lastInsertRowId;
    }
    model.rowid = lastInsertRowId;
    if(execute == NO)
    {
        NSLog(@"database insert fail %@",NSStringFromClass(modelClass));
    }
    return execute;
}

#pragma mark- update operation
-(BOOL)updateToDB:(NSObject *)model where:(id)where
{
    return [self updateToDB:model where:where db:nil];
}
-(void)updateToDB:(NSObject *)model where:(id)where callback:(void (^)(BOOL))block
{
    [self.bindingQueue inDatabase:^(FMDatabase *db) {
        BOOL result = [self updateToDB:model where:where db:db];
        if(block != nil)
        {
            block(result);
        }
    }];
}
-(BOOL)updateToDB:(NSObject *)model where:(id)where db:(FMDatabase*)db
{
    Class modelClass = model.class;
    NSDictionary* dic  = [modelClass getPropertys];
    NSArray* pronames = [dic objectForKey:@"name"];
    NSArray* protypes = [dic objectForKey:@"type"];
    
    NSMutableString* updateKey = [NSMutableString stringWithCapacity:0];
    NSMutableArray* updateValues = [NSMutableArray arrayWithCapacity:pronames.count];
    for (int i=0; i<pronames.count; i++) {
        
        NSString* columeName = [pronames objectAtIndex:i];
        NSString* columeType = [protypes objectAtIndex:i];
        
        [updateKey appendFormat:@" %@=?,", columeName];
        
        id value = [model modelGetValueWithKey:columeName type:columeType];
        if(value == nil)
        {
            value = @"";
        }
        [updateValues addObject:value];
    }
    [updateKey deleteCharactersInRange:NSMakeRange(updateKey.length - 1, 1)];
    
    NSMutableString* updateSQL = [NSMutableString stringWithFormat:@"update %@ set %@ where  ",[modelClass getTableName],updateKey];
    
    //添加where 语句
    if([where isKindOfClass:[NSString class]] && [LKDBUtils checkStringIsEmpty:where]== NO)
    {
        [updateSQL appendString:where];
    }
    else if([where isKindOfClass:[NSDictionary class]] && [where count]>0)
    {
        NSMutableArray* valuearray = [NSMutableArray array];
        NSString* sqlwhere = [self dictionaryToSqlWhere:where andValues:valuearray];
        
        [updateSQL appendString:sqlwhere];
        [updateValues addObjectsFromArray:valuearray];
    }
    else if(model.rowid > 0)
    {
        [updateSQL appendFormat:@"rowid=%d",model.rowid];
    }
    else
    {
        //如果不通过 rowid 来 更新数据  那 primarykey 一定要有值
        NSString* primaryKey = [modelClass  getPrimaryKey];
        if([LKDBUtils checkStringIsEmpty:primaryKey])
        {
            return NO;
        }
        [updateSQL appendFormat:@"%@=?",primaryKey];
        id value = [model modelGetValueWithKey:primaryKey type:nil];
        if(value == nil)
        {
            value = @"";
        }
        [updateValues addObject:value];
    }
    __block BOOL execute = NO;
    if(db == nil)
    {
        [self executeDB:^(FMDatabase *db) {
            execute = [db executeUpdate:updateSQL withArgumentsInArray:updateValues];
        }];
    }
    else
    {
        execute = [db executeUpdate:updateSQL withArgumentsInArray:updateValues];
    }
    if(execute == NO)
    {
        NSLog(@"database update fail %@   ----->rowid: %d",NSStringFromClass(modelClass),model.rowid);
    }
    return execute;
}
#pragma mark - delete operation
-(BOOL)deleteToDB:(NSObject *)model
{
    __block BOOL isDeleted = NO;
    [self executeDB:^(FMDatabase *db) {
        isDeleted = [self deleteToDB:model db:db];
    }];
    return isDeleted;
}
-(void)deleteToDB:(NSObject *)model callback:(void (^)(BOOL))block
{
    [self.bindingQueue inDatabase:^(FMDatabase *db) {
        BOOL isDeleted = [self deleteToDB:model db:db];
        if(block != nil)
        {
            block(isDeleted);
        }
    }];
}
-(BOOL)deleteToDB:(NSObject *)model db:(FMDatabase*)db
{
    BOOL result = NO;
    Class modelClass = model.class;
    if(model.rowid > 0)
    {
        NSString*  delete = [NSString stringWithFormat:@"delete from %@ where rowid=%d",[modelClass getTableName],model.rowid];
        result = [db executeUpdate:delete];
    }
    else
    {
        NSString* primarykey = [modelClass  getPrimaryKey];
        if ([LKDBUtils checkStringIsEmpty:primarykey]) {
            NSLog(@"delete model fail . %@ primary key is nil",NSStringFromClass(modelClass));
            return NO;
        }
        NSString* delete = [NSString stringWithFormat:@"delete from %@ where %@=?",[modelClass getTableName],primarykey];
        id value = [model modelGetValueWithKey:primarykey type:nil];
        if(value == nil)
        {
            value = @"";
        }
        result = [db executeUpdate:delete withArgumentsInArray:[NSArray arrayWithObject:value]];
    }
    return result;
}

-(BOOL)deleteWithClass:(Class)modelClass where:(id)where
{
    __block BOOL isDeleted = NO;
    [self executeDB:^(FMDatabase *db) {
        isDeleted = [self deleteWithClass:modelClass where:where db:db];
    }];
    return isDeleted;
}
-(void)deleteWithClass:(Class)modelClass where:(id)where callback:(void (^)(BOOL))block
{
    [self.bindingQueue inDatabase:^(FMDatabase *db) {
        BOOL isDeleted = [self deleteWithClass:modelClass where:where db:db];
        if (block != nil) {
            block(isDeleted);
        }
    }];
}
-(BOOL)deleteWithClass:(Class)modelClass where:(id)where db:(FMDatabase*)db
{
    BOOL result = NO;
    if([where isKindOfClass:[NSString class]] && [LKDBUtils checkStringIsEmpty:where] == NO)
    {
        NSString*  delete = [NSString stringWithFormat:@"delete from %@ where %@",[modelClass getTableName],where];
        result = [db executeUpdate:delete];
    }
    else if([where isKindOfClass:[NSDictionary class]] && [where count] > 0)
    {
        NSMutableArray* values = [NSMutableArray arrayWithCapacity:6];
        NSString* wherekey = [self dictionaryToSqlWhere:where andValues:values];
        NSString* delete = [NSString stringWithFormat:@"delete from %@ where %@",[modelClass getTableName],wherekey];
        result = [db executeUpdate:delete withArgumentsInArray:values];
    }
    return result;
}
#pragma mark - other operation

-(BOOL)isExistsModel:(NSObject *)model
{
    Class modelClass = model.class;
    NSString* primaryKey = [modelClass getPrimaryKey];
    NSString* where = [NSString stringWithFormat:@"%@ = '%@'",primaryKey,[model modelGetValueWithKey:primaryKey type:nil]];
    
    __block BOOL isExists = NO;
    [self executeDB:^(FMDatabase *db) {
        isExists = [self isExistsClass:modelClass where:where db:db];
    }];
    return isExists;
}
-(BOOL)isExistsClass:(Class)modelClass where:(id)where
{
    __block BOOL isExists = NO;
    [self executeDB:^(FMDatabase *db) {
       isExists = [self isExistsClass:modelClass where:where db:db];
    }];
    return isExists;
}
-(BOOL)isExistsClass:(Class)modelClass where:(id)where db:(FMDatabase*)db
{
    BOOL exists = NO;
    if([where isKindOfClass:[NSString class]] && [LKDBUtils checkStringIsEmpty:where] == NO)
    {
        NSString* rowCountSql = [NSString stringWithFormat:@"select count(rowid) from %@ where %@",[modelClass getTableName],where];
        FMResultSet* resultSet = [db executeQuery:rowCountSql];
        [resultSet next];
        if([resultSet intForColumnIndex:0]>0)
        {
            exists = YES;
        }
        [resultSet close];
    }
    else if([where isKindOfClass:[NSDictionary class]] && [where count] > 0)
    {
        NSMutableArray* values = [NSMutableArray arrayWithCapacity:6];
        NSString* wherekey = [self dictionaryToSqlWhere:where andValues:values];
        NSString* rowCountSql = [NSString stringWithFormat:@"select count(rowid) from %@ where %@",[modelClass getTableName],wherekey];
        
        FMResultSet* resultSet = [db executeQuery:rowCountSql withArgumentsInArray:values];
        [resultSet next];
        if([resultSet intForColumnIndex:0]>0)
        {
            exists = YES;
        }
        [resultSet close];
    }
    return exists;
}

#pragma mark- clear operation

-(void)clearTableData:(Class)modelClass
{
    [self.bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSString* delete = [NSString stringWithFormat:@"DELETE FROM %@",[modelClass getTableName]];
         [db executeUpdate:delete];
     }];
}

-(void)clearNoneData:(Class)modelClass columes:(NSArray *)columes
{
    [self clearFileWithTable:[modelClass getTableName] columes:columes dir:[modelClass getDBDataDir]];
}
-(void)clearNoneImage:(Class)modelClass columes:(NSArray *)columes
{
    [self clearFileWithTable:[modelClass getTableName]  columes:columes dir:[modelClass getDBImageDir]];
}

-(void)clearFileWithTable:(NSString*)tableName columes:(NSArray*)columes dir:(NSString*)relativeDIR
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        int count =  columes.count;
        NSString* dir =  [LKDBUtils getDirectoryForDocuments:relativeDIR];
        //获取该目录下所有文件名
        NSArray* files = [LKDBUtils getFilenamesWithDir:dir];
        
        NSString* seleteColume = [columes componentsJoinedByString:@","];
        NSMutableString* whereStr =[NSMutableString string];
        for (int i=0; i<count ; i++) {
            [whereStr appendFormat:@" %@ != '' ",[columes objectAtIndex:i]];
            if(i< count -1)
            {
                [whereStr appendString:@" or "];
            }
        }
        NSString* querySql = [NSString stringWithFormat:@"select %@ from %@ where %@",seleteColume,tableName,whereStr];
        __block NSArray* dbfiles;
        [[LKDBHelper sharedDBHelper] executeDB:^(FMDatabase *db) {
            
            NSMutableArray* tempfiles = [NSMutableArray arrayWithCapacity:6];
            FMResultSet* set = [db executeQuery:querySql];
            while ([set next]) {
                for (int j=0; j<count; j++) {
                    NSString* str = [set stringForColumnIndex:j];
                    if([LKDBUtils checkStringIsEmpty:str] ==NO)
                    {
                        [tempfiles addObject:str];
                    }
                }
            }
            [set close];
            dbfiles = tempfiles;
        }];
        
        //遍历  当不再数据库记录中 就删除
        for (NSString* deletefile in files) {
            if([dbfiles indexOfObject:deletefile] == NSNotFound)
            {
                [LKDBUtils deleteWithFilepath:[dir stringByAppendingPathComponent:deletefile]];
            }
        }
    });
}
@end

