//
//  AppDelegate.swift
//  Swift-Demo
//
//  Created by ljh on 16/5/31.
//  Copyright © 2016年 ljh. All rights reserved.
//

import UIKit
import LKDBHelper

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITextViewDelegate {

    var window: UIWindow?
    var ms:String = ""
    var tv:UITextView? = nil
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.window?.endEditing(true);
    }
    
    func add(txt:String) -> Void {
        dispatch_async(dispatch_get_main_queue()) {
            self.ms += "\n"
            self.ms += txt
            self.ms += "\n"
            self.tv?.text = self.ms
        }
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        self.window = UIWindow.init(frame: UIScreen.mainScreen().bounds);
        self.window?.rootViewController = UIViewController.init();
        
        var frame = self.window?.bounds;
        frame?.origin.y = 20
        self.tv = UITextView.init(frame: frame!)
        self.tv?.textColor = UIColor.blackColor()
        self.tv?.delegate = self
        self.window?.rootViewController?.view.addSubview(self.tv!);
        self.window?.makeKeyAndVisible()
        
        dispatch_async(dispatch_get_global_queue(0, 0)) { 
            self.test()
        }
        return true
    }
    func test() {
        self.add("示例 开始 example start \n\n")
        let globalHelper = LKTest.getUsingLKDBHelper()
        
        ///删除所有表   delete all table
        globalHelper.dropAllTable()
        
        //清空表数据  clear table data
        LKDBHelper.clearTableData(LKTest)

        //初始化数据模型  init object
        var test = LKTest.init();
        
        test.name = "zhan san"
        test.age = 16
        
        //外键  foreign key
        var foreign = LKTestForeign.init()
        foreign.address = ":asdasdasdsadasdsdas"
        foreign.postcode = 123341
        foreign.addid = 213214
        
        test.address = foreign
        
        test.blah = ["0",[1],["2":2],foreign]
        test.hoho = ["array":test.blah!,"foreign":foreign,"normal":123456,"date":NSDate()]
        
        test.isGirl = true
        
        test.like = 56
        test.img = UIImage.init(named: "Snip20130620_6.png")
        test.color = UIColor.orangeColor()
        //同步 插入第一条 数据   synchronous insert the first
        test.saveToDB()
        
        //更改主键继续插入   Insert the change after the primary key
        test.name = "li si"
        test.saveToDB()
        
        //事物  transaction
        globalHelper.executeForTransaction { (_helper) -> Bool in
            
            test.name = "1"
            var insertSucceed = _helper.insertToDB(test);
            
            test.name = "2"
            insertSucceed = _helper.insertToDB(test);
            
            test.name = "1"
            test.rowid = 0
            insertSucceed = _helper.insertToDB(test);
            
            if insertSucceed == false {
                return false
            }
            else {
                return true
            }
        }
        
        self.add("同步插入 完成!  Insert completed synchronization")
        
        sleep(1);
        
        let searchResultArray = LKTest.searchWithWhere(nil, orderBy: nil, offset: 0, count: 0);
        for obj in searchResultArray {
            self.add(obj.printAllPropertys())
        }
    }
}

