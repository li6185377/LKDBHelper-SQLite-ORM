//
//  LKTestModels.h
//  LKDBHelper
//
//  Created by upin on 13-7-12.
//  Copyright (c) 2013年 ljh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LKDBHelper.h"

@interface LKTestForeign : NSObject
@property int addid;
@property(copy,nonatomic)NSString* address;
@property int postcode;
@end



@interface LKTest : NSObject
@property(copy,nonatomic)NSString* name;
@property NSUInteger  age;
@property BOOL isGirl;

@property(strong,nonatomic)LKTestForeign* address;

@property char like;
@property(strong,nonatomic) UIImage* img;
@property(strong,nonatomic) NSDate* date;

@property(copy,nonatomic)NSString* error;
@property(strong,nonatomic)UIColor* color;

//new add
@property double score;

@property(strong,nonatomic)NSData* data;

@property CGRect frame;
#if TARGET_OS_MAC
@property NSRect frame1;
#else
@property CGRect frame1;
#endif

@property CGRect size;
@property CGPoint point;
@end


@interface NSObject(PrintSQL)
+(NSString*)getCreateTableSQL;
@end