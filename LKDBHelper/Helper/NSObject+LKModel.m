//
//  NSObject+LKModel.m
//  LKDBHelper
//
//  Created by upin on 13-4-15.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import "NSObject+LKModel.h"
#import "LKDBHelper.h"

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
    return nil;
}
+(NSString *)getPrimaryKey
{
    return nil;
}
+(void)columeAttributeWithProperty:(LKDBProperty *)property
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
-(id)modelGetValue:(LKDBProperty *)property
{
    id value = [self valueForKey:property.propertyName];
    id returnValue = nil;
    if(value == nil)
    {
        returnValue = @"";
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
        returnValue = [LKDBUtils stringWithDate:value];
    }
    else if([value isKindOfClass:[UIColor class]])
    {
        UIColor* color = value;
        float r,g,b,a;
        [color getRed:&r green:&g blue:&b alpha:&a];
        returnValue = [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f",r,g,b,a];
    }
    else if([value isKindOfClass:[NSValue class]])
    {
        NSString* columeType = property.propertyType;
        if([columeType isEqualToString:@"CGRect"])
        {
            returnValue = NSStringFromCGRect([value CGRectValue]);
        }
        else if([columeType isEqualToString:@"CGPoint"])
        {
            returnValue = NSStringFromCGPoint([value CGPointValue]);
        }
        else if([columeType isEqualToString:@"CGSize"])
        {
            returnValue = NSStringFromCGSize([value CGSizeValue]);
        }
    }
    else if([value isKindOfClass:[UIImage class]])
    {
        long random = arc4random();
        long date = [[NSDate date] timeIntervalSince1970];
        NSString* filename = [NSString stringWithFormat:@"img%ld%ld",date&0xFFFFF,random&0xFFF];
        
        NSData* datas = UIImageJPEGRepresentation(value, 1);
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
    if(returnValue == nil)
        returnValue = @"";
    
    return returnValue;
}
-(void)modelSetValue:(LKDBProperty *)property value:(id)value
{
    id modelValue = value;
    NSString* columeType = property.propertyType;
    if([columeType isEqualToString:@"NSString"])
    {
        
    }
    else if([LKSQLFloatType rangeOfString:columeType].location != NSNotFound)
    {
        modelValue = [NSNumber numberWithFloat:[value floatValue]];
    }
    else if([LKSQLIntType rangeOfString:columeType].location != NSNotFound)
    {
        modelValue = [NSNumber numberWithFloat:[value intValue]];
    }
    else if([columeType isEqualToString:@"NSDate"])
    {
        NSString* datestr = value;
        modelValue = [LKDBUtils dateWithString:datestr];
    }
    else if([columeType isEqualToString:@"UIColor"])
    {
        NSString* color = value;
        NSArray* array = [color componentsSeparatedByString:@","];
        float r,g,b,a;
        r = [[array objectAtIndex:0] floatValue];
        g = [[array objectAtIndex:1] floatValue];
        b = [[array objectAtIndex:2] floatValue];
        a = [[array objectAtIndex:3] floatValue];
        
        modelValue = [UIColor colorWithRed:r green:g blue:b alpha:a];
    }
    else if([columeType isEqualToString:@"CGRect"])
    {
        modelValue = [NSValue valueWithCGRect:CGRectFromString(value)];
    }
    else if([columeType isEqualToString:@"CGPoint"])
    {
        modelValue = [NSValue valueWithCGPoint:CGPointFromString(value)];
    }
    else if([columeType isEqualToString:@"CGSize"])
    {
        modelValue = [NSValue valueWithCGSize:CGSizeFromString(value)];
    }
    else if([columeType isEqualToString:@"UIImage"])
    {
        NSString* filename = value;
        NSString* filepath = [self.class getDBImagePathWithName:filename];
        if([LKDBUtils isFileExists:filepath])
        {
            UIImage* img = [UIImage imageWithContentsOfFile:filepath];
            modelValue = img;
        }
        else
        {
            modelValue = nil;
        }
    }
    else if([columeType isEqualToString:@"NSData"])
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
    return @"";
}

-(id)getPrimaryValue
{
    NSString* primarykey = [self.class getPrimaryKey];
    LKModelInfos* infos = [self.class getModelInfos];
    LKDBProperty* property = [infos objectWithSqlColumeName:primarykey];
    
    if(primarykey&&property)
    {
        return [self modelGetValue:property];
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
            
            infos = [[LKModelInfos alloc]initWithKeyMapping:keymapping propertyNames:pronames propertyType:protypes];
            
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
        if([propertyName isEqualToString:@"rowid"])
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
            if ([propertyType hasPrefix:@"ti"])
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
            else if([propertyType hasPrefix:@"tl"])
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
#ifdef DEBUG
    NSMutableString* sb = [NSMutableString stringWithFormat:@"<%@> \n", [self class]];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    [sb appendFormat:@" %@ : %@ \n",@"rowid",[self valueForKey:@"rowid"]];
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        [sb appendFormat:@" %@ : %@ \n",propertyName,[self valueForKey:propertyName]];
    }
    free(properties);
    NSLog(@"%@",sb);
    return sb;
#else
    return @"";
#endif
}

@end