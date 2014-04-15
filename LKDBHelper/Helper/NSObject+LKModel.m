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
@implementation NSObject (LKModel)
+(LKDBHelper *)getUsingLKDBHelper
{
    static LKDBHelper* helper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[LKDBHelper alloc]init];
    });
    return helper;
}
#pragma mark Tabel Structure Function 表结构
+(NSString *)getTableName
{
    return NSStringFromClass(self);
}
+(BOOL)getAutoUpdateSqlColumn
{
    return YES;
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
-(void)setRowid:(int)rowid
{
    objc_setAssociatedObject(self, &LKModelBase_Key_RowID,[NSNumber numberWithInt:rowid], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(int)rowid
{
    return [objc_getAssociatedObject(self, &LKModelBase_Key_RowID) intValue];
}
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
+(NSDateFormatter*)getModelDateFormatter{
    return nil;
}
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
    
    return returnValue;
}
-(void)modelSetValue:(LKDBProperty *)property value:(id)value
{
    id modelValue = value;
    NSString* columnType = property.propertyType;
    if([columnType isEqualToString:@"NSString"])
    {
        
    }
    else if([columnType isEqualToString:@"NSNumber"])
    {
        modelValue = [NSNumber numberWithDouble:[value doubleValue]];
    }
    else if([LKSQL_Convert_FloatType rangeOfString:columnType].location != NSNotFound)
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
    else if([columnType isEqualToString:@"NSDate"])
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
    else if([columnType isEqualToString:NSStringFromClass([LKDBColor class])])
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
#endif
    else if([columnType isEqualToString:NSStringFromClass([LKDBImage class])])
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
    else if([columnType isEqualToString:@"NSData"])
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
    
    [self setValue:modelValue forKey:property.propertyName];
}
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
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        oncePropertyDic = [[NSMutableDictionary alloc]initWithCapacity:8];
    });
    
    LKModelInfos* infos;
    @synchronized(self)
    {
        infos = [oncePropertyDic objectForKey:NSStringFromClass(self)];
        if(infos == nil)
        {
            NSMutableArray* pronames = [NSMutableArray array];
            NSMutableArray* protypes = [NSMutableArray array];
            NSDictionary* keymapping = [self getTableMapping];
            [self getSelfPropertys:pronames protypes:protypes];
            
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
            
            infos = [[LKModelInfos alloc]initWithKeyMapping:keymapping propertyNames:pronames propertyType:protypes primaryKeys:pkArray];
            [oncePropertyDic setObject:infos forKey:NSStringFromClass(self)];
        }
    }
    return infos;
    
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
    objc_property_t *properties = class_copyPropertyList(self, &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        
        //取消rowid 的插入 //子类 已重载的属性 取消插入
        if([propertyName isEqualToString:@"rowid"] ||
           [pronames indexOfObject:propertyName] != NSNotFound)
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
    free(properties);
    if([self isContainParent] && [self superclass] != [NSObject class])
    {
        [[self superclass] getSelfPropertys:pronames protypes:protypes];
    }
}

#pragma mark - log all property
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
        [self mutableString:sb appendPropertyStringWithClass:self.superclass containParent:containParent];
    }
}

@end