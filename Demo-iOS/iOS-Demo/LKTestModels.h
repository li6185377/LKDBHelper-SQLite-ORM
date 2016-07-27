//
//  LKTestModels.h
//  LKDBHelper
//
//  Created by upin on 13-7-12.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LKDBHelper.h"

@interface LKTestForeignSuper : NSObject
@property(copy,nonatomic)NSString* address;
@property int postcode;
@end

@class LKTest;
@interface LKTestForeign : LKTestForeignSuper
@property NSInteger addid;

@property(strong,nonatomic) LKTest* nestModel;

@end



@interface LKTest : NSObject

@property(strong,nonatomic) LKTestForeign* nestModel;

@property(copy, nonatomic) NSURL* url;
@property(copy,nonatomic)NSString* name;
@property NSUInteger  age;
@property BOOL isGirl;

@property(strong,nonatomic)LKTestForeign* address;
@property(strong,nonatomic)NSArray* blah;
@property(strong,nonatomic)NSDictionary* hoho;

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
@property CGFloat score;

@property(strong,nonatomic)NSData* data;

@property CGRect frame;

@property CGRect size;
@property CGPoint point;
@property NSRange range;
@end


@interface NSObject(PrintSQL)
+(NSString*)getCreateTableSQL;
@end