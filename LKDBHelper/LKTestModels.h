//
//  LKTestModels.h
//  LKDBHelper
//
//  Created by upin on 13-7-12.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LKDBHelper.h"

@interface LKTestForeignSuper : NSObject
@property(copy,nonatomic)NSString* address;
@property int postcode;
@end

@interface LKTestForeign : LKTestForeignSuper
@property int addid;
@end



@interface LKTest : NSObject
@property(copy,nonatomic)NSString* name;
@property NSUInteger  age;
@property BOOL isGirl;

@property(strong,nonatomic)LKTestForeign* address;

@property char like;

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
@property(strong,nonatomic) UIImage* img;
@property(strong,nonatomic)UIColor* color;
@property CGRect frame1;
#else
@property(strong,nonatomic) NSImage* img;
@property(strong,nonatomic) NSColor* color;
@property NSRect frame1;
#endif

@property(strong,nonatomic) NSDate* date;

@property(copy,nonatomic)NSString* error;

//new add
@property double score;

@property(strong,nonatomic)NSData* data;

@property CGRect frame;

@property CGRect size;
@property CGPoint point;
@end


@interface NSObject(PrintSQL)
+(NSString*)getCreateTableSQL;
@end