//
//  LKDBHelper.m
//  upin
//
//  Created by Fanhuan on 12-12-6.
//  Copyright (c) 2012年 linggan. All rights reserved.
//


#import "LKDBHelper.h"

#define checkClassIsInvalid(modelClass)if([LKDBUtils checkStringIsEmpty:[modelClass getTableName]]){\
LKErrorLog(@"model class name %@ table name is invalid!",NSStringFromClass(modelClass));\
return NO;}

#define checkModelIsInvalid(model)if(model == nil){LKErrorLog(@"model is nil");return NO;}checkClassIsInvalid(model.class)

@interface LKDBHelper()
@property(unsafe_unretained,nonatomic)FMDatabase* usingdb;
@property(strong,nonatomic)FMDatabaseQueue* bindingQueue;
@property(copy,nonatomic)NSString* dbPath;

@property(strong,nonatomic)NSRecursiveLock* threadLock;
@property(strong,nonatomic)LKTableManager* tableManager;
@end

@implementation LKDBHelper

#pragma mark- deprecated
+(LKDBHelper *)sharedDBHelper
{return [LKDBHelper getUsingLKDBHelper];}
#pragma mark-

-(instancetype)initWithDBName:(NSString *)dbname
{
    self = [super init];
    if (self) {
        self.threadLock = [[NSRecursiveLock alloc]init];
        [self setDBName:dbname];
    }
    return self;
}
-(instancetype)initWithDBPath:(NSString *)filePath
{
    self = [super init];
    if (self) {
        self.threadLock = [[NSRecursiveLock alloc]init];
        [self setDBPath:filePath];
    }
    return self;
}
- (instancetype)init
{
    return [self initWithDBName:@"LKDB"];
}

-(void)setDBName:(NSString *)fileName
{
    NSString* dbname = nil;
    if([fileName hasSuffix:@".db"] == NO){
        dbname = [NSString stringWithFormat:@"%@.db",fileName];
    }
    else{
        dbname = fileName;
    }
    
    NSString* filePath = [LKDBUtils getPathForDocuments:dbname inDir:@"db"];
    [self setDBPath:filePath];
}

-(void)setDBPath:(NSString *)filePath
{
    if(self.bindingQueue && [self.dbPath isEqualToString:[filePath lowercaseString]])
    {
        return;
    }
    
    NSRange lastComponent = [filePath rangeOfString:@"/" options:NSBackwardsSearch];
    if(lastComponent.length > 0){
        NSString* dirPath = [filePath substringToIndex:lastComponent.location];
        BOOL isDir = NO;
        BOOL isCreated = [[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir];
        if ( isCreated == NO || isDir == NO ) {
            NSError* error = nil;
            BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
            if(success == NO)
                NSLog(@"create dir error: %@",error.debugDescription);
        }
    }
    self.dbPath = filePath;
    [self.bindingQueue close];
    self.bindingQueue = [[FMDatabaseQueue alloc]initWithPath:self.dbPath];
    
#ifdef DEBUG
    //debug 模式下  打印错误日志
    [_bindingQueue inDatabase:^(FMDatabase *db) {
        db.logsErrors = YES;
    }];
#endif
    self.tableManager = [[LKTableManager alloc]initWithLKDBHelper:self];
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
    else if ([where isKindOfClass:[NSDictionary class]])
    {
        NSDictionary* dicWhere = where;
        if(dicWhere.count > 0)
        {
            values = [NSMutableArray arrayWithCapacity:dicWhere.count];
            NSString* wherekey = [self dictionaryToSqlWhere:where andValues:values];
            [query appendFormat:@" where %@",wherekey];
        }
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
//where sql statements about model primary keys
-(NSMutableString*)primaryKeyWhereSQLWithModel:(NSObject*)model addPValues:(NSMutableArray*)addPValues
{
    LKModelInfos* infos = [model.class getModelInfos];
    NSArray* primaryKeys = infos.primaryKeys;
    NSMutableString* pwhere = [NSMutableString string];
    if(primaryKeys.count>0)
    {
        for (int i=0; i<primaryKeys.count; i++) {
            NSString* pk = [primaryKeys objectAtIndex:i];
            if([LKDBUtils checkStringIsEmpty:pk] == NO)
            {
                LKDBProperty* property = [infos objectWithSqlColumnName:pk];
                id pvalue = nil;
                if(property && [property.type isEqualToString:LKSQL_Mapping_UserCalculate])
                {
                    pvalue = [model userGetValueForModel:property];
                }
                else if(pk && property)
                {
                    pvalue = [model modelGetValue:property];
                }
                
                if(pvalue)
                {
                    if(pwhere.length>0)
                        [pwhere appendString:@"and"];
                    
                    if(addPValues)
                    {
                        [pwhere appendFormat:@" %@=? ",pk];
                        [addPValues addObject:pvalue];
                    }
                    else
                    {
                        [pwhere appendFormat:@" %@='%@' ",pk,pvalue];
                    }
                }
            }
        }
    }
    return pwhere;
}
#pragma mark- dealloc
-(void)dealloc
{
    [self.bindingQueue close];
    self.usingdb = nil;
    self.bindingQueue = nil;
    self.dbPath = nil;
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
-(void)fixSqlColumnsWithClass:(Class)clazz
{
    NSString* tableName = [clazz getTableName];
    LKModelInfos* infos = [clazz getModelInfos];
    [self executeDB:^(FMDatabase *db) {
        NSString* select = [NSString stringWithFormat:@"select * from %@ limit 0",tableName];
        FMResultSet* set = [db executeQuery:select];
        NSArray*  columnArray = set.columnNameToIndexMap.allKeys;
        [set close];
        BOOL hasTableChanged = NO;
        for (int i=0; i<infos.count; i++) {
            LKDBProperty* p = [infos objectWithIndex:i];
            if([p.sqlColumnName.lowercaseString isEqualToString:@"rowid"])
                continue;
            
            if([columnArray indexOfObject:p.sqlColumnName.lowercaseString] == NSNotFound)
            {
                if([clazz getAutoUpdateSqlColumn])
                {
                    [clazz tableUpdateAddColumnWithName:p.sqlColumnName sqliteType:p.sqlColumnType];
                    hasTableChanged = YES;
                }
                else
                {
                    [clazz removePropertyWithColumnName:p.sqlColumnName];
                }
            }
        }
        if (hasTableChanged) {
            [clazz tableDidCreatedOrUpdated];
        }
    }];
}
-(BOOL)createTableWithModelClass:(Class)modelClass
{
    checkClassIsInvalid(modelClass);
    NSString* tableName = [modelClass getTableName];
    
    int oldVersion = [_tableManager versionWithName:tableName];
    int newVersion = [modelClass getTableVersion];
    
    if(oldVersion>0 && oldVersion != newVersion)
    {
        [self fixSqlColumnsWithClass:modelClass];
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
        if([self getTableCreatedWithClass:modelClass])
        {
            //已创建表 就跳过
            [self fixSqlColumnsWithClass:modelClass];
            return YES;
        }
    }
    
    LKModelInfos* infos = [modelClass getModelInfos];
    NSArray* primaryKeys = infos.primaryKeys;
    BOOL isAutoinc = NO;
    if(primaryKeys.count == 1 && [[primaryKeys lastObject] isEqual:@"rowid"])
    {
        isAutoinc = YES;
    }
    NSMutableString* table_pars = [NSMutableString string];
    for (int i=0; i<infos.count; i++) {
        
        if(i > 0)
            [table_pars appendString:@","];
        
        LKDBProperty* property =  [infos objectWithIndex:i];
        [modelClass columnAttributeWithProperty:property];
        
        NSString* columnType = property.sqlColumnType;
        if([columnType isEqualToString:LKSQL_Type_Double])
            columnType = LKSQL_Type_Text;
        
        [table_pars appendFormat:@"%@ %@",property.sqlColumnName,columnType];
        
        if([property.sqlColumnType isEqualToString:LKSQL_Type_Text])
        {
            if(property.length>0)
            {
                [table_pars appendFormat:@"(%d)",property.length];
            }
        }
        if(property.isNotNull)
        {
            [table_pars appendFormat:@" %@",LKSQL_Attribute_NotNull];
        }
        if(property.isUnique)
        {
            [table_pars appendFormat:@" %@",LKSQL_Attribute_Unique];
        }
        if(property.checkValue)
        {
            [table_pars appendFormat:@" %@(%@)",LKSQL_Attribute_Check,property.checkValue];
        }
        if(property.defaultValue)
        {
            [table_pars appendFormat:@" %@ %@",LKSQL_Attribute_Default,property.defaultValue];
        }
        if(isAutoinc)
        {
            if([property.sqlColumnName isEqualToString:@"rowid"])
            {
                [table_pars appendString:@" primary key autoincrement"];
            }
        }
    }
    NSMutableString* pksb = [NSMutableString string];
    if(isAutoinc == NO)
    {
        if(primaryKeys.count>0)
        {
            pksb = [NSMutableString string];
            for (int i=0; i<primaryKeys.count; i++) {
                NSString* pk = [primaryKeys objectAtIndex:i];
                
                if(pksb.length>0)
                    [pksb appendString:@","];
                
                [pksb appendString:pk];
            }
            if(pksb.length>0)
            {
                [pksb insertString:@",primary key(" atIndex:0];
                [pksb appendString:@")"];
            }
        }
    }
    NSString* createTableSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@%@)",tableName,table_pars,pksb];
    
    BOOL isCreated = [self executeSQL:createTableSQL arguments:nil];
    
    if(isCreated)
    {
        [_tableManager setTableName:tableName version:newVersion];
        [modelClass tableDidCreatedOrUpdated];
    }
    
    return isCreated;
}
-(BOOL)getTableCreatedWithClass:(Class)modelClass
{
    __block BOOL isTableCreated = NO;
    [self executeDB:^(FMDatabase *db) {
        FMResultSet* set = [db executeQuery:@"select count(name) from sqlite_master where type='table' and name=?",[modelClass getTableName]];
        [set next];
        if([set intForColumnIndex:0]>0)
        {
            isTableCreated = YES;
        }
        [set close];
    }];
    return isTableCreated;
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
    return [self searchBase:modelClass columns:nil where:where orderBy:orderBy offset:offset count:count];
}
-(NSMutableArray *)search:(Class)modelClass column:(id)columns where:(id)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count
{
    return [self searchBase:modelClass columns:columns where:where orderBy:orderBy offset:offset count:count];
}
-(id)searchSingle:(Class)modelClass where:(id)where orderBy:(NSString *)orderBy
{
    NSMutableArray* array = [self searchBase:modelClass columns:nil where:where orderBy:orderBy offset:0 count:1];
    
    if(array.count>0)
        return [array objectAtIndex:0];
    
    return nil;
}
-(void)search:(Class)modelClass where:(id)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count callback:(void (^)(NSMutableArray *))block
{
    [self asyncBlock:^{
        NSMutableArray* array = [self searchBase:modelClass columns:nil where:where orderBy:orderBy offset:offset count:count];
        
        if(block != nil)
            block(array);
    }];
}

-(NSMutableArray *)searchBase:(Class)modelClass columns:(id)columns where:(id)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count
{
    NSString* columnsString = nil;
    NSUInteger columnCount = 0;
    if([columns isKindOfClass:[NSArray class]] && [columns count]>0){
        
        columnsString = [columns componentsJoinedByString:@","];
        columnsString = [NSString stringWithFormat:@"rowid,%@",columnsString];
        
    }else if([LKDBUtils checkStringIsEmpty:columns]==NO){
        
        columnsString = columns;
        NSArray* array = [columns componentsSeparatedByString:@","];
        
        columnCount = array.count;
        if(columnCount>1)
        {
            columnsString = [NSString stringWithFormat:@"rowid,%@",columnsString];
        }
    }
    
    if(columnCount==0){
        columnsString = @"rowid,*";
    }
    
    NSMutableString* query = [NSMutableString stringWithFormat:@"select %@ from @t",columnsString];
    NSMutableArray * values = [self extractQuery:query where:where];
    
    [self sqlString:query AddOder:orderBy offset:offset count:count];
    
    //replace @t to model table name
    NSString* replaceTableName = [NSString stringWithFormat:@" %@ ",[modelClass getTableName]];
    if([query hasSuffix:@" @t"]){
        [query appendString:@" "];
    }
    [query replaceOccurrencesOfString:@" @t " withString:replaceTableName options:NSCaseInsensitiveSearch range:NSMakeRange(0, query.length)];
    
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
        
        if(columnCount == 1)
        {
            results = [self executeOneColumnResult:set];
        }
        else
        {
            results = [self executeResult:set Class:modelClass];
        }
        
        [set close];
    }];
    return results;
}
-(NSMutableArray *)searchWithSQL:(NSString *)sql toClass:(Class)modelClass
{
    //replace @t to model table name
    NSString* tableName = [NSString stringWithFormat:@" %@ ",[modelClass getTableName]];
    if([sql hasSuffix:@" @t"]){
        sql = [sql stringByAppendingString:@" "];
    }
    NSString* executeSQL = [sql stringByReplacingOccurrencesOfString:@" @t " withString:tableName options:NSCaseInsensitiveSearch range:NSMakeRange(0, sql.length)];
    
    __block NSMutableArray* results = nil;
    [self executeDB:^(FMDatabase *db) {
        FMResultSet* set = [db executeQuery:executeSQL];
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
    if(count>0)
    {
        [sql appendFormat:@" limit %d offset %d",count,offset];
    }
    else if(offset > 0)
    {
        [sql appendFormat:@" limit %d offset %d",INT_MAX,offset];
    }
}
- (NSMutableArray *)executeOneColumnResult:(FMResultSet *)set
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:0];
    while ([set next]) {
        NSString* string = [set stringForColumnIndex:0];
        if(string)
        {
            [array addObject:string];
        }
    }
    return array;
}
- (NSMutableArray *)executeResult:(FMResultSet *)set Class:(Class)modelClass
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:0];
    LKModelInfos* infos = [modelClass getModelInfos];
    int columnCount = [set columnCount];
    while ([set next]) {
        
        NSObject* bindingModel = [[modelClass alloc]init];
        
        for (int i=0; i<columnCount; i++) {
            
            NSString* sqlName = [set columnNameForIndex:i];
            LKDBProperty* property = [infos objectWithSqlColumnName:sqlName];
            
            BOOL isUserCalculate = [property.type isEqualToString:LKSQL_Mapping_UserCalculate];
            if([[sqlName lowercaseString] isEqualToString:@"rowid"] && isUserCalculate==NO)
            {
                bindingModel.rowid = [set intForColumnIndex:i];
            }
            else
            {
                NSString* sqlValue = [set stringForColumnIndex:i];
                if(property.propertyName && isUserCalculate == NO)
                {
                    [bindingModel modelSetValue:property value:sqlValue];
                }
                else
                {
                    [bindingModel userSetValueForModel:property value:sqlValue];
                }
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
    if([modelClass dbWillInsert:model]==NO)
    {
        LKErrorLog(@"your cancel %@ insert",model);
        return NO;
    }
    
    //--
    LKModelInfos* infos = [modelClass getModelInfos];
    
    NSMutableString* insertKey = [NSMutableString stringWithCapacity:0];
    NSMutableString* insertValuesString = [NSMutableString stringWithCapacity:0];
    NSMutableArray* insertValues = [NSMutableArray arrayWithCapacity:infos.count];
    
    
    LKDBProperty* primaryProperty = [model singlePrimaryKeyProperty];
    
    for (int i=0; i<infos.count; i++) {
        
        LKDBProperty* property = [infos objectWithIndex:i];
        if([LKDBUtils checkStringIsEmpty:property.sqlColumnName])
            continue;
        
        if([property isEqual:primaryProperty])
        {
            if([model singlePrimaryKeyValueIsEmpty])
                continue;
        }
        
        if(insertKey.length>0)
        {
            [insertKey appendString:@","];
            [insertValuesString appendString:@","];
        }
        
        [insertKey appendString:property.sqlColumnName];
        [insertValuesString appendString:@"?"];
        
        id value = [self modelValueWithProperty:property model:model];
        
        [insertValues addObject:value];
    }
    
    //拼接insertSQL 语句  采用 replace 插入
    NSString* insertSQL = [NSString stringWithFormat:@"replace into %@(%@) values(%@)",[modelClass getTableName],insertKey,insertValuesString];
    
    __block BOOL execute = NO;
    __block sqlite_int64 lastInsertRowId = 0;
    
    [self executeDB:^(FMDatabase *db) {
        execute = [db executeUpdate:insertSQL withArgumentsInArray:insertValues];
        lastInsertRowId= db.lastInsertRowId;
    }];
    
    model.rowid = (int)lastInsertRowId;
    if(execute == NO)
        LKErrorLog(@"database insert fail %@, sql:%@",NSStringFromClass(modelClass),insertSQL);
    
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
    if([modelClass dbWillUpdate:model]==NO)
    {
        LKErrorLog(@"you cancel %@ update.",model);
        return NO;
    }
    
    LKModelInfos* infos = [modelClass getModelInfos];
    
    NSMutableString* updateKey = [NSMutableString string];
    NSMutableArray* updateValues = [NSMutableArray arrayWithCapacity:infos.count];
    for (int i=0; i<infos.count; i++) {
        
        LKDBProperty* property = [infos objectWithIndex:i];
        
        if(i>0)
            [updateKey appendString:@","];
        
        [updateKey appendFormat:@"%@=?",property.sqlColumnName];
        
        id value = [self modelValueWithProperty:property model:model];
        
        [updateValues addObject:value];
    }
    
    NSMutableString* updateSQL = [NSMutableString stringWithFormat:@"update %@ set %@ where ",[modelClass getTableName],updateKey];
    
    //添加where 语句
    if([where isKindOfClass:[NSString class]] && [LKDBUtils checkStringIsEmpty:where]== NO)
    {
        [updateSQL appendString:where];
    }
    else if([where isKindOfClass:[NSDictionary class]] && [(NSDictionary*)where count]>0)
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
        NSString* pwhere = [self primaryKeyWhereSQLWithModel:model addPValues:updateValues];
        if(pwhere.length ==0)
        {
            LKErrorLog(@"database update fail : %@ no find primary key!",NSStringFromClass(modelClass));
            return NO;
        }
        [updateSQL appendString:pwhere];
    }
    
    BOOL execute = [self executeSQL:updateSQL arguments:updateValues];
    if(execute == NO)
    {
        LKErrorLog(@"database update fail : %@   -----> update sql: %@",NSStringFromClass(modelClass),updateSQL);
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
        LKErrorLog(@"database update fail %@   ----->sql:%@",NSStringFromClass(modelClass),updateSQL);
    
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
    if([modelClass dbWillDelete:model] == NO)
    {
        LKErrorLog(@"you cancel %@ delete",model);
        return NO;
    }
    
    NSMutableString*  deleteSQL =[NSMutableString stringWithFormat:@"delete from %@ where ",[modelClass getTableName]];
    NSMutableArray* parsArray = [NSMutableArray array];
    if(model.rowid > 0)
    {
        [deleteSQL appendFormat:@"rowid = %d",model.rowid];
    }
    else
    {
        NSString* pwhere = [self primaryKeyWhereSQLWithModel:model addPValues:parsArray];
        if(pwhere.length==0)
        {
            LKErrorLog(@"delete fail : %@ primary value is nil",NSStringFromClass(modelClass));
            return NO;
        }
        [deleteSQL appendString:pwhere];
    }
    
    if(parsArray.count==0)
        parsArray = nil;
    
    BOOL execute = [self executeSQL:deleteSQL arguments:parsArray];
    
    //callback
    [modelClass dbDidDeleted:model result:execute];
    
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
    NSString* pwhere = nil;
    if(model.rowid>0){
        pwhere = [NSString stringWithFormat:@"rowid=%d",model.rowid];
    }
    else{
        pwhere = [self primaryKeyWhereSQLWithModel:model addPValues:nil];
    }
    if(pwhere.length == 0)
    {
        LKErrorLog(@"exists model fail: primary key is nil or invalid");
        return NO;
    }
    return [self isExistsClass:model.class where:pwhere];
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

+(void)clearNoneImage:(Class)modelClass columns:(NSArray *)columns
{
    [self clearFileWithTable:modelClass columns:columns type:1];
}
+(void)clearNoneData:(Class)modelClass columns:(NSArray *)columns
{
    [self clearFileWithTable:modelClass columns:columns type:2];
}
#define LKTestDirFilename @"LKTestDirFilename111"
+(void)clearFileWithTable:(Class)modelClass columns:(NSArray*)columns type:(int)type
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
        
        NSUInteger count =  columns.count;
        
        //获取该目录下所有文件名
        NSArray* files = [LKDBUtils getFilenamesWithDir:dir];
        
        NSString* seleteColumn = [columns componentsJoinedByString:@","];
        NSMutableString* whereStr =[NSMutableString string];
        for (int i=0; i<count ; i++) {
            [whereStr appendFormat:@" %@ != '' ",[columns objectAtIndex:i]];
            if(i< count -1)
            {
                [whereStr appendString:@" or "];
            }
        }
        NSString* querySql = [NSString stringWithFormat:@"select %@ from %@ where %@",seleteColumn,[modelClass getTableName],whereStr];
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


