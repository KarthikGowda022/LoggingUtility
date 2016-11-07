//
//  ILConfiguration.swift
//  IntuitLogging
//
//  Created by Gowda, Karthik on 9/28/16.
//  Copyright © 2016 Intuit. All rights reserved.
//

import Foundation

public enum LogLevelSpecification {
    
    case AtLeveleAndHigher
    case AtLevelsOnly
}

public enum ProviderType {
    
    case TypeConsole
    case TypeRemote
    case TypeCustom
}

public class ILConfiguration : NSObject {
    
    public var level:ILLevel = ILLevel.init(withSpec: .AtLeveleAndHigher, levels: [ILLogLevel.ILLogLevelDebug])
    
    public var providers:[String:ILProviderConfig]?
    
    public var additionalProps:[String:AnyObject]?
    
    public init(level:ILLevel, providers:[String:ILProviderConfig]?, props:[String:AnyObject]?){
        
        self.level = level
        self.providers = providers
        self.additionalProps = props
    }
    
    public class func configurationFromResourcePath(fileName:String, ofType type:String) -> ILConfiguration? {
        
        var result:ILConfiguration?
        
        let path:String? = NSBundle.mainBundle().pathForResource(fileName, ofType:type)
        
        if path != nil{
            let setttingJson = try? String(contentsOfFile:path!, encoding: NSUTF8StringEncoding)
            
            if (setttingJson != nil ){
                result = configurationFromJSON(setttingJson!)
            }
            else{
                print("Couldn't read \(fileName).\(type) config file at path \(path)")
            }
        }
        else{
            print("Couldn't read \(fileName).\(type) config file")
            
        }
        
        return result
    }
    
    
    
    public class func configurationFromJSON(data:String) -> ILConfiguration {
        
        var results:ILConfiguration?
        
        do {
            let cofigDict:[String:AnyObject] = try NSJSONSerialization.JSONObjectWithData(data.dataUsingEncoding(NSUTF8StringEncoding)!, options:.AllowFragments) as! [String:AnyObject]
            print("configurationFromJSON = \(cofigDict)")
            
            results = loggingConfigurationFromDictionary(cofigDict)
        } catch {
            print("error: \(error)")
        }
        
        //let resultDict : NSDictionary = try! NSJSONSerialization.JSONObjectWithData(data.dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
        
        return results!
    }
    
    
    public class func loggingConfigurationFromDictionary(configDict:[String:AnyObject]) -> ILConfiguration {
        
        var loggingConfig:ILConfiguration
        
        var logLevels = [ILLogLevel]()
        var logLevleSpec:LogLevelSpecification = .AtLevelsOnly
        
        if let levels = configDict["levels"] as? [String:AnyObject] {
            
            if let levelsList = levels["AtLevelAndHigher"] as? [String] {
                
                logLevels.append(ILLogLevel.from(levelsList.first!))
                logLevleSpec =  .AtLeveleAndHigher
            }
            else if let levelsList = levels["AtLevelAndHigher"] as? String {
                
                logLevels.append(ILLogLevel.from(levelsList))
                logLevleSpec =  .AtLeveleAndHigher
            }
            else if let levelsList = levels["AtLevelsOnly"] as? [String] {
                
                for each in levelsList {
                    logLevels.append(ILLogLevel.from(each))
                }
                logLevleSpec =  .AtLevelsOnly
            }
            else{
                print("Parsing Erorr.!!!")
            }
        }
        else{
            print("Parsing Erorr.!!!")
        }
        
        var providers = [String:ILProviderConfig]()
        
        if let providerList = configDict["providers"] as? [String:AnyObject] {
            
            for (key, value) in providerList{
                
                let type = value["type"] as! String
                
                var provider:ILProviderConfig
                if type == "local" || type == "Local" {
                    
                    provider = ILProviderConfig.init(withType:.TypeConsole, props: value as? [String : AnyObject])
                }
                else if type == "remote" || type == "Remote" {
                    
                    let prop = value["addProps"] as? [String : AnyObject]
                    let endPoint = value["endpoint"] as? [String : AnyObject]
                    let headers = value["headers"] as? [String : String]
                    provider = ILProviderConfig.init(withType: .TypeRemote, endpoint: endPoint, headers: headers, props: prop)
                }
                else{
                    provider = ILProviderConfig.init(withType:.TypeCustom, props: nil)
                }
                providers[key] = provider
            }
            
        }
        
        let addProps = configDict["addProps"] as? [String:AnyObject]
        
        let levelConfig = ILLevel.init(withSpec: logLevleSpec, levels: logLevels)
        loggingConfig = ILConfiguration.init(level: levelConfig, providers: providers, props: addProps)
        
        
        return loggingConfig
    }

}


public class ILLevel{
    
    public var atLevel:LogLevelSpecification
    
    public var levels:[ILLogLevel]
    
    
    public init(withSpec:LogLevelSpecification, levels:[ILLogLevel]){
        
        self.atLevel = withSpec
        self.levels = levels
        
    }
}


public class ILProviderConfig {
    
    public var type:ProviderType
    
    public var addProps:[String:AnyObject]?
    public var endpoint:[String:AnyObject]?
    public var headers:[String:String]?
    
    public init(withType:ProviderType, props:[String:AnyObject]?){
        
        self.type = withType
        self.addProps = props
    }
    
    public init(withType:ProviderType, endpoint:[String:AnyObject]?, headers:[String:String]?, props:[String:AnyObject]?){
        
        self.type = withType
        self.addProps = props
        self.endpoint = endpoint
        self.headers = headers
    }
}
