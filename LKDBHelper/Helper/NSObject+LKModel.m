//
//  NSObject+LKModel.m
//  LKDBHelper
//
//  Created by upin on 13-4-15.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import "NSObject+LKModel.h"



static char LKModelBase_Key_RowID;
@implementation NSObject (LKModel)

+(NSDictionary *)getPropertys
{
    static NSMutableDictionary* oncePropertyDic;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        oncePropertyDic = [[NSMutableDictionary alloc]initWithCapacity:8];
    });
    NSDictionary* props = [oncePropertyDic objectForKey:NSStringFromClass(self)];
    if(props == nil)
    {
        NSMutableArray* pronames = [NSMutableArray array];
        NSMutableArray* protypes = [NSMutableArray array];
        NSMutableArray* sqltypes = [NSMutableArray array];
        
        props = [NSDictionary dictionaryWithObjectsAndKeys:pronames,@"name",protypes,@"type",sqltypes,@"sqltype",nil];
        [self getSelfPropertys:pronames protypes:protypes];
        
        [oncePropertyDic setObject:props forKey:NSStringFromClass(self)];
    }
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
    objc_property_t *properties = class_copyPropertyList(self, &outCount);
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

+(NSString *)getPrimaryKey
{
    return @"";
}
+(NSString *)getTableName
{
    return NSStringFromClass(self);
}

#pragma mark- translate value
+(NSString*)getDBImageDir
{
    return [NSString stringWithFormat:@"dbimg/%@",NSStringFromClass(self)];
}
+(NSString*)getDBDataDir
{
    return [NSString stringWithFormat:@"dbdata/%@",NSStringFromClass(self)];
}
-(id)modelGetValueWithKey:(NSString *)key type:(NSString *)columeType
{
    id value = [self valueForKey:key];
    if([value isKindOfClass:[UIImage class]])
    {
        long random = arc4random();
        long date = [[NSDate date] timeIntervalSince1970];
        NSString* filename = [NSString stringWithFormat:@"img%ld%ld",date&0xFFFFF,random&0xFFF];
        
        NSData* datas = UIImageJPEGRepresentation(value, 1);
        [datas writeToFile:[LKDBUtils getPathForDocuments:filename inDir:[self.class getDBImageDir]] atomically:YES];
        value = filename;
    }
    else if([value isKindOfClass:[NSData class]])
    {
        long random = arc4random();
        long date = [[NSDate date] timeIntervalSince1970];
        NSString* filename = [NSString stringWithFormat:@"data%ld%ld",date&0xFFFFF,random&0xFFF];
        
        [value writeToFile:[LKDBUtils getPathForDocuments:filename inDir:[self.class getDBDataDir]] atomically:YES];
        value = filename;
    }
    else if([value isKindOfClass:[NSDate class]])
    {
        value = [LKDBUtils stringWithDate:value];
    }
    else if([value isKindOfClass:[UIColor class]])
    {
        UIColor* color = value;
        float r,g,b,a;
        [color getRed:&r green:&g blue:&b alpha:&a];
        value = [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f",r,g,b,a];
    }
    else if([columeType isEqualToString:@"char"])
    {
        value = [value stringValue];
    }
    return value;
}

-(void)modelSetValue:(id)value key:(NSString *)key type:(NSString *)columeType
{
    id modelValue = value;
    if([columeType isEqualToString:@"UIImage"])
    {
        NSString* filename = value;
        if([LKDBUtils isFileExists:[LKDBUtils getPathForDocuments:filename inDir:[self.class getDBImageDir]]])
        {
            UIImage* img = [UIImage imageWithContentsOfFile:[LKDBUtils getPathForDocuments:filename inDir:[self.class getDBImageDir]]];
            modelValue = img;
        }
    }
    else if([columeType isEqualToString:@"NSDate"])
    {
        NSString* datestr = value;
        modelValue = [LKDBUtils dateWithString:datestr];
    }
    else if([columeType isEqualToString:@"NSData"])
    {
        
        NSString* filename = value;
        if([LKDBUtils isFileExists:[LKDBUtils getPathForDocuments:filename inDir:[self.class getDBDataDir]]])
        {
            NSData* data = [NSData dataWithContentsOfFile:[LKDBUtils getPathForDocuments:filename inDir:[self.class getDBDataDir]]];
            modelValue = data;
        }
    }else if([columeType isEqualToString:@"UIColor"])
    {
        NSString* color = value;
        NSArray* array = [color componentsSeparatedByString:@","];
        float r,g,b,a;
        r = [[array objectAtIndex:0] floatValue];
        g = [[array objectAtIndex:1] floatValue];
        b = [[array objectAtIndex:2] floatValue];
        a = [[array objectAtIndex:3] floatValue];
        
        value = [UIColor colorWithRed:r green:g blue:b alpha:a];
    }
    
    [self setValue:modelValue forKey:key];
}

#pragma mark -
-(void)setRowid:(int)rowid
{
    objc_setAssociatedObject(self, &LKModelBase_Key_RowID,[NSNumber numberWithInt:rowid], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(int)rowid
{
    return [objc_getAssociatedObject(self, &LKModelBase_Key_RowID) intValue];
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

#pragma mark version manager
//版本号  最少为1
+(int)getTableVersion
{
    return 1;
}
+(LKTableUpdateType)tableUpdateWithDBHelper:(LKDBHelper *)helper oldVersion:(int)oldVersion newVersion:(int)newVersion
{
    return LKTableUpdateTypeDefault;
}
@end