//
//  NSObject+LKUtils.m
//  LKDBHelper
//
//  Created by upin on 13-4-15.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import "LKDBUtils.h"

@implementation LKDBUtils
+(NSString *)getDocumentPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}
+(NSString *)getDirectoryForDocuments:(NSString *)dir
{
    NSError* error;
    NSString* path = [[self getDocumentPath] stringByAppendingPathComponent:dir];
    
    if(![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error])
    {
        NSLog(@"create dir error: %@",error.debugDescription);
    }
    return path;
}
+ (NSString *)getPathForDocuments:(NSString *)filename
{
    return [[self getDocumentPath] stringByAppendingPathComponent:filename];
}
+(NSString *)getPathForDocuments:(NSString *)filename inDir:(NSString *)dir
{
    return [[self getDirectoryForDocuments:dir] stringByAppendingPathComponent:filename];
}
+(BOOL)isFileExists:(NSString *)filepath
{
    return [[NSFileManager defaultManager] fileExistsAtPath:filepath];
}
+(BOOL)deleteWithFilepath:(NSString *)filepath
{
   return [[NSFileManager defaultManager] removeItemAtPath:filepath error:nil];
}
+(NSArray*)getFilenamesWithDir:(NSString*)dir
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray *fileList = [fileManager contentsOfDirectoryAtPath:dir error:nil];
    return fileList;
}
+(BOOL)checkStringIsEmpty:(NSString *)string
{
    if(string == nil)
    {
        return YES;
    }
    if([string isKindOfClass:[NSNull class]])
    {
        return YES;
    }
    return [[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""];
}

+(NSDateFormatter*)getDBDateFormat
{
    static NSDateFormatter* format;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        format = [[NSDateFormatter alloc]init];
        format.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    });
    return format;
}
+(NSString*)stringWithDate:(NSDate*)date
{
    NSDateFormatter* formatter = [self getDBDateFormat];
    NSString* datestr = [formatter stringFromDate:date];
    return datestr;
}
+(NSDate *)dateWithString:(NSString *)str
{
    NSDateFormatter* formatter =[self getDBDateFormat];
    NSDate* date = [formatter dateFromString:str];
    return date;
}
@end
