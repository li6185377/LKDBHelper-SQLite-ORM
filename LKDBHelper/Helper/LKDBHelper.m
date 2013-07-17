//
//  LKDBHelper.m
//  upin
//
//  Created by Fanhuan on 12-12-6.
//  Copyright (c) 2012年 linggan. All rights reserved.
//


#import "LKDBHelper.h"

#define checkClassIsInvalid(modelClass)if([LKDBUtils checkStringIsEmpty:[modelClass getTableName]]){\
LKLog(@"model class name %@ table name is invalid!",NSStringFromClass(modelClass));\
return NO;}

#define checkModelIsInvalid(model)if(model == nil){LKLog(@"model is nil");return NO;}checkClassIsInvalid(model.class)

@interface LKDBHelper()
@property(unsafe_unretained,nonatomic)FMDatabase* usingdb;
@property(strong,nonatomic)FMDatabaseQueue* bindingQueue;
@property(copy,nonatomic)NSString* dbname;

@property(strong,nonatomic)NSRecursiveLock* threadLock;
@property(strong,nonatomic)LKTableManager* tableManager;
@end

@implementation LKDBHelper

-(id)initWithDBName:(NSString *)dbname
{
    self = [super init];
    if (self) {
        self.threadLock = [[NSRecursiveLock alloc]init];
        [self setDBName:dbname];
    }
    return self;
}
- (id)init
{
    return [self initWithDBName:@"LKDB"];
}
-(void)setDBName:(NSString *)fileName
{
    if([self.dbname isEqualToString:fileName] == NO)
    {
        if([fileName hasSuffix:@".db"] == NO)
        {
            self.dbname = [NSString stringWithFormat:@"%@.db",fileName];
        }
        else
        {
            self.dbname = fileName;
        }
        [self.bindingQueue close];
        self.bindingQueue = [[FMDatabaseQueue alloc]initWithPath:[LKDBUtils getPathForDocuments:self.dbname inDir:@"db"]];
        
#ifdef DEBUG
        //debug 模式下  打印错误日志
        [_bindingQueue inDatabase:^(FMDatabase *db) {
            db.logsErrors = YES;
        }];
#endif
        self.tableManager = [[LKTableManager alloc]initWithLKDBHelper:self];
    }
}

#pragma mark- core
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
-(BOOL)executeSQL:(NSString *)sql arguments:(NSArray *)args
{
    __block BOOL execute = NO;
    [self executeDB:^(FMDatabase *db) {
        if(args.count>0)
            execute = [db executeUpdate:sql withArgumentsInArray:args];
        else
            execute = [db executeUpdate:sql];
    }];
    return execute;
}
-(NSString *)executeScalarWithSQL:(NSString *)sql arguments:(NSArray *)args
{
    __block NSString* scalar = nil;
    [self executeDB:^(FMDatabase *db) {
        FMResultSet* set = nil;
        if(args.count>0)
            set = [db executeQuery:sql withArgumentsInArray:args];
        else
            set = [db executeQuery:sql];
        
        if([set columnCount]>0 && [set next])
        {
            scalar = [set stringForColumnIndex:0];
        }
        [set close];
    }];
    return scalar;
}


//splice 'where' 拼接where语句
- (NSMutableArray *)extractQuery:(NSMutableString *)query where:(id)where
{
    NSMutableArray* values = nil;
    if([where isKindOfClass:[NSString class]] && [LKDBUtils checkStringIsEmpty:where]==NO)
    {
        [query appendFormat:@" where %@",where];
    }
    else if ([where isKindOfClass:[NSDictionary class]] && [where count] > 0)
    {
        values = [NSMutableArray arrayWithCapacity:[where count]];
        NSString* wherekey = [self dictionaryToSqlWhere:where andValues:values];
        [query appendFormat:@" where %@",wherekey];
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
                NSArray* vlist = va;
                if(vlist.count==0)
                    continue;
                
                if(wherekey.length > 0)
                    [wherekey appendString:@" and"];
                
                [wherekey appendFormat:@" %@ in(",key];
                
                for (int j=0; j<vlist.count; j++) {
                    
                    [wherekey appendString:@"?"];
                    if(j== vlist.count-1)
                        [wherekey appendString:@")"];
                    else
                        [wherekey appendString:@","];
                    
                    [values addObject:[vlist objectAtIndex:j]];
                }
            }
            else
            {
                if(wherekey.length > 0)
                    [wherekey appendFormat:@" and %@=?",key];
                else
                    [wherekey appendFormat:@" %@=?",key];
                
                [values addObject:va];
            }
            
        }
    }
    return wherekey;
}

#pragma mark- dealloc
-(void)dealloc
{
    [self.bindingQueue close];
    self.usingdb = nil;
    self.bindingQueue = nil;
    self.dbname = nil;
    self.tableManager = nil;
    self.threadLock = nil;
}
@end
@implementation LKDBHelper(DatabaseManager)

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
    
    [self.tableManager clearTableInfos];
}
-(BOOL)dropTableWithClass:(Class)modelClass
{
    checkClassIsInvalid(modelClass);
    
    NSString* tableName = [modelClass getTableName];
    NSString* dropTable = [NSString stringWithFormat:@"drop table %@",tableName];
    
    BOOL isDrop = [self executeSQL:dropTable arguments:nil];

    if(isDrop)
        [_tableManager setTableName:tableName version:0];
    
    return isDrop;
}
-(BOOL)createTableWithModelClass:(Class)modelClass
{
    checkClassIsInvalid(modelClass);
    NSString* tableName = [modelClass getTableName];
    
    int oldVersion = [_tableManager versionWithName:tableName];
    int newVersion = [modelClass getTableVersion];
    
    if(oldVersion>0 && oldVersion != newVersion)
    {
        LKTableUpdateType userOperation = [modelClass tableUpdateForOldVersion:oldVersion newVersion:newVersion];
        switch (userOperation) {
            case LKTableUpdateTypeDeleteOld:
            {
                [self dropTableWithClass:modelClass];
            }
                break;
                
            case LKTableUpdateTypeDefault:
                return NO;
                
            case LKTableUpdateTypeCustom:
                [_tableManager setTableName:tableName version:newVersion];
                return YES;
        }
    }
    else if(oldVersion == newVersion)
    {
        //已创建表 就跳过
        return YES;
    }
    
    LKModelInfos* infos = [modelClass getModelInfos];
    NSString* primaryKey = [modelClass getPrimaryKey];
    NSMutableString* table_pars = [NSMutableString string];
    for (int i=0; i<infos.count; i++) {
        
        if(i > 0)
            [table_pars appendString:@","];
        
        LKDBProperty* property =  [infos objectWithIndex:i];
        [modelClass columeAttributeWithProperty:property];
        
        [table_pars appendFormat:@"%@ %@",property.sqlColumeName,property.sqlColumeType];
        
        if([property.sqlColumeType isEqualToString:LKSQLText])
        {
            if(property.length>0)
            {
                [table_pars appendFormat:@"(%d)",property.length];
            }
        }
        if(property.isNotNull)
        {
            [table_pars appendFormat:@" %@",LKSQLNotNull];
        }
        if(property.isUnique)
        {
            [table_pars appendFormat:@" %@",LKSQLUnique];
        }
        if(property.checkValue)
        {
            [table_pars appendFormat:@" %@(%@)",LKSQLCheck,property.checkValue];
        }
        if(property.defaultValue)
        {
            [table_pars appendFormat:@" %@ %@",LKSQLDefault,property.defaultValue];
        }
        if(primaryKey && [property.sqlColumeName isEqualToString:primaryKey])
        {
            [table_pars appendFormat:@" %@",LKSQLPrimaryKey];
        }
    }
    NSString* createTableSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@)",tableName,table_pars];
    
    
    BOOL isCreated = [self executeSQL:createTableSQL arguments:nil];
    
    if(isCreated)
        [_tableManager setTableName:tableName version:newVersion];
    
    return isCreated;
}
@end

@implementation LKDBHelper(DatabaseExecute)

-(id)modelValueWithProperty:(LKDBProperty *)property model:(NSObject *)model {
    id value = nil;
    if(property.isUserCalculate)
    {
        value = [model userGetValueForModel:property];
    }
    else
    {
        value = [model modelGetValue:property];
    }
    if(value == nil)
    {
        value = @"";
    }
    return value;
}
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
    NSMutableString* rowCountSql = [NSMutableString stringWithFormat:@"select count(rowid) from %@",[modelClass getTableName]];
    
    NSMutableArray* valuesarray = [self extractQuery:rowCountSql where:where];
    int result = [[self executeScalarWithSQL:rowCountSql arguments:valuesarray] intValue];

    return result;
}

#pragma mark- search operation
-(NSMutableArray *)search:(Class)modelClass where:(id)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count
{
    return [self searchBase:modelClass where:where orderBy:orderBy offset:offset count:count];
}
-(id)searchSingle:(Class)modelClass where:(id)where orderBy:(NSString *)orderBy
{
    NSMutableArray* array = [self searchBase:modelClass where:where orderBy:orderBy offset:0 count:1];
    
    if(array.count>0)
        return [array objectAtIndex:0];
    
    return nil;
}

-(void)search:(Class)modelClass where:(id)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count callback:(void (^)(NSMutableArray *))block
{
    [self asyncBlock:^{
        NSMutableArray* array = [self searchBase:modelClass where:where orderBy:orderBy offset:offset count:count];

        if(block != nil)
            block(array);
    }];
}

-(NSMutableArray *)searchBase:(Class)modelClass where:(id)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count
{
    NSMutableString* query = [NSMutableString stringWithFormat:@"select rowid,* from %@",[modelClass getTableName]];
    NSMutableArray * values = [self extractQuery:query where:where];
    
    [self sqlString:query AddOder:orderBy offset:offset count:count];
    
    __block NSMutableArray* results = nil;
    [self executeDB:^(FMDatabase *db) {
        FMResultSet* set = nil;
        if(values == nil)
            set = [db executeQuery:query];
        else
            set = [db executeQuery:query withArgumentsInArray:values];
        
        results = [self executeResult:set Class:modelClass];
        [set close];
    }];
    return results;
}
-(void)sqlString:(NSMutableString*)sql AddOder:(NSString*)orderby offset:(int)offset count:(int)count
{
    if([LKDBUtils checkStringIsEmpty:orderby] == NO)
    {
        [sql appendFormat:@" order by %@",orderby];
    }
    [sql appendFormat:@" limit %d offset %d",count,offset];
}
- (NSMutableArray *)executeResult:(FMResultSet *)set Class:(Class)modelClass
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:0];
    LKModelInfos* infos = [modelClass getModelInfos];
    int columeCount = [set columnCount];
    while ([set next]) {
        
        NSObject* bindingModel = [[modelClass alloc]init];
        bindingModel.rowid = [set intForColumnIndex:0];
        
        for (int i=1; i<columeCount; i++) {
            NSString* sqlName = [set columnNameForIndex:i];
            NSString* sqlValue = [set stringForColumnIndex:i];
            
            LKDBProperty* property = [infos objectWithSqlColumeName:sqlName];
            if(property.propertyName && [property.propertyName isEqualToString:LKSQLUserCalculate] ==NO)
            {
                [bindingModel modelSetValue:property value:sqlValue];
            }
            else
            {
                [bindingModel userSetValueForModel:property value:sqlValue];
            }
        }
        [array addObject:bindingModel];
    }
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
    
    checkModelIsInvalid(model);
    
    Class modelClass = model.class;

    //callback
    [modelClass dbWillInsert:model];
    
    //--
    LKModelInfos* infos = [modelClass getModelInfos];
    
    NSMutableString* insertKey = [NSMutableString stringWithCapacity:0];
    NSMutableString* insertValuesString = [NSMutableString stringWithCapacity:0];
    
    NSMutableArray* insertValues = [NSMutableArray arrayWithCapacity:infos.count];
    for (int i=0; i<infos.count; i++) {
        LKDBProperty* property = [infos objectWithIndex:i];
        
        if(i>0)
        {
            [insertKey appendString:@","];
            [insertValuesString appendString:@","];
        }
        
        [insertKey appendString:property.sqlColumeName];
        [insertValuesString appendString:@"?"];
        
        id value = [self modelValueWithProperty:property model:model];
        
        [insertValues addObject:value];
    }
    
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
        LKLog(@"database insert fail %@, sql:%@",NSStringFromClass(modelClass),insertSQL);
    
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
            block(result);
    }];
}
-(BOOL)updateToDBBase:(NSObject *)model where:(id)where
{
    checkModelIsInvalid(model);
    
    Class modelClass = model.class;
    //callback
    [modelClass dbWillUpdate:model];
    
    LKModelInfos* infos = [modelClass getModelInfos];
    
    NSMutableString* updateKey = [NSMutableString string];
    NSMutableArray* updateValues = [NSMutableArray arrayWithCapacity:infos.count];
    for (int i=0; i<infos.count; i++) {
        
        LKDBProperty* property = [infos objectWithIndex:i];
        
        if(i>0)
            [updateKey appendString:@","];
        
        [updateKey appendFormat:@"%@=?",property.sqlColumeName];
        
        id value = [self modelValueWithProperty:property model:model];
        
        [updateValues addObject:value];
    }
    
    NSMutableString* updateSQL = [NSMutableString stringWithFormat:@"update %@ set %@ where",[modelClass getTableName],updateKey];
    
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
        [updateSQL appendFormat:@" rowid=%d",model.rowid];
    }
    else
    {
        //如果不通过 rowid 来 更新数据  那 primarykey 一定要有值
        NSString* primaryKey = [modelClass  getPrimaryKey];
        if([LKDBUtils checkStringIsEmpty:primaryKey] == NO)
        {
            LKDBProperty* property = [infos objectWithSqlColumeName:primaryKey];
            if(property)
            {
                [updateSQL appendFormat:@" %@=?",property.sqlColumeName];
                
                id value = [self modelValueWithProperty:property model:model];
                
                [updateValues addObject:value];
            }
        }
    }
    
    BOOL execute = [self executeSQL:updateSQL arguments:updateValues];
    if(execute == NO)
    {
        LKLog(@"database update fail : %@   -----> update sql: %@",NSStringFromClass(modelClass),updateSQL);
    }
    
    //callback
    [modelClass dbDidUpdated:model result:execute];
    
    return execute;
}
-(BOOL)updateToDB:(Class)modelClass set:(NSString *)sets where:(id)where
{
    checkClassIsInvalid(modelClass);
    
    NSMutableString* updateSQL = [NSMutableString stringWithFormat:@"update %@ set %@ ",[modelClass getTableName],sets];
    NSMutableArray* updateValues = [self extractQuery:updateSQL where:where];
    
    BOOL execute = [self executeSQL:updateSQL arguments:updateValues];

    if(execute == NO)
        LKLog(@"database update fail %@   ----->sql:%@",NSStringFromClass(modelClass),updateSQL);
    
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
            block(isDeleted);
    }];
}

-(BOOL)deleteToDBBase:(NSObject *)model
{
    checkModelIsInvalid(model);
    
    Class modelClass = model.class;
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
            LKLog(@"delete fail : %@ primary value is nil",NSStringFromClass(modelClass));
            return NO;
        }
    }
    
    NSArray* array = nil;
    if(primaryValue)
        array = [NSArray arrayWithObject:primaryValue];
    
    BOOL execute = [self executeSQL:deleteSQL arguments:array];
    
    //callback
    [modelClass dbDidIDeleted:model result:execute];
    
    return execute;
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
    checkClassIsInvalid(modelClass);
    
    NSMutableString* deleteSQL = [NSMutableString stringWithFormat:@"delete from %@",[modelClass getTableName]];
    NSMutableArray* values = [self extractQuery:deleteSQL where:where];

    BOOL result = [self executeSQL:deleteSQL arguments:values];
    return result;
}
#pragma mark - other operation
-(BOOL)isExistsModel:(NSObject *)model
{
    checkModelIsInvalid(model);
    if(model.rowid>0)
        return YES;
    else
    {
        Class modelClass = model.class;
        
        NSString* primarykey = [modelClass getPrimaryKey];
        id primaryValue = [model getPrimaryValue];

        if(primarykey&&primaryValue)
        {
            NSString* where = [NSString stringWithFormat:@"%@ = '%@'",primarykey,primaryValue];
            return [self isExistsClass:modelClass where:where];
        }
        
        LKLog(@"exists model fail: primary key is nil or invalid");
        return NO;
    }
}
-(BOOL)isExistsClass:(Class)modelClass where:(id)where
{
    return [self isExistsClassBase:modelClass where:where];
}
-(BOOL)isExistsClassBase:(Class)modelClass where:(id)where
{
    return [self rowCount:modelClass where:where] > 0;
}

#pragma mark- clear operation

+(void)clearTableData:(Class)modelClass
{
    [[modelClass getUsingLKDBHelper] executeDB:^(FMDatabase *db) {
        NSString* delete = [NSString stringWithFormat:@"DELETE FROM %@",[modelClass getTableName]];
        [db executeUpdate:delete];
    }];
}

+(void)clearNoneImage:(Class)modelClass columes:(NSArray *)columes
{
    [self clearFileWithTable:modelClass columes:columes type:1];
}
+(void)clearNoneData:(Class)modelClass columes:(NSArray *)columes
{
    [self clearFileWithTable:modelClass columes:columes type:2];
}
#define LKTestDirFilename @"LKTestDirFilename111"
+(void)clearFileWithTable:(Class)modelClass columes:(NSArray*)columes type:(int)type
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        NSString* testpath = nil;
        switch (type) {
            case 1:
                testpath = [modelClass getDBImagePathWithName:LKTestDirFilename];
                break;
            case 2:
                testpath = [modelClass getDBDataPathWithName:LKTestDirFilename];
                break;
        }
        
        if([LKDBUtils checkStringIsEmpty:testpath])
            return ;
        
        NSString* dir  = [testpath stringByReplacingOccurrencesOfString:LKTestDirFilename withString:@""];
        
        int count =  columes.count;
        
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
        NSString* querySql = [NSString stringWithFormat:@"select %@ from %@ where %@",seleteColume,[modelClass getTableName],whereStr];
        __block NSArray* dbfiles;
        [[modelClass getUsingLKDBHelper] executeDB:^(FMDatabase *db) {
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


