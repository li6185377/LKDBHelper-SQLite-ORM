//
//  LKDALBase+LKDALBase.m
//  CarDaMan
//
//  Created by y h on 12-10-9.
//  Copyright (c) 2012年 LK. All rights reserved.
//

#import "LKDAOBase.h"
#import "FMDatabaseQueue.h"
#import "FMResultSet.h"
#import "FMDatabase.h"
#import <objc/runtime.h>

@implementation LKDAOBase
@synthesize columeNames;
@synthesize columeTypes;
@synthesize bindingQueue;
+(NSString *)getTableName
{
    return @"";
}
+(Class)getBindingModelClass
{
    return [NSObject class];
}
-(void)executeDB:(void (^)(FMDatabase *db))block
{
    __block BOOL lock = YES;
    [bindingQueue inDatabase:^(FMDatabase *db) {
        block(db);
        lock = NO;
    }];
    while (lock) {}
}
-(id)initWithDBQueue:(FMDatabaseQueue *)queue
{
    self = [super init];
    if (self) {
        self.bindingQueue = queue;
        
        self.columeNames = [NSMutableArray arrayWithCapacity:16];
        self.columeTypes = [NSMutableArray arrayWithCapacity:16];
        
        //获取绑定的 Model 并 保存 Model 的属性信息
        NSDictionary* dic  = [[self.class getBindingModelClass] getPropertys];
        NSString* primaryKey = [[self.class getBindingModelClass] primaryKey];
        NSArray* pronames = [dic objectForKey:@"name"];
        NSArray* protypes = [dic objectForKey:@"type"];
        self.propertys = [NSMutableDictionary dictionaryWithObjects:protypes forKeys:pronames];
        for (int i =0; i<pronames.count; i++) {
            NSString* columeName = [pronames objectAtIndex:i];
            if([primaryKey isEqualToString:columeName])
            {
                [self addColumePrimaryKey:columeName type:[protypes objectAtIndex:i]];
            }
            else
            {
                [self addColume:columeName type:[protypes objectAtIndex:i]];
            }
        }
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            onceCreateTable = [[NSMutableDictionary  alloc]initWithCapacity:8];
        });
        NSString* className = NSStringFromClass(self.class);
        NSNumber* onceToCreate = [onceCreateTable objectForKey:className];
        if(onceToCreate.boolValue == NO)
        {
            [self createTable];
            onceToCreate = [NSNumber numberWithBool:YES];
            [onceCreateTable setObject:onceToCreate forKey:className];
        }
    }
    return self;
    
}
-(void)dealloc
{
    self.bindingQueue = nil;
    self.propertys = nil;
    self.columeNames = nil;
    self.columeTypes = nil;
    [super dealloc];
}
static NSMutableDictionary* onceCreateTable;
+(void)clearCreateHistory
{
    [onceCreateTable removeAllObjects];
}
-(void)createTable
{
    if(! [self.class checkStringNotEmpty:[self.class getTableName]])
    {
        NSLog(@"LKTableName is None!");
        return;
    }
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSString* createTable = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@)",[self.class getTableName],[self getParameterString]];
         [db executeUpdate:createTable];
         
     }];
}
-(void)addColumePrimaryKey:(NSString *)name type:(NSString *)type
{
    [columeNames addObject:name];
    [columeTypes addObject:[NSString stringWithFormat:@"%@ %@",[LKDAOBase toDBType:type],LKSQLPrimaryKey]];
}
-(void)addColume:(NSString *)name type:(NSString *)type
{
    [columeNames addObject:name];
    [columeTypes addObject:[LKDAOBase toDBType:type]];
}
-(NSString *)getParameterString
{
    NSMutableString* pars = [NSMutableString string];
    for (int i=0; i<columeNames.count; i++) {
        [pars appendFormat:@"%@ %@",[columeNames objectAtIndex:i],[columeTypes objectAtIndex:i]];
        if(i+1 !=columeNames.count)
        {
            [pars appendString:@","];
        }
    }
    return pars;
}

#pragma mark - 条数
-(int)rowCountWhere:(id)where
{
    __block int result= 0;
    [self executeDB:^(FMDatabase *db) {
        result = [self rowCountWhere:where db:db];
    }];
    return result;
}
-(int)rowCountWhere:(id)where db:(id)db
{
    NSMutableString* rowCountSql = [NSMutableString stringWithFormat:@"select count(rowid) from %@ ",[self.class getTableName]];
    FMResultSet* resultSet = nil;
    if([where isKindOfClass:[NSString class]] && [self.class checkStringNotEmpty:where])
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
    [resultSet next];
    int result =  [resultSet intForColumnIndex:0];
    [resultSet close];
    return result;
}
-(void)rowCount:(void (^)(int))callback where:(id)where
{
    [bindingQueue inDatabase:^(FMDatabase* db){
        callback([self rowCountWhere:where db:db]);
    }];
}

#pragma mark - 搜索

-(NSArray*)searchWhere:(NSString *)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count db:(id)db
{
    NSMutableString* query = [NSMutableString stringWithFormat:@"select rowid,* from %@ ",[self.class getTableName]];
    if([self.class checkStringNotEmpty:where])
    {
        [query appendFormat:@" where %@",where];
    }
    [self sqlString:query AddOder:orderBy offset:offset count:count];
    
    
    __block NSArray* results = nil;
    if(db == nil)
    {
        [self executeDB:^(FMDatabase *db) {
           FMResultSet* set =[db executeQuery:query];
           results = [self executeResult:set];
        }];
    }
    else
    {
        FMResultSet* set =[db executeQuery:query];
        results = [self executeResult:set];
    }
    return results;
}
-(NSArray*)searchWhere:(NSString *)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count
{
    return [self searchWhere:where orderBy:orderBy offset:offset count:count db:nil];
}
-(void)searchWhere:(NSString *)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count callback:(void (^)(NSArray *))block
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         block([self searchWhere:where orderBy:orderBy offset:offset count:count db:db]);
     }];
}
#pragma mark - 搜索  dic
-(NSArray*)searchWhereDic:(NSDictionary*)where orderBy:(NSString *)orderby offset:(int)offset count:(int)count db:(id)db
{
    
    
    NSMutableString* query = [NSMutableString stringWithFormat:@"select rowid,* from %@ ",[self.class getTableName]];
    NSMutableArray* values = [NSMutableArray arrayWithCapacity:0];
    if(where !=nil&& where.count>0)
    {
        NSString* wherekey = [self dictionaryToSqlWhere:where andValues:values];
        [query appendFormat:@" where %@",wherekey];
    }
    [self sqlString:query AddOder:orderby offset:offset count:count];

    __block NSArray* results = nil;
    if(db == nil)
    {
        [self executeDB:^(FMDatabase *db) {
            FMResultSet* set =[db executeQuery:query withArgumentsInArray:values];
            results = [self executeResult:set];
        }];
    }
    else
    {
        FMResultSet* set =[db executeQuery:query withArgumentsInArray:values];
        results = [self executeResult:set];
    }
    return results;
}
-(NSArray*)searchWhereDic:(NSDictionary*)where orderBy:(NSString *)orderby offset:(int)offset count:(int)count
{
    return [self searchWhereDic:where orderBy:orderby offset:offset count:count db:nil];
}
-(void)searchWhereDic:(NSDictionary*)where orderBy:(NSString *)orderby offset:(int)offset count:(int)count callback:(void (^)(NSArray *))block
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         block([self searchWhereDic:where orderBy:orderby offset:offset count:count db:db]);
     }];
}

#pragma mark - base function
-(void)sqlString:(NSMutableString*)sql AddOder:(NSString*)orderby offset:(int)offset count:(int)count
{
    if([self.class checkStringNotEmpty:orderby])
    {
        [sql appendFormat:@" order by %@ ",orderby];
    }
    [sql appendFormat:@" limit %d offset %d ",count,offset];
}
- (NSArray *)executeResult:(FMResultSet *)set
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:0];
    while ([set next]) {
        NSObject* bindingModel = [[[[self.class getBindingModelClass] alloc]init] autorelease];
        bindingModel.rowid = [set intForColumnIndex:0];
        for (int i=0; i<self.columeNames.count; i++) {
            NSString* columeName = [self.columeNames objectAtIndex:i];
            NSString* columeType = [self.propertys objectForKey:columeName];
            if([@"intfloatdoublelongcharshort" rangeOfString:columeType].location != NSNotFound)
            {
                [bindingModel setValue:[NSNumber numberWithDouble:[set doubleForColumn:columeName]] forKey:columeName];
            }
            else if([columeType isEqualToString:@"NSString"])
            {
                [bindingModel setValue:[set stringForColumn:columeName] forKey:columeName];
            }
            else if([columeType isEqualToString:@"UIImage"])
            {
                NSString* filename = [set stringForColumn:columeName];
                if([LKDBPathHelper isFileExists:[LKDBPathHelper getPathForDocuments:filename inDir:@"dbimg"]])
                {
                    UIImage* img = [UIImage imageWithContentsOfFile:[LKDBPathHelper getPathForDocuments:filename inDir:@"dbimg"]];
                    [bindingModel setValue:img forKey:columeName];
                }
            }
            else if([columeType isEqualToString:@"NSDate"])
            {
                NSString* datestr = [set stringForColumn:columeName];
                [bindingModel setValue:[LKDAOBase dateWithString:datestr] forKey:columeName];
            }
            else if([columeType isEqualToString:@"NSData"])
            {
                NSString* filename = [set stringForColumn:columeName];
                if([LKDBPathHelper isFileExists:[LKDBPathHelper getPathForDocuments:filename inDir:@"dbdata"]])
                {
                    NSData* data = [NSData dataWithContentsOfFile:[LKDBPathHelper getPathForDocuments:filename inDir:@"dbdata"]];
                    [bindingModel setValue:data forKey:columeName];
                }
            }
            else
            {
                [self safetySetModel:bindingModel key:columeName value:[set objectForColumnName:columeName] type:columeType];
            }
            
        }
        [array addObject:bindingModel];
    }
    [set close];
    return array;
}

#pragma mark insert model
-(BOOL)insertToDB:(NSObject*)model db:(FMDatabase*)db{
    
    if(model == nil)
    {
        return false;
    }
    
    
    NSDate* date = [NSDate date];
    NSMutableString* insertKey = [NSMutableString stringWithCapacity:0];
    NSMutableString* insertValuesString = [NSMutableString stringWithCapacity:0];
    NSMutableArray* insertValues = [NSMutableArray arrayWithCapacity:self.columeNames.count];
    for (int i=0; i<self.columeNames.count; i++) {
        
        NSString* proname = [self.columeNames objectAtIndex:i];
        [insertKey appendFormat:@"%@,", proname];
        [insertValuesString appendString:@"?,"];
        id value =[self safetyGetModel:model valueKey:proname];
        if([value isKindOfClass:[UIImage class]])
        {
            NSString* filename = [NSString stringWithFormat:@"img%f",[date timeIntervalSince1970]];
            [UIImageJPEGRepresentation(value, 1) writeToFile:[LKDBPathHelper getPathForDocuments:filename inDir:@"dbimg"] atomically:YES];
            value = filename;
        }
        else if([value isKindOfClass:[NSData class]])
        {
            NSString* filename = [NSString stringWithFormat:@"data%f",[date timeIntervalSince1970]];
            [value writeToFile:[LKDBPathHelper getPathForDocuments:filename inDir:@"dbdata"] atomically:YES];
            value = filename;
        }
        else if([value isKindOfClass:[NSDate class]])
        {
            value = [LKDAOBase stringWithDate:value];
        }
        [insertValues addObject:value];
    }
    [insertKey deleteCharactersInRange:NSMakeRange(insertKey.length - 1, 1)];
    [insertValuesString deleteCharactersInRange:NSMakeRange(insertValuesString.length - 1, 1)];
    NSString* insertSQL = [NSString stringWithFormat:@"replace into %@(%@) values(%@)",[self.class getTableName],insertKey,insertValuesString];
    
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
        NSLog(@"database insert fail %@",NSStringFromClass(model.class));
    }
    return execute;
    
}
-(BOOL)insertToDB:(NSObject*)model
{
    return [self insertToDB:model db:nil];
}
-(void)insertToDB:(NSObject*)model callback:(void (^)(BOOL))block{
    
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         if(block != nil)
         {
             block([self insertToDB:model db:db]);
         }
         else
         {
             [self insertToDB:model db:db];
         }
     }];
}

#pragma mark- update model
-(BOOL)updateToDB:(NSObject *)model where:(id)where db:(FMDatabase*)db
{
    NSDate* date = [NSDate date];
    NSMutableString* updateKey = [NSMutableString stringWithCapacity:0];
    NSMutableArray* updateValues = [NSMutableArray arrayWithCapacity:self.columeNames.count];
    for (int i=0; i<self.columeNames.count; i++) {
        
        NSString* proname = [self.columeNames objectAtIndex:i];
        [updateKey appendFormat:@" %@=?,", proname];
        
        id value =[self safetyGetModel:model valueKey:proname];
        if([value isKindOfClass:[UIImage class]])
        {
            NSString* filename = [NSString stringWithFormat:@"img%f",[date timeIntervalSince1970]];
            [UIImageJPEGRepresentation(value, 1) writeToFile:[LKDBPathHelper getPathForDocuments:filename inDir:@"dbimg"] atomically:YES];
            value = filename;
        }
        else if([value isKindOfClass:[NSData class]])
        {
            NSString* filename = [NSString stringWithFormat:@"data%f",[date timeIntervalSince1970]];
            [value writeToFile:[LKDBPathHelper getPathForDocuments:filename inDir:@"dbdata"] atomically:YES];
            value = filename;
        }
        else if([value isKindOfClass:[NSDate class]])
        {
            value = [LKDAOBase stringWithDate:value];
        }
        [updateValues addObject:value];
    }
    [updateKey deleteCharactersInRange:NSMakeRange(updateKey.length - 1, 1)];
    
    NSMutableString* updateSQL = [NSMutableString stringWithFormat:@"update %@ set %@ where  ",[self.class getTableName],updateKey];
    
    if([where isKindOfClass:[NSString class]] && [self.class checkStringNotEmpty:where])
    {
        [updateSQL appendString:where];
    }
    else if([where isKindOfClass:[NSDictionary class]])
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
        [updateSQL appendFormat:@"%@=?",[model.class  primaryKey]];
        [updateValues addObject:[self safetyGetModel:model valueKey:[model.class  primaryKey]]];
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
        NSLog(@"database update fail %@   ----->rowid: %d",NSStringFromClass(model.class),model.rowid);
    }
    return execute;
}

-(void)updateToDB:(NSObject *)model where:(id)where callback:(void (^)(BOOL))block
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         if(block != nil)
         {
             block([self updateToDB:model where:where db:db]);
         }
         else
         {
            [self updateToDB:model where:where db:db];
         }
     }];
}
-(BOOL)updateToDB:(NSObject *)model where:(id)where
{
    return [self updateToDB:model where:where db:nil];
}

#pragma mark- delete
-(void)deleteToDB:(NSObject*)model callback:(void (^)(BOOL))block{
    
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSString* delete;
         BOOL result;
         if(model.rowid > 0)
         {
             delete = [NSString stringWithFormat:@"DELETE FROM %@ where rowid=%d",[self.class getTableName],model.rowid];
             result = [db executeUpdate:delete];
         }
         else
         {
             NSString* primarykey = [model.class  primaryKey];
             delete = [NSString stringWithFormat:@"delete from %@ where %@=?",[self.class getTableName],primarykey];
             id value = [self safetyGetModel:model valueKey:primarykey];
             result = [db executeUpdate:delete withArgumentsInArray:@[value]];
         }
         if(block != nil)
         {
             block(result);
         }
     }];
}
-(void)deleteToDBWithWhere:(NSString *)where callback:(void (^)(BOOL))block
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSString* delete = [NSString stringWithFormat:@"delete from %@ where %@",[self.class getTableName],where];
         BOOL result = [db executeUpdate:delete];
         if(block != nil)
         {
             block(result);
         }
     }];
}
-(void)deleteToDBWithWhereDic:(NSDictionary *)where callback:(void (^)(BOOL))block
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSMutableArray* values = [NSMutableArray arrayWithCapacity:6];
         NSString* wherekey = [self dictionaryToSqlWhere:where andValues:values];
         NSString* delete = [NSString stringWithFormat:@"delete from %@ where %@",[self.class getTableName],wherekey];
         BOOL result = [db executeUpdate:delete withArgumentsInArray:values];
         if(block != nil)
         {
             block(result);
         }
     }];
}

#pragma mark- function with dictionary
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
-(void)clearTableData
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSString* delete = [NSString stringWithFormat:@"DELETE FROM %@",[self.class getTableName]];
         [db executeUpdate:delete];
     }];
}
#pragma mark - exists
-(BOOL)isExistsModel:(NSObject*)model
{
    //如果有rowid 就肯定存在 所以就不判断rowid > 0
    return [self isExistsWithWhere:[NSString stringWithFormat:@"%@ = '%@'",[model.class  primaryKey],[self safetyGetModel:model valueKey:[model.class  primaryKey]]] db:nil];
}
-(void)isExistsModel:(NSObject*)model callback:(void(^)(BOOL))block{
    [self isExistsWithWhere:[NSString stringWithFormat:@"%@ = '%@'",[model.class primaryKey],[self safetyGetModel:model valueKey:[model.class  primaryKey]]] callback:block];
}
-(BOOL)isExistsWithWhere:(NSString *)where db:(id)db
{
    NSString* rowCountSql = [NSString stringWithFormat:@"select count(rowid) from %@ where %@",[self.class getTableName],where];
    FMResultSet* resultSet = [db executeQuery:rowCountSql];
    [resultSet next];
    int result =  [resultSet intForColumnIndex:0];
    [resultSet close];
    BOOL exists = (result != 0);
    return exists;
}
-(BOOL)isExistsWithWhere:(NSString *)where
{
    return [self isExistsWithWhere:where db:nil];
}
-(void)isExistsWithWhere:(NSString *)where callback:(void (^)(BOOL))block
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         block([self isExistsWithWhere:where db:db]);
     }];
}
-(id)safetyGetModel:(NSObject*) model valueKey:(NSString*)valueKey
{
    id value = [model valueForKey:valueKey];
    if(value == nil)
    {
        return @"";
    }
    return value;
}
-(void)safetySetModel:(NSObject *)model key:(NSString *)key value:(id)value type:(NSString *)type{}
#pragma mark- 静态方法


@end


static char LKModelBase_Key_RowID;
@implementation NSObject(LKModelBase)

+(NSDictionary *)getPropertys
{
    NSMutableArray* pronames = [NSMutableArray array];
    NSMutableArray* protypes = [NSMutableArray array];
    NSDictionary* props = [NSDictionary dictionaryWithObjectsAndKeys:pronames,@"name",protypes,@"type",nil];
    [self getSelfPropertys:pronames protypes:protypes];
    return props;
}
+(BOOL)isContainParent
{
    return NO;
}
/**
 *	@brief	获取自身的属性
 *
 *	@param 	pronames 	保存属性名称
 *	@param 	protypes 	保存属性类型
 */
+ (void)getSelfPropertys:(NSMutableArray *)pronames protypes:(NSMutableArray *)protypes
{
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        if([propertyName isEqualToString:@"primaryKey"]||[propertyName isEqualToString:@"rowid"])
        {
            continue;
        }
        [pronames addObject:propertyName];
        NSString *propertyType = [NSString stringWithCString: property_getAttributes(property) encoding:NSUTF8StringEncoding];
        /*
         c char
         i int
         l long
         s short
         d double
         f float
         @ id //指针 对象
         ...  BOOL 获取到的表示 方式是 char
         .... ^i 表示  int*  一般都不会用到
         */
        
        if ([propertyType hasPrefix:@"T@"]) {
            [protypes addObject:[propertyType substringWithRange:NSMakeRange(3, [propertyType rangeOfString:@","].location-4)]];
        }
        else if ([propertyType hasPrefix:@"Ti"])
        {
            [protypes addObject:@"int"];
        }
        else if ([propertyType hasPrefix:@"Tf"])
        {
            [protypes addObject:@"float"];
        }
        else if([propertyType hasPrefix:@"Td"]) {
            [protypes addObject:@"double"];
        }
        else if([propertyType hasPrefix:@"Tl"])
        {
            [protypes addObject:@"long"];
        }
        else if ([propertyType hasPrefix:@"Tc"]) {
            [protypes addObject:@"char"];
        }
        else if([propertyType hasPrefix:@"Ts"])
        {
            [protypes addObject:@"short"];
        }
        
    }
    free(properties);
    if([self isContainParent] && [self superclass] != [NSObject class])
    {
        [[self superclass] getSelfPropertys:pronames protypes:protypes];
    }
}

-(void)setRowid:(int)rowid
{
    objc_setAssociatedObject(self, &LKModelBase_Key_RowID,[NSNumber numberWithInt:rowid], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(int)rowid
{
    return [objc_getAssociatedObject(self, &LKModelBase_Key_RowID) intValue];
}

+(NSString *)primaryKey
{
    return @"";
}

-(void)printAllPropertys
{
    NSMutableString* sb = [NSMutableString stringWithCapacity:0];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        [sb appendFormat:@"\n %@ : %@ ",propertyName,[self valueForKey:propertyName]];
    }
    free(properties);
    NSLog(@"\n%@\n",sb);
}
@end