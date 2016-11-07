//
//  LoggingProvider.swift
//  IntuitLogging
//
//  Created by Gowda, Karthik on 9/28/16.
//  Copyright © 2016 Intuit. All rights reserved.
//

import Foundation

public protocol LoggingProvider :NSObjectProtocol {
    
    func logMessage(message: String, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?)
    
    func logMessage(message: String, withException:exception, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?)
    
    func logMessage(message: String, withError:ErrorType, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?)
}