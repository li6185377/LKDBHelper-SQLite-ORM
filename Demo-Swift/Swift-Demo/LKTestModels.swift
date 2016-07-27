//
//  LKTestModels.swift
//  Swift-Demo
//
//  Created by ljh on 16/5/31.
//  Copyright © 2016年 ljh. All rights reserved.
//

import UIKit
import LKDBHelper

class LKTestForeignSuper: NSObject {
    var address:NSString? = nil
    var postcode:Int = 0
}

class LKTestForeign: LKTestForeignSuper {
    var addid:Int = 0
    var testModel:LKTest? = nil
}

class LKTest: NSObject {
    var address:LKTestForeign?
    var name:NSString?
    var url:NSURL?
    var age:Int = 0
    var isGirl:Bool = false
    var blah: NSArray?
    var hoho:NSDictionary?
    var like:u_char = 0
    var img:UIImage?
    var color:UIColor?
    var frame:CGRect = CGRectZero
    var size:CGSize = CGSizeZero
    var range:NSRange = NSMakeRange(0, 0)
    var point:CGPoint = CGPointZero
    
    override static func getPrimaryKey() -> String {
        return "name"
    }
    override static func getTableName() -> String {
        return "LKTestTable"
    }
}