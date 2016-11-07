//
//  ILConsoleLoggingProvider.swift
//  IntuitLogging
//
//  Created by Gowda, Karthik on 9/28/16.
//  Copyright © 2016 Intuit. All rights reserved.
//

import Foundation

class ILConsoleLoggingProvider:NSObject, LoggingProvider {
    
    let name:String
    let config:ILProviderConfig
    
    
    init(WithName name:String, config:ILProviderConfig){
        self.name = name
        self.config = config
        super.init()
    }
    
    init(WithConfigDict config:ILProviderConfig){
        self.name = "No Name"
        self.config = config
        super.init()
    }
    
    func logMessage(message: String, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?){
        
        let mergredProps:[String:AnyObject]? = mergeRuntimPropsWith(props)
        if let propsDic = mergredProps?.count {
            print("\(NSDate()):LoggingUtility - \(message) : \(propsDic)")
        }
        else{
            print("\(NSDate()):LoggingUtility -\(message)")
        }
    }
    
    func logMessage(message: String, withException exc:exception, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?){
        
        let mergredProps:[String:AnyObject]? = mergeRuntimPropsWith(props)
        if let propsDic = mergredProps?.count {
            
            print("\(NSDate()):LoggingUtility -\(message) : \(propsDic)")
        }
        else{
            print("\(NSDate()):LoggingUtility -\(message)")
        }
    }
    
    func logMessage(message: String, withError error:ErrorType, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?){
        
        let mergredProps:[String:AnyObject]? = mergeRuntimPropsWith(props)
        if let propsDic = mergredProps?.count {
            
            print("\(NSDate()):LoggingUtility -\(message) : \(propsDic)")
        }
        else{
            print("\(NSDate()):LoggingUtility -\(message)")
        }
        
    }
    
    func mergeRuntimPropsWith(addProb:[String:AnyObject]?) -> [String:AnyObject] {
        
        var resultProps = [String:AnyObject]()
        
        if let providerProps = self.config.addProps{
            for (key, value) in providerProps {
                resultProps[key] = value
            }
        }
        
        if addProb != nil {
            for (key, value) in addProb! {
                resultProps[key] = value
            }
        }
        
        return resultProps
    }
    
    
}

