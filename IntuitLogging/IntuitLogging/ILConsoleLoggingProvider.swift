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
    
    func logMessage(_ message: String, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?){
        
        let mergredProps:[String:AnyObject]? = mergeRuntimPropsWith(props)
        if let propsDic = mergredProps?.count {
            print("\(Date()):LoggingUtility - \(message) : \(propsDic)")
        }
        else{
            print("\(Date()):LoggingUtility -\(message)")
        }
    }
    
    func logMessage(_ message: String, withException exc:exception, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?){
        
        let mergredProps:[String:AnyObject]? = mergeRuntimPropsWith(props)
        if let propsDic = mergredProps?.count {
            
            print("\(Date()):LoggingUtility -\(message) : \(propsDic)")
        }
        else{
            print("\(Date()):LoggingUtility -\(message)")
        }
    }
    
    func logMessage(_ message: String, withError error:Error, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?){
        
        let mergredProps:[String:AnyObject]? = mergeRuntimPropsWith(props)
        if let propsDic = mergredProps?.count {
            
            print("\(Date()):LoggingUtility -\(message) : \(propsDic)")
        }
        else{
            print("\(Date()):LoggingUtility -\(message)")
        }
        
    }
    
    func mergeRuntimPropsWith(_ addProb:[String:AnyObject]?) -> [String:AnyObject] {
        
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

