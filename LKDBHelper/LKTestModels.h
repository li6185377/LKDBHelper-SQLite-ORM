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
@property(copy,nonatomic)UIColor* color;
@end


@interface NSObject(PrintSQL)
+(NSString*)getCreateTableSQL;
@end