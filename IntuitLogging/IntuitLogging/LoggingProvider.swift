//
//  LoggingProvider.swift
//  IntuitLogging
//
//  Created by Gowda, Karthik on 9/28/16.
//  Copyright © 2016 Intuit. All rights reserved.
//

import Foundation

public protocol LoggingProvider :NSObjectProtocol {
    
    func logMessage(_ message: String, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?)
    
    func logMessage(_ message: String, withException:exception, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?)
    
    func logMessage(_ message: String, withError:Error, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?)
}
