//
//  NSObject+LKUtils.h
//  LKDBHelper
//
//  Created by LJH on 13-4-15.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LKDBUtils : NSObject

// 创建文件路径所需要的文件夹
+ (BOOL)createDirectoryWithFilePath:(NSString *)filePath;

///返回根目录路径 "document"
+ (NSString *)getDocumentPath;
///返回 "document/dir/" 文件夹路径
+ (NSString *)getDirectoryForDocuments:(NSString *)dir;
///返回 "document/filename" 路径
+ (NSString *)getPathForDocuments:(NSString *)filename;
///返回 "document/dir/filename" 路径
+ (NSString *)getPathForDocuments:(NSString *)filename inDir:(NSString *)dir;
///文件是否存在
+ (BOOL)isFileExists:(NSString *)filepath;
///删除文件
+ (BOOL)deleteWithFilepath:(NSString *)filepath;
///返回该文件目录下 所有文件名
+ (nullable NSArray *)getFilenamesWithDir:(NSString *)dir;

///检测字符串是否为空
+ (BOOL)checkStringIsEmpty:(NSString *)string;
+ (nullable NSString *)getTrimStringWithString:(nullable NSString *)string;

///把Date 转换成String
+ (NSString *)stringWithDate:(NSDate *)date;
///把String 转换成Date
+ (NSDate *)dateWithString:(NSString *)str;
///单例formatter
+ (NSNumberFormatter *)numberFormatter;

@end


#pragma mark - 数据格式化相关，可 method swizzle 做逻辑替换

@interface LKDateFormatter : NSDateFormatter

///由于 NSDateFormatter 相关API 并不是线程安全的
@property (nonatomic, readonly) dispatch_semaphore_t lock;

@end

@interface LKNumberFormatter : NSNumberFormatter

@end

@class LKDBHelper;

/// 需要外部实现对应 API
@interface LKDBUtils (Events)

// LKDateFormatter 创建完毕， 可以修改对应属性
+ (void)onCreateWithDateFormatter:(LKDateFormatter *)dateFormatter;

// LKNumberFormatter 创建完毕， 可以修改对应属性
+ (void)onCreateWithNumberFormatter:(LKNumberFormatter *)numberFormatter;

/// 数据库损坏
+ (void)onLKDBWithFails:(LKDBHelper *)dbHelper dbError:(NSError *)dbError;

@end

#pragma mark - Types

#ifdef DEBUG
#ifdef NSLog
#define LKErrorLog(fmt, ...) NSLog(@"#LKDBHelper Log:\n" fmt, ##__VA_ARGS__);
#else
#define LKErrorLog(fmt, ...) NSLog(@"\n#LKDBHelper Log: %s  [Line %d] \n" fmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#endif
#else
#define LKErrorLog(...)
#endif

static NSString *const LKSQL_Type_Text = @"text";
static NSString *const LKSQL_Type_Int = @"integer";
static NSString *const LKSQL_Type_Double = @"double";
static NSString *const LKSQL_Type_Blob = @"blob";

static NSString *const LKSQL_Attribute_NotNull = @"NOT NULL";
static NSString *const LKSQL_Attribute_PrimaryKey = @"PRIMARY KEY";
static NSString *const LKSQL_Attribute_Default = @"DEFAULT";
static NSString *const LKSQL_Attribute_Unique = @"UNIQUE";
static NSString *const LKSQL_Attribute_Check = @"CHECK";
static NSString *const LKSQL_Attribute_ForeignKey = @"FOREIGN KEY";

static NSString *const LKSQL_Convert_FloatType = @"float_double_decimal";
static NSString *const LKSQL_Convert_IntType = @"int_char_short_long";
static NSString *const LKSQL_Convert_BlobType = @"";

static NSString *const LKSQL_Mapping_Inherit = @"LKDBInherit";
static NSString *const LKSQL_Mapping_Binding = @"LKDBBinding";
static NSString *const LKSQL_Mapping_UserCalculate = @"LKDBUserCalculate";

static NSString *const LKDB_TypeKey = @"DB_Type";

static NSString *const LKDB_TypeKey_Model = @"DB_Type_Model";
static NSString *const LKDB_TypeKey_JSON = @"DB_Type_JSON";
static NSString *const LKDB_TypeKey_Combo = @"DB_Type_Combo";
static NSString *const LKDB_TypeKey_Date = @"DB_Type_Date";

static NSString *const LKDB_ValueKey = @"DB_Value";

static NSString *const LKDB_TableNameKey = @"DB_TableName";
static NSString *const LKDB_ClassKey = @"DB_Class";
static NSString *const LKDB_RowIdKey = @"DB_RowId";
static NSString *const LKDB_PValueKey = @"DB_PKeyValue";

///Object-c type converted to SQLite type  把Object-c 类型 转换为sqlite 类型
extern NSString *LKSQLTypeFromObjcType(NSString *objcType);

#pragma mark - Search Utils

@interface LKDBQueryParams : NSObject

///columns or array
@property (nullable, nonatomic, copy) NSString *columns;
@property (nullable, nonatomic, copy) NSArray<NSString *> *columnArray;

@property (nullable, nonatomic, copy) NSString *tableName;

///where or dic
@property (nullable, nonatomic, copy) NSString *where;
@property (nullable, nonatomic, copy) NSDictionary<NSString *, id> *whereDic;

@property (nullable, nonatomic, copy) NSString *groupBy;
@property (nullable, nonatomic, copy) NSString *orderBy;

@property (nonatomic, assign) NSInteger offset;
@property (nonatomic, assign) NSInteger count;

@property (nullable, nonatomic, strong) Class toClass;

@property (nullable, nonatomic, copy) void (^callback)(NSMutableArray *_Nullable results);

@end

NS_ASSUME_NONNULL_END
