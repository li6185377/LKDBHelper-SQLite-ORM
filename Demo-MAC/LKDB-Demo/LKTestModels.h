//
//  LKTestModels.h
//  LKDBHelper
//
//  Created by upin on 13-7-12.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import "LKDBHelper.h"
#import <Foundation/Foundation.h>

@interface LKTestForeignSuper : NSObject
@property (nonatomic, copy) NSString *address;
@property (nonatomic, assign) int postcode;
@end

@class LKTest;
@interface LKTestForeign : LKTestForeignSuper

@property (nonatomic, assign) NSInteger addid;
@property (nonatomic, strong) LKTest *nestModel;

@end


@interface LKTest : NSObject

@property (nonatomic, strong) LKTestForeign *nestModel;

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSUInteger age;
@property (nonatomic, assign) BOOL isGirl;

@property (nonatomic, strong) LKTestForeign *address;
@property (nonatomic, strong) NSArray *blah;
@property (nonatomic, strong) NSDictionary *hoho;

@property char like;

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
@property (nonatomic, strong) UIImage *img;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGRect frame1;
#else
@property (nonatomic, strong) NSImage *img;
@property (nonatomic, strong) NSColor *color;
@property (nonatomic, assign) NSRect frame1;
#endif

@property (nonatomic, strong) NSDate *date;

@property (nonatomic, copy) NSString *error;

//new add
@property (nonatomic, assign) CGFloat score;

@property (nonatomic, strong) NSData *data;

@property (nonatomic, assign) CGRect frame;

@property (nonatomic, assign) CGRect size;
@property (nonatomic, assign) CGPoint point;
@property (nonatomic, assign) NSRange range;
@end


@interface NSObject (PrintSQL)
+ (NSString *)getCreateTableSQL;
@end
