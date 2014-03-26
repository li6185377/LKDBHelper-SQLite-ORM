//
//  LKAppDelegate.h
//  LKDB-Demo
//
//  Created by ljh on 14-3-26.
//  Copyright (c) 2014年 LJH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LKAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end
