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
    
    override var description: String {
        return "address:\(address) postcode:\(postcode)";
    }
}

class LKTestForeign: LKTestForeignSuper {
    var addid:Float = 0
    var testModel:LKTest? = nil
    
    override var description: String {
        let desc = super.description;
        return desc + " addid:\(addid) testModel:\(testModel)";
    }
}

class LKTest: NSObject {
    var address: LKTestForeign?
    var name: String?
    var url: URL?
    var age: Int = 0
    var isGirl: Bool = false
    var blah: NSArray?
    var hoho: NSDictionary?
    var like: u_char = 0
    var img: UIImage?
    var color: UIColor?
    var frame: CGRect = CGRect.zero
    var size: CGSize = CGSize.zero
    var range: NSRange = NSMakeRange(0, 0)
    var point: CGPoint = CGPoint.zero
    
    override static func getPrimaryKey() -> String {
        return "name"
    }
    override static func getTableName() -> String {
        return "LKTestTable"
    }
}
