//
//  LKDBHelper.m
//  upin
//
//  Created by Fanhuan on 12-12-6.
//  Copyright (c) 2012年 linggan. All rights reserved.
//

#import "LKDBHelper.h"

@interface LKDBHelper()
@property(weak,nonatomic)FMDatabase* usingdb;
@property(strong,nonatomic)FMDatabaseQueue* bindingQueue;
@property(copy,nonatomic)NSString* dbname;
@property(strong,nonatomic)NSMutableDictionary* tableManager;
@property(strong,nonatomic)NSRecursiveLock* threadLock;
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
- (id)init
{
    self = [super init];
    if (self) {
        [self setDBName:@"LKDB"];
        self.threadLock = [[NSRecursiveLock alloc]init];
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
-(void)executeDB:(void (^)(FMDatabase *db))block
{
    [_threadLock lock];
    if(self.usingdb != nil)
    {
        block(self.usingdb);
    }
    else
    {
        [_bindingQueue inDatabase:^(FMDatabase *db) {
            self.usingdb = db;
            block(db);
            self.usingdb = nil;
        }];
    }
    [_threadLock unlock];
}

//splice 'where' 拼接where语句
- (NSMutableArray *)extractQuery:(NSMutableString *)query where:(id)where
{
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
    return values;
}
//dic where parse
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
    return _tableManager;
}
-(void)dealloc
{
    [self.bindingQueue close];
}
@end
@implementation LKDBHelper(DatabaseManager)

const __strong static NSString* normaltypestring = @"floatdoubledecimal";
const __strong static NSString* inttypesstring = @"intcharshortlong";
const __strong static NSString* blobtypestring = @"NSDataUIImage";
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
-(void)dropAllTable
{
    [self executeDB:^(FMDatabase *db) {
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
    [self.tableManager removeAllObjects];
}
-(void)dropTableWithClass:(Class)modelClass
{
    [self executeDB:^(FMDatabase *db) {
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
    int version = [[_tableManager objectForKey:tableName] intValue];
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
    [self executeDB:^(FMDatabase *db) {
        BOOL isCreated = [db executeUpdate:createTable];
        if(isCreated)
        {
            [modelClass dbDidCreateTable:self];
            [_tableManager setObject:tableName forKey:[NSNumber numberWithInt:newVersion]];
            
            NSString* replaceSQL = [NSString stringWithFormat:@"replace into LKTableManager(table_name,version) values('%@',%d)",tableName,newVersion];
            [db executeUpdate:replaceSQL];
        }
    }];
}

@end
@implementation LKDBHelper(DatabaseExecute)

-(void)asyncBlock:(void(^)(void))block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),block);
}
#pragma mark - row count operation
-(int)rowCount:(Class)modelClass where:(id)where
{
    return [self rowCountBase:modelClass where:where];
}
-(void)rowCount:(Class)modelClass where:(id)where callback:(void (^)(int))callback
{
    [self asyncBlock:^{
        int result = [self rowCountBase:modelClass where:where];
        if(callback != nil)
        {
            callback(result);
        }
    }];
}
-(int)rowCountBase:(Class)modelClass where:(id)where
{
    NSMutableString* rowCountSql = [NSMutableString stringWithFormat:@"select count(rowid) from %@ ",[modelClass getTableName]];
    
    NSMutableArray* valuesarray = [self extractQuery:rowCountSql where:where];
    
    __block int result = 0;
    [self executeDB:^(FMDatabase *db) {
        FMResultSet* resultSet = nil;
        if(valuesarray == nil)
        {
            resultSet = [db executeQuery:rowCountSql];
        }
        else
        {
            resultSet = [db executeQuery:rowCountSql withArgumentsInArray:valuesarray];
        }
        if([resultSet next])
        {
            result =  [resultSet intForColumnIndex:0];
        }
        [resultSet close];
    }];
    return result;
}
#pragma mark- search operation
-(NSMutableArray *)search:(Class)modelClass where:(id)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count
{
    return [self searchBase:modelClass where:where orderBy:orderBy offset:offset count:count];
}
-(void)search:(Class)modelClass where:(id)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count callback:(void (^)(NSMutableArray *))block
{
    [self asyncBlock:^{
        NSMutableArray* array = [self searchBase:modelClass where:where orderBy:orderBy offset:offset count:count];
        if(block != nil)
        {
            block(array);
        }
    }];
}
-(NSMutableArray *)searchBase:(Class)modelClass where:(id)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count
{
    NSMutableString* query = [NSMutableString stringWithFormat:@"select rowid,* from %@ ",[modelClass getTableName]];
    NSMutableArray * values = [self extractQuery:query where:where];
    
    [self sqlString:query AddOder:orderBy offset:offset count:count];
    
    __block NSMutableArray* results = nil;
    [self executeDB:^(FMDatabase *db) {
        FMResultSet* set = nil;
        if(values == nil)
        {
            set = [db executeQuery:query];
        }
        else
        {
            set = [db executeQuery:query withArgumentsInArray:values];
        }
        results = [self executeResult:set Class:modelClass];
    }];
    return results;
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
                value = [NSNumber numberWithFloat:[set doubleForColumn:columeName]];
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
    return [self insertBase:model];
}
-(void)insertToDB:(NSObject *)model callback:(void (^)(BOOL))block
{
    [self asyncBlock:^{
        BOOL result = [self insertBase:model];
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
    [self asyncBlock:^{
        if(block != nil)
        {
            block([self insertWhenNotExists:model]);
        }
        else
        {
            [self insertWhenNotExists:model];
        }
    }];
}
-(BOOL)insertBase:(NSObject*)model{
    
    Class modelClass = model.class;
    if(model == nil || [LKDBUtils checkStringIsEmpty:[modelClass getTableName]])
    {
        NSLog(@"LKDBHelper Insert Fail 。。 Model = nil or  not has Table Name");
        return NO;
    }
    
    //callback
    [modelClass dbWillInsert:model];
    
    //--
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
    
    [self executeDB:^(FMDatabase *db) {
        execute = [db executeUpdate:insertSQL withArgumentsInArray:insertValues];
        lastInsertRowId= db.lastInsertRowId;
    }];
    
    model.rowid = lastInsertRowId;
    if(execute == NO)
    {
        NSLog(@"database insert fail %@, sql:%@",NSStringFromClass(modelClass),insertSQL);
    }
    
    //callback
    [modelClass dbDidInserted:model result:execute];
    return execute;
}

#pragma mark- update operation
-(BOOL)updateToDB:(NSObject *)model where:(id)where
{
    return [self updateToDBBase:model where:where];
}
-(void)updateToDB:(NSObject *)model where:(id)where callback:(void (^)(BOOL))block
{
    [self asyncBlock:^{
        BOOL result = [self updateToDBBase:model where:where];
        if(block != nil)
        {
            block(result);
        }
    }];
}
-(BOOL)updateToDBBase:(NSObject *)model where:(id)where
{
    Class modelClass = model.class;
    if(model == nil || [LKDBUtils checkStringIsEmpty:[modelClass getTableName]])
    {
        NSLog(@"LKDBHelper Update Fail 。。 model = nil or  not has Table Name");
        return false;
    }
    //callback
    [modelClass dbWillUpdate:model];
    
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
    
    NSMutableString* updateSQL = [NSMutableString stringWithFormat:@"update %@ set %@ where ",[modelClass getTableName],updateKey];
    
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
        int index = [pronames indexOfObject:primaryKey];
        if(index == NSNotFound)
        {
            return NO;
        }
        NSString* primaryValue = [protypes objectAtIndex:index];
        [updateSQL appendFormat:@"%@=?",primaryKey];
        id value = [model modelGetValueWithKey:primaryKey type:primaryValue];
        if(value == nil)
        {
            value = @"";
        }
        [updateValues addObject:value];
    }
    __block BOOL execute = NO;
    [self executeDB:^(FMDatabase *db) {
        execute = [db executeUpdate:updateSQL withArgumentsInArray:updateValues];
    }];
    if(execute == NO)
    {
        NSLog(@"database update fail %@   ----->rowid: %d",NSStringFromClass(modelClass),model.rowid);
    }
    //callback
    [modelClass dbDidUpdated:model result:execute];
    
    return execute;
}

//table update
-(BOOL)updateToDB:(Class)modelClass set:(NSString *)sets where:(id)where
{
    if([LKDBUtils checkStringIsEmpty:[modelClass getTableName]])
    {
        NSLog(@"LKDBHelper Update Fail 。。not has Table Name");
        return NO;
    }
    if([LKDBUtils checkStringIsEmpty:sets])
    {
        NSLog(@"LKDBHelper Update Fail 。。no set statement 没set语句");
        return NO;
    }
    NSMutableString* updateSQL = [NSMutableString stringWithFormat:@"update %@ set %@ ",[modelClass getTableName],sets];
    NSMutableArray* updateValues = [self extractQuery:updateSQL where:where];
    __block BOOL execute = NO;
    [self executeDB:^(FMDatabase *db) {
        if(updateValues.count>0)
        {
            execute = [db executeUpdate:updateSQL withArgumentsInArray:updateValues];
        }
        else
        {
            execute = [db executeUpdate:updateSQL];
        }
    }];
    if(execute == NO)
    {
        NSLog(@"database update fail %@   ----->sql:%@",NSStringFromClass(modelClass),updateSQL);
    }
    //callback
    [modelClass dbDidUpdated:nil result:execute];
    
    return execute;
}
#pragma mark - delete operation
-(BOOL)deleteToDB:(NSObject *)model
{
    return [self deleteToDBBase:model];
}
-(void)deleteToDB:(NSObject *)model callback:(void (^)(BOOL))block
{
    [self asyncBlock:^{
        BOOL isDeleted = [self deleteToDBBase:model];
        if(block != nil)
        {
            block(isDeleted);
        }
    }];
}
-(BOOL)deleteToDBBase:(NSObject *)model
{
    Class modelClass = model.class;
    if(model == nil || [LKDBUtils checkStringIsEmpty:[modelClass getTableName]])
    {
        NSLog(@"LKDBHelper Delete Fail 。。 model = nil or  not has Table Name");
        return NO;
    }
    
    //callback
    [modelClass dbWillDelete:model];
    
    NSMutableString*  deleteSQL =[NSMutableString stringWithFormat:@"delete from %@ where ",[modelClass getTableName]];
    id primaryValue = nil;
    if(model.rowid > 0)
    {
        [deleteSQL appendFormat:@" rowid = %d",model.rowid];
    }
    else
    {
        primaryValue = [model getPrimaryValue];
        if(primaryValue)
        {
            NSString* primarykey = [modelClass  getPrimaryKey];
            [deleteSQL appendFormat:@" %@=? ",primarykey];
        }
        else
        {
            NSLog(@"delete fail : %@ primary value is nil",NSStringFromClass(modelClass));
            return NO;
        }
    }
    __block BOOL result = NO;
    [self executeDB:^(FMDatabase *db) {
        if(primaryValue)
        {
            result = [db executeUpdate:deleteSQL withArgumentsInArray:@[primaryValue]];
        }
        else
        {
            result = [db executeUpdate:deleteSQL];
        }
    }];
    
    //callback
    [modelClass dbDidIDeleted:model result:result];
    
    return result;
}

-(BOOL)deleteWithClass:(Class)modelClass where:(id)where
{
    return [self deleteWithClassBase:modelClass where:where];
}
-(void)deleteWithClass:(Class)modelClass where:(id)where callback:(void (^)(BOOL))block
{
    [self asyncBlock:^{
        BOOL isDeleted = [self deleteWithClassBase:modelClass where:where];
        if (block != nil) {
            block(isDeleted);
        }
    }];
}
-(BOOL)deleteWithClassBase:(Class)modelClass where:(id)where
{
    __block BOOL result = NO;
    NSMutableString* deleteSQL = [NSMutableString stringWithFormat:@"delete from %@",[modelClass getTableName]];
    NSMutableArray* values = [self extractQuery:deleteSQL where:where];
    [self executeDB:^(FMDatabase *db) {
        if(values.count>0)
        {
            result = [db executeUpdate:deleteSQL withArgumentsInArray:values];
        }
        else
        {
            result = [db executeUpdate:deleteSQL];
        }
    }];
    return result;
}
#pragma mark - other operation
-(BOOL)isExistsModel:(NSObject *)model
{
    Class modelClass = model.class;
    NSString* primarykey = [modelClass getPrimaryKey];
    id primaryValue = [model getPrimaryValue];
    if(primarykey&&primaryValue)
    {
        NSString* where = [NSString stringWithFormat:@"%@ = '%@'",primarykey,primaryValue];
        return [self isExistsClass:modelClass where:where];
    }
    else
    {
        NSLog(@"exists model fail: primary key is nil or invalid");
        return NO;
    }
}
-(BOOL)isExistsClass:(Class)modelClass where:(id)where
{
    return [self isExistsClassBase:modelClass where:where];
}
-(BOOL)isExistsClassBase:(Class)modelClass where:(id)where
{
    int rowcount = [self rowCountBase:modelClass where:where];
    if(rowcount > 0)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark- clear operation

-(void)clearTableData:(Class)modelClass
{
    [self executeDB:^(FMDatabase *db) {
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
        [self executeDB:^(FMDatabase *db) {
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



@implementation NSObject(LKDBHelper)

+(void)dbDidCreateTable:(LKDBHelper *)helper{}

+(void)dbDidIDeleted:(NSObject *)entity result:(BOOL)result{}
+(void)dbWillDelete:(NSObject *)entity{}

+(void)dbDidInserted:(NSObject *)entity result:(BOOL)result{}
+(void)dbWillInsert:(NSObject *)entity{}

+(void)dbDidUpdated:(NSObject *)entity result:(BOOL)result{}
+(void)dbWillUpdate:(NSObject *)entity{}

#pragma mark - simplify synchronous function
+(BOOL)checkModelClass:(NSObject*)model
{
    if([model isKindOfClass:self])
    {
        return YES;
    }
    else
    {
        NSLog(@"%@ can not use %@",NSStringFromClass(self),NSStringFromClass(model.class));
        return NO;
    }
}

+(int)rowCountWithWhere:(id)where{
    return [[LKDBHelper sharedDBHelper] rowCount:self where:where];
}

+(NSMutableArray*)searchWithWhere:(id)where orderBy:(NSString*)orderBy offset:(int)offset count:(int)count{
    return [[LKDBHelper sharedDBHelper] search:self where:where orderBy:orderBy offset:offset count:count];
}

+(BOOL)insertToDB:(NSObject*)model{
    
    if([self checkModelClass:model])
    {
        return [[LKDBHelper sharedDBHelper] insertToDB:model];
    }
    return NO;
    
}
+(BOOL)insertWhenNotExists:(NSObject*)model{
    if([self checkModelClass:model])
    {
        return [[LKDBHelper sharedDBHelper] insertWhenNotExists:model];
    }
    return NO;
}
+(BOOL)updateToDB:(NSObject *)model where:(id)where{
    if([self checkModelClass:model])
    {
        return [[LKDBHelper sharedDBHelper] updateToDB:model where:where];
    }
    return NO;
}
+(BOOL)updateToDBWithSet:(NSString *)sets where:(id)where
{
    return [[LKDBHelper sharedDBHelper] updateToDB:self set:sets where:where];
}
+(BOOL)deleteToDB:(NSObject*)model{
    if([self checkModelClass:model])
    {
        return [[LKDBHelper sharedDBHelper] deleteToDB:model];
    }
    return NO;
}
+(BOOL)deleteWithWhere:(id)where{
    return [[LKDBHelper sharedDBHelper] deleteWithClass:self where:where];
}
@end