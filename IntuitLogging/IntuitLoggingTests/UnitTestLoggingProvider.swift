//
//  UnitTestLoggingProvider.swift
//  CommonUtilities
//
//  Created by Gowda, Karthik on 8/18/16.
//  Copyright © 2016 Intuit. All rights reserved.
//

import Foundation
import IntuitLogging

class UnitTestLoggingProvider:NSObject, LoggingProvider {
    
    let name:String
    let config:Dictionary<String, AnyObject>
    var history =  [AnyObject]()
    
    init(WithName name:String, config:Dictionary<String, AnyObject>){
        self.name = name
        self.config = config
        super.init()
    }
    
    init(WithConfigDict config:Dictionary<String, AnyObject>){
        self.name = "UnitTestLogger"
        self.config = config
        super.init()
    }
    
    func logMessage(_ message: String, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?){
        
        if let propsDic = props?.count {
            print("\(self.name) - \(message) : \(propsDic)")
        }
        else{
            print("\(self.name) -\(message)")
        }
        
//        let logStr:String = CULogLevel.string(from: logLevel)
//        self.history.append(["message":message, "logLevel":logStr, "props":props!])
        
    }
    
    func logMessage(_ message: String, withException exc:exception, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?){
        
        if let propsDic = props?.count {
            print("\(self.name) - \(message) : \(propsDic)")
        }
        else{
            print("\(self.name) -\(message)")
        }
        
//        let logStr:String = CULogLevel.string(from: logLevel)
//        self.history.append(["message":message, "logLevel":logStr, "props":props!])
    }
    
    func logMessage(_ message: String, withError error:Error, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?){
        
        if let propsDic = props?.count {
            print("\(self.name) - \(message) : \(propsDic)")
        }
        else{
            print("\(self.name) -\(message)")
        }
        
//        let logStr:String = CULogLevel.string(from: logLevel)
//        self.history.append(["message":message, "logLevel":logStr, "props":props!])
    }
    
}

