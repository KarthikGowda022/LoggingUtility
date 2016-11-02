//
//  ILUtilities.swift
//  IntuitLogging
//
//  Created by Gowda, Karthik on 9/28/16.
//  Copyright © 2016 Intuit. All rights reserved.
//

import Foundation

class ILUtilities {

    class func makeLogLevelOptionFromString(_ levelArray:[String]) -> ILLogLevel{
        
        var value : Int = 0
        for (_, item) in levelArray.enumerated() {
            
            value |= ILLogLevel.from(item).rawValue
        }
        let result  = ILLogLevel.init(rawValue: value)
        
        return result //CULoggingConfig.mapFrom(levelArray.first!)
    }
    
 
    class func makeInclusiveLogLevelOptionFromString(_ levelStr:String) -> ILLogLevel {
        
        let allOptions = ["fatal", "error", "warn", "info", "debug"]
        
        var subArray = [String]()
        
        for (_, item) in allOptions.enumerated() {
            subArray.append(item)
            if item == levelStr {
                break
            }
        }
        
        return ILUtilities.makeLogLevelOptionFromString(subArray)
    }
    
    
}
