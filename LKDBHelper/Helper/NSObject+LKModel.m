//
//  NSObject+LKModel.m
//  LKDBHelper
//
//  Created by upin on 13-4-15.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import "NSObject+LKModel.h"
#import "LKDBHelper.h"

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#define LKDBImage UIImage
#define LKDBColor UIColor
#else
#define LKDBImage NSImage
#define LKDBColor NSColor
#endif

static char LKModelBase_Key_RowID;
static char LKModelBase_Key_TableName;
static char LKModelBase_Key_Inserting;

@implementation NSObject (LKModel)

+(LKDBHelper *)getUsingLKDBHelper
{
    ///ios8 能获取系统类的属性了  所以没有办法判断属性数量来区分自定义类和系统类
    ///所以要 重载该方法 才能进行数据库操作
    return nil;
}
#pragma mark Tabel Structure Function 表结构
+(NSString *)getTableName
{
    return NSStringFromClass(self);
}

+(NSString *)getPrimaryKey
{
    return @"rowid";
}

+(NSArray *)getPrimaryKeyUnionArray
{
    return nil;
}


+(void)columnAttributeWithProperty:(LKDBProperty *)property
{
    //overwrite
}
#pragma 属性
-(void)setRowid:(int)rowid
{
    objc_setAssociatedObject(self, &LKModelBase_Key_RowID,[NSNumber numberWithInt:rowid], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(int)rowid
{
    return [objc_getAssociatedObject(self, &LKModelBase_Key_RowID) intValue];
}

-(void)setDb_tableName:(NSString *)db_tableName
{
    objc_setAssociatedObject(self, &LKModelBase_Key_TableName,db_tableName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
-(NSString *)db_tableName
{
    NSString* tableName = objc_getAssociatedObject(self, &LKModelBase_Key_TableName);
    if(tableName.length == 0)
    {
        tableName = [self.class getTableName];
    }
    return tableName;
}
-(BOOL)db_inserting
{
   return [objc_getAssociatedObject(self, &LKModelBase_Key_Inserting) boolValue];
}
-(void)setDb_inserting:(BOOL)db_inserting
{
    NSNumber* number = nil;
    if(db_inserting)
    {
        number = [NSNumber numberWithBool:YES];
    }
    objc_setAssociatedObject(self, &LKModelBase_Key_Inserting,number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
#pragma 无关紧要的
+(NSString *)getDBImagePathWithName:(NSString *)filename
{
    NSString* dir = [NSString stringWithFormat:@"dbimg/%@",NSStringFromClass(self)];
    return [LKDBUtils getPathForDocuments:filename inDir:dir];
}
+(NSString*)getDBDataPathWithName:(NSString *)filename
{
    NSString* dir = [NSString stringWithFormat:@"dbdata/%@",NSStringFromClass(self)];
    return [LKDBUtils getPathForDocuments:filename inDir:dir];
}
+(NSDictionary *)getTableMapping
{
    return nil;
}
#pragma mark- Table Data Function 表数据
+(NSDateFormatter*)getModelDateFormatter
{
    return nil;
}

///get
-(id)modelGetValue:(LKDBProperty *)property
{
    id value = [self valueForKey:property.propertyName];
    id returnValue = value;
    if(value == nil)
    {
        return nil;
    }
    else if([value isKindOfClass:[NSString class]])
    {
        returnValue = value;
    }
    else if([value isKindOfClass:[NSNumber class]])
    {
        returnValue = [value stringValue];
    }
    else if([value isKindOfClass:[NSDate class]])
    {
        NSDateFormatter* formatter = [self.class getModelDateFormatter];
        if(formatter){
            returnValue = [formatter stringFromDate:value];
        }
        else{
            returnValue = [LKDBUtils stringWithDate:value];
        }
        returnValue = [returnValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    else if([value isKindOfClass:[LKDBColor class]])
    {
        LKDBColor* color = value;
        CGFloat r,g,b,a;
        [color getRed:&r green:&g blue:&b alpha:&a];
        returnValue = [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f",r,g,b,a];
    }
    else if([value isKindOfClass:[NSValue class]])
    {
        NSString* columnType = property.propertyType;
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
        if([columnType isEqualToString:@"CGRect"])
        {
            returnValue = NSStringFromCGRect([value CGRectValue]);
        }
        else if([columnType isEqualToString:@"CGPoint"])
        {
            returnValue = NSStringFromCGPoint([value CGPointValue]);
        }
        else if([columnType isEqualToString:@"CGSize"])
        {
            returnValue = NSStringFromCGSize([value CGSizeValue]);
        }
        else if([columnType isEqualToString:@"_NSRange"])
        {
            returnValue = NSStringFromRange([value rangeValue]);
        }
#else
        if([columnType hasSuffix:@"Rect"])
        {
            returnValue = NSStringFromRect([value rectValue]);
        }
        else if([columnType hasSuffix:@"Point"])
        {
            returnValue = NSStringFromPoint([value pointValue]);
        }
        else if([columnType hasSuffix:@"Size"])
        {
            returnValue = NSStringFromSize([value sizeValue]);
        }
        else if([columnType hasSuffix:@"Range"])
        {
            returnValue = NSStringFromRange([value rangeValue]);
        }
#endif
    }
    else if([value isKindOfClass:[LKDBImage class]])
    {
        long random = arc4random();
        long date = [[NSDate date] timeIntervalSince1970];
        NSString* filename = [NSString stringWithFormat:@"img%ld%ld",date&0xFFFFF,random&0xFFF];
        
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
        NSData* datas = UIImageJPEGRepresentation(value, 1);
#else
        [value lockFocus];
        NSBitmapImageRep *srcImageRep = [NSBitmapImageRep imageRepWithData:[value TIFFRepresentation]];
        NSData* datas = [srcImageRep representationUsingType:NSJPEGFileType properties:nil];
        [value unlockFocus];
#endif
        [datas writeToFile:[self.class getDBImagePathWithName:filename] atomically:YES];
        
        returnValue = filename;
    }
    else if([value isKindOfClass:[NSData class]])
    {
        long random = arc4random();
        long date = [[NSDate date] timeIntervalSince1970];
        NSString* filename = [NSString stringWithFormat:@"data%ld%ld",date&0xFFFFF,random&0xFFF];
        
        [value writeToFile:[self.class getDBDataPathWithName:filename] atomically:YES];
        
        returnValue = filename;
    }
    else
    {
        if([value isKindOfClass:[NSArray class]])
        {
            returnValue = [self db_jsonObjectFromArray:value];
        }
        else if([value isKindOfClass:[NSDictionary class]])
        {
            returnValue = [self db_jsonObjectFromDictionary:value];
        }
        else
        {
            returnValue = [self db_jsonObjectFromModel:value];
        }
        returnValue = [self db_jsonStringFromObject:returnValue];
    }
    
    return returnValue;
}

///set
-(void)modelSetValue:(LKDBProperty *)property value:(id)value
{
    ///参试获取属性的Class
    Class columnClass = NSClassFromString(property.propertyType);
    
    id modelValue = value;
    if([value length] == 0)
    {
        modelValue = nil;
    }
    else if(columnClass == nil)
    {
        ///当找不到 class 时，就是 基础类型 int,float CGRect 之类的
        
        NSString* columnType = property.propertyType;
        if([LKSQL_Convert_FloatType rangeOfString:columnType].location != NSNotFound)
        {
            modelValue = [NSNumber numberWithDouble:[value doubleValue]];
        }
        else if([LKSQL_Convert_IntType rangeOfString:columnType].location != NSNotFound)
        {
            if([columnType isEqualToString:@"long"])
            {
                modelValue = [NSNumber numberWithLongLong:[value longLongValue]];
            }
            else
            {
                modelValue = [NSNumber numberWithInteger:[value intValue]];
            }
        }
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
        else if([columnType isEqualToString:@"CGRect"])
        {
            modelValue = [NSValue valueWithCGRect:CGRectFromString(value)];
        }
        else if([columnType isEqualToString:@"CGPoint"])
        {
            modelValue = [NSValue valueWithCGPoint:CGPointFromString(value)];
        }
        else if([columnType isEqualToString:@"CGSize"])
        {
            modelValue = [NSValue valueWithCGSize:CGSizeFromString(value)];
        }
        else if([columnType isEqualToString:@"_NSRange"])
        {
            modelValue = [NSValue valueWithRange:NSRangeFromString(value)];
        }
#else
        else if([columnType hasSuffix:@"Rect"])
        {
            modelValue = [NSValue valueWithRect:NSRectFromString(value)];
        }
        else if([columnType hasSuffix:@"Point"])
        {
            modelValue = [NSValue valueWithPoint:NSPointFromString(value)];
        }
        else if([columnType hasSuffix:@"Size"])
        {
            modelValue = [NSValue valueWithSize:NSSizeFromString(value)];
        }
        else if([columnType hasSuffix:@"Range"])
        {
            modelValue = [NSValue valueWithRange:NSRangeFromString(value)];
        }
#endif
    }
    else if([columnClass isSubclassOfClass:[NSString class]])
    {
        
    }
    else if([columnClass isSubclassOfClass:[NSNumber class]])
    {
        modelValue = [NSNumber numberWithDouble:[value doubleValue]];
    }
    else if([columnClass isSubclassOfClass:[NSDate class]])
    {
        NSString* datestr = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSDateFormatter* formatter = [self.class getModelDateFormatter];
        if(formatter){
            modelValue = [formatter dateFromString:datestr];
        }
        else{
            modelValue = [LKDBUtils dateWithString:datestr];
        }
    }
    else if([columnClass isSubclassOfClass:[LKDBColor class]])
    {
        NSString* color = value;
        NSArray* array = [color componentsSeparatedByString:@","];
        float r,g,b,a;
        r = [[array objectAtIndex:0] floatValue];
        g = [[array objectAtIndex:1] floatValue];
        b = [[array objectAtIndex:2] floatValue];
        a = [[array objectAtIndex:3] floatValue];
        
        modelValue = [LKDBColor colorWithRed:r green:g blue:b alpha:a];
    }
    else if([columnClass isSubclassOfClass:[LKDBImage class]])
    {
        NSString* filename = value;
        NSString* filepath = [self.class getDBImagePathWithName:filename];
        if([LKDBUtils isFileExists:filepath])
        {
            LKDBImage* img = [[LKDBImage alloc] initWithContentsOfFile:filepath];
            modelValue = img;
        }
        else
        {
            modelValue = nil;
        }
    }
    else if([columnClass isSubclassOfClass:[NSData class]])
    {
        NSString* filename = value;
        NSString* filepath = [self.class getDBDataPathWithName:filename];
        if([LKDBUtils isFileExists:filepath])
        {
            NSData* data = [NSData dataWithContentsOfFile:filepath];
            modelValue = data;
        }
        else
        {
            modelValue = nil;
        }
    }
    else
    {
        modelValue = [self db_modelWithJsonValue:value];
        if([modelValue isKindOfClass:columnClass] == NO)
        {
            modelValue = nil;
        }
    }
    
    [self setValue:modelValue forKey:property.propertyName];
}

#pragma mark- 对 model NSArray NSDictionary 进行支持
-(id)db_jsonObjectFromDictionary:(NSDictionary*)dic
{
    if([NSJSONSerialization isValidJSONObject:dic])
    {
        NSDictionary* bomb = @{LKDB_TypeKey:LKDB_TypeKey_JSON,LKDB_ValueKey:dic};
        return bomb;
    }
    else
    {
        NSMutableDictionary* toDic = [NSMutableDictionary dictionary];
        NSArray* allKeys = dic.allKeys;
        for (int i = 0; i<allKeys.count; i++)
        {
            NSString* key = [allKeys objectAtIndex:i];
            id obj = [dic objectForKey:key];
            id jsonObject = [self db_jsonObjectWithObject:obj];
            if(jsonObject)
            {
                [toDic setObject:jsonObject forKey:key];
            }
        }
        
        if(toDic.count)
        {
            NSDictionary* bomb = @{LKDB_TypeKey:LKDB_TypeKey_Combo,LKDB_ValueKey:toDic};
            return bomb;
        }
    }
    return nil;
    
}
-(id)db_jsonObjectFromArray:(NSArray*)array
{
    if([NSJSONSerialization isValidJSONObject:array])
    {
        NSDictionary* bomb = @{LKDB_TypeKey:LKDB_TypeKey_JSON,LKDB_ValueKey:array};
        return bomb;
    }
    else
    {
        NSMutableArray* toArray = [NSMutableArray array];
        NSInteger count = array.count;
        for (int i = 0; i < count; i++)
        {
            id obj = [array objectAtIndex:i];
            id jsonObject = [self db_jsonObjectWithObject:obj];
            if(jsonObject)
            {
                [toArray addObject:jsonObject];
            }
        }
        
        if(toArray.count)
        {
            NSDictionary* bomb = @{LKDB_TypeKey:LKDB_TypeKey_Combo,LKDB_ValueKey:toArray};
            return bomb;
        }
    }
    return nil;
}
///目前只支持 model、NSString、NSNumber 简单类型
-(id)db_jsonObjectWithObject:(id)obj
{
    NSString* jsonObject = nil;
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]])
    {
        jsonObject = obj;
    }
    else if([obj isKindOfClass:[NSArray class]])
    {
        jsonObject = [self db_jsonObjectFromArray:obj];
    }
    else if([obj isKindOfClass:[NSDictionary class]])
    {
        jsonObject = [self db_jsonObjectFromArray:obj];
    }
    else
    {
        jsonObject = [self db_jsonObjectFromModel:obj];
    }
    
    if(jsonObject == nil)
    {
        jsonObject = [obj description];
    }
    return jsonObject;
}

-(id)db_jsonObjectFromModel:(NSObject*)model
{
    Class clazz = model.class;
    NSDictionary* jsonObject = nil;
    if(model.rowid > 0)
    {
        jsonObject = @{LKDB_TypeKey:LKDB_TypeKey_Model,
                       LKDB_TableNameKey:model.db_tableName,
                       LKDB_ClassKey:NSStringFromClass(clazz),
                       LKDB_RowIdKey:@(model.rowid)};
    }
    else
    {
        uint outCount = 0;
        objc_property_t *properties = class_copyPropertyList(clazz, &outCount);
        free(properties);
        if(outCount > 0 && model.db_inserting == NO)
        {
            BOOL success = [model saveToDB];
            if(success)
            {
                jsonObject = @{LKDB_TypeKey:LKDB_TypeKey_Model,
                               LKDB_TableNameKey:model.db_tableName,
                               LKDB_ClassKey:NSStringFromClass(clazz),
                               LKDB_RowIdKey:@(model.rowid)};
            }
        }
    }
    return jsonObject;
}
-(NSString*)db_jsonStringFromObject:(NSObject*)jsonObject
{
    if(jsonObject && [NSJSONSerialization isValidJSONObject:jsonObject])
    {
        NSData* data = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:nil];
        if(data.length > 0)
        {
            NSString* jsonString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            return jsonString;
        }
    }
    return nil;
}
-(id)db_modelWithJsonValue:(id)value
{
    NSData* jsonData = nil;
    if([value isKindOfClass:[NSString class]])
    {
        jsonData = [value dataUsingEncoding:NSUTF8StringEncoding];
    }
    else if([value isKindOfClass:[NSData class]])
    {
        jsonData = value;
    }
    
    if(jsonData.length > 0)
    {
        NSDictionary* jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
        return [self db_objectWithDictionary:jsonDic];
    }
    return nil;
}
-(id)db_objectWithArray:(NSArray*)array
{
    NSMutableArray* toArray = nil;
    
    NSInteger count = array.count;
    for (int i=0; i<count; i++)
    {
        id value = [array objectAtIndex:i];
        if([value isKindOfClass:[NSDictionary class]])
        {
            value = [self db_objectWithDictionary:value];
        }
        else if([value isKindOfClass:[NSArray class]])
        {
            value = [self db_objectWithArray:value];
        }
        
        if(value)
        {
            if (toArray == nil)
            {
                toArray = [NSMutableArray array];
            }
            [toArray addObject:value];
        }
    }
    
    return toArray;
}
-(id)db_objectWithDictionary:(NSDictionary*)dic
{
    if(dic.count == 0)
    {
        return nil;
    }
    NSString* type = [dic objectForKey:LKDB_TypeKey];
    if(type)
    {
        if([type isEqualToString:LKDB_TypeKey_Model])
        {
            Class clazz = NSClassFromString([dic objectForKey:LKDB_ClassKey]);
            int rowid = [[dic objectForKey:LKDB_RowIdKey] intValue];
            NSString* tableName = [dic objectForKey:LKDB_TableNameKey];
            
            NSArray* array = [[clazz getUsingLKDBHelper] searchWithSQL:[NSString stringWithFormat:@"select rowid,* from %@ where rowid=%d limit 1",tableName,rowid] toClass:clazz];
            if(array.count > 0)
            {
                NSObject* result = [array objectAtIndex:0];
                result.db_tableName = tableName;
                return result;
            }
        }
        else if([type isEqualToString:LKDB_TypeKey_JSON])
        {
            id value = [dic objectForKey:LKDB_ValueKey];
            return value;
        }
        else if([type isEqualToString:LKDB_TypeKey_Combo])
        {
            id value = [dic objectForKey:LKDB_ValueKey];
            if ([value isKindOfClass:[NSArray class]])
            {
                return [self db_objectWithArray:value];
            }
            else if([value isKindOfClass:[NSDictionary class]])
            {
                return [self db_objectWithDictionary:value];
            }
            else
            {
                return value;
            }
        }
    }
    else
    {
        NSArray* allKeys = dic.allKeys;
        NSMutableDictionary* toDic = [NSMutableDictionary dictionary];
        for (int i=0; i < allKeys.count; i++)
        {
            NSString* key = [allKeys objectAtIndex:i];
            id value = [dic objectForKey:key];
            
            id saveObj = value;
            if([value isKindOfClass:[NSArray class]])
            {
                saveObj = [self db_objectWithArray:value];
            }
            else if([value isKindOfClass:[NSDictionary class]])
            {
                saveObj = [self db_objectWithDictionary:value];
            }
            
            [toDic setObject:saveObj forKey:key];
        }
        return toDic;
    }
    return nil;
}
#pragma mark- your can overwrite
-(id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"你有get方法没实现");
    return nil;
}
-(void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    NSLog(@"你有set方法没实现");
}

#pragma mark-
-(void)userSetValueForModel:(LKDBProperty *)property value:(id)value{}
-(id)userGetValueForModel:(LKDBProperty *)property
{
    return nil;
}


//主键值 是否为空
-(BOOL)singlePrimaryKeyValueIsEmpty
{
    LKDBProperty* property = [self singlePrimaryKeyProperty];
    if(property)
    {
        id pkvalue = [self singlePrimaryKeyValue];
        if([property.sqlColumnType isEqualToString:LKSQL_Type_Int])
        {
            if([pkvalue isKindOfClass:[NSString class]])
            {
                if([LKDBUtils checkStringIsEmpty:pkvalue])
                    return YES;
                
                if([pkvalue intValue] == 0)
                    return YES;
                
                return NO;
            }
            if([pkvalue isKindOfClass:[NSNumber class]])
            {
                if([pkvalue intValue] == 0)
                    return YES;
                else
                    return NO;
            }
            return YES;
        }
        else
        {
            return (pkvalue == nil);
        }
    }
    return NO;
}
-(LKDBProperty *)singlePrimaryKeyProperty
{
    LKModelInfos* infos = [self.class getModelInfos];
    if(infos.primaryKeys.count == 1)
    {
        NSString* name = [infos.primaryKeys objectAtIndex:0];
        return [infos objectWithSqlColumnName:name];
    }
    return nil;
}
-(id)singlePrimaryKeyValue
{
    LKDBProperty* property = [self singlePrimaryKeyProperty];
    if(property)
    {
        if([property.type isEqualToString:LKSQL_Mapping_UserCalculate])
        {
            return [self userGetValueForModel:property];
        }
        else
        {
            return [self modelGetValue:property];
        }
    }
    return nil;
}

#pragma mark- get model property info
+(LKModelInfos *)getModelInfos
{
    static __strong NSMutableDictionary* oncePropertyDic;
    static __strong NSRecursiveLock* lock;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = [[NSRecursiveLock alloc]init];
        oncePropertyDic = [[NSMutableDictionary alloc]initWithCapacity:8];
    });
    
    LKModelInfos* infos;
    [lock lock];
    
    infos = [oncePropertyDic objectForKey:NSStringFromClass(self)];
    if(infos == nil)
    {
        NSMutableArray* pronames = [NSMutableArray array];
        NSMutableArray* protypes = [NSMutableArray array];
        NSDictionary* keymapping = [self getTableMapping];
        
        if ([self isContainSelf] && [self class] != [NSObject class])
        {
            [self getSelfPropertys:pronames protypes:protypes];
        }
        
        NSArray* pkArray = [self getPrimaryKeyUnionArray];
        if(pkArray.count == 0)
        {
            pkArray = nil;
            NSString* pk = [self getPrimaryKey];
            if([LKDBUtils checkStringIsEmpty:pk] == NO)
            {
                pkArray = [NSArray arrayWithObject:pk];
            }
        }
        if([self isContainParent] && [self superclass] != [NSObject class])
        {
            LKModelInfos* superInfos = [[self superclass] getModelInfos];
            for (int i=0; i<superInfos.count; i++) {
                LKDBProperty* db_p = [superInfos objectWithIndex:i];
                if(db_p.propertyName && db_p.propertyType && [db_p.propertyName isEqualToString:@"rowid"]==NO)
                {
                    [pronames addObject:db_p.propertyName];
                    [protypes addObject:db_p.propertyType];
                }
            }
        }
        
        infos = [[LKModelInfos alloc]initWithKeyMapping:keymapping propertyNames:pronames propertyType:protypes primaryKeys:pkArray];
        [oncePropertyDic setObject:infos forKey:NSStringFromClass(self)];
    }
    
    [lock unlock];
    return infos;
    
}

+(BOOL)isContainParent
{
    return NO;
}

+(BOOL)isContainSelf
{
    return YES;
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
    objc_property_t *properties = class_copyPropertyList(self, &outCount);
    
    id respondInstance = nil;
    if(outCount > 0)
    {
        respondInstance = [[self alloc]init];
    }
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        
        //取消rowid 的插入 //子类 已重载的属性 取消插入
        if([propertyName isEqualToString:@"rowid"] ||
           [pronames indexOfObject:propertyName] != NSNotFound)
        {
            continue;
        }
        NSString *propertyType = [NSString stringWithCString: property_getAttributes(property) encoding:NSUTF8StringEncoding];
        
        ///过滤只读属性
        if ([propertyType containsString:@",R,"] || [propertyType hasSuffix:@",R"])
        {
            NSString* setMethodString = [NSString stringWithFormat:@"set%@:",[propertyName capitalizedString]];
            SEL setSEL = NSSelectorFromString(setMethodString);
            ///有set方法就不过滤了
            if([respondInstance respondsToSelector:setSEL] == NO)
            {
                continue;
            }
        }
        
        [pronames addObject:propertyName];
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
            
            NSString* propertyClassName = [propertyType substringWithRange:NSMakeRange(3, [propertyType rangeOfString:@","].location-4)];
            if(propertyClassName==nil)
            {
                propertyClassName = @"NSString";
            }
            else if([propertyClassName hasSuffix:@">"])
            {
                NSRange range = [propertyClassName rangeOfString:@"<"];
                if (range.length>0)
                {
                    propertyClassName = [propertyClassName substringToIndex:range.location];
                }
            }
            [protypes addObject:propertyClassName];
        }
        else if([propertyType hasPrefix:@"T{"])
        {
            [protypes addObject:[propertyType substringWithRange:NSMakeRange(2, [propertyType rangeOfString:@"="].location-2)]];
        }
        else
        {
            propertyType = [propertyType lowercaseString];
            if ([propertyType hasPrefix:@"ti"] || [propertyType hasPrefix:@"tb"])
            {
                [protypes addObject:@"int"];
            }
            else if ([propertyType hasPrefix:@"tf"])
            {
                [protypes addObject:@"float"];
            }
            else if([propertyType hasPrefix:@"td"]) {
                [protypes addObject:@"double"];
            }
            else if([propertyType hasPrefix:@"tl"] || [propertyType hasPrefix:@"tq"])
            {
                [protypes addObject:@"long"];
            }
            else if ([propertyType hasPrefix:@"tc"]) {
                [protypes addObject:@"char"];
            }
            else if([propertyType hasPrefix:@"ts"])
            {
                [protypes addObject:@"short"];
            }
            else {
                [protypes addObject:@"NSString"];
            }
        }
    }
    respondInstance = nil;
    free(properties);
    if([self isContainParent] && [self superclass] != [NSObject class])
    {
        [[self superclass] getSelfPropertys:pronames protypes:protypes];
    }
}

#pragma mark - log all property
-(NSMutableString *)getAllPropertysString
{
    Class clazz = [self class];
    NSMutableString* sb = [NSMutableString stringWithFormat:@"\n <%@> :\n", NSStringFromClass(clazz)];
    [sb appendFormat:@"rowid : %d\n",self.rowid];
    [self mutableString:sb appendPropertyStringWithClass:clazz containParent:YES];
    return sb;
}
-(NSString*)printAllPropertys
{
    return [self printAllPropertysIsContainParent:NO];
}
-(NSString *)printAllPropertysIsContainParent:(BOOL)containParent
{
#ifdef DEBUG
    Class clazz = [self class];
    NSMutableString* sb = [NSMutableString stringWithFormat:@"\n <%@> :\n", NSStringFromClass(clazz)];
    [sb appendFormat:@"rowid : %d\n",self.rowid];
    [self mutableString:sb appendPropertyStringWithClass:clazz containParent:containParent];
    NSLog(@"%@",sb);
    return sb;
#else
    return @"";
#endif
}
-(void)mutableString:(NSMutableString*)sb appendPropertyStringWithClass:(Class)clazz containParent:(BOOL)containParent
{
    if (clazz == [NSObject class])
    {
        return;
    }
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(clazz, &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        [sb appendFormat:@" %@ : %@ \n",propertyName,[self valueForKey:propertyName]];
    }
    free(properties);
    if(containParent)
    {
        [self mutableString:sb appendPropertyStringWithClass:clazz.superclass containParent:containParent];
    }
}

@end