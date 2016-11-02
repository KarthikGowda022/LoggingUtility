//
//  ILConfiguration.swift
//  IntuitLogging
//
//  Created by Gowda, Karthik on 9/28/16.
//  Copyright © 2016 Intuit. All rights reserved.
//

import Foundation

public enum LogLevelSpecification {
    
    case atLeveleAndHigher
    case atLevelsOnly
}

public enum ProviderType {
    
    case typeConsole
    case typeRemote
    case typeCustom
}

open class ILConfiguration : NSObject {
    
    open var level:ILLevel = ILLevel.init(withSpec: .atLeveleAndHigher, levels: [ILLogLevel.ILLogLevelDebug])
    
    open var providers:[String:ILProviderConfig]?
    
    open var additionalProps:[String:AnyObject]?
    
    public init(level:ILLevel, providers:[String:ILProviderConfig]?, props:[String:AnyObject]?){
        
        self.level = level
        self.providers = providers
        self.additionalProps = props
    }
    
    open class func configurationFromResourcePath(_ fileName:String, ofType type:String) -> ILConfiguration? {
        
        var result:ILConfiguration?
        
        let path:String? = Bundle.main.path(forResource: fileName, ofType:type)
        
        if path != nil{
            let setttingJson = try? String(contentsOfFile:path!, encoding: String.Encoding.utf8)
            
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
    
    
    
    open class func configurationFromJSON(_ data:String) -> ILConfiguration {
        
        var results:ILConfiguration?
        
        do {
            let cofigDict:[String:AnyObject] = try JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options:.allowFragments) as! [String:AnyObject]
            print("configurationFromJSON = \(cofigDict)")
            
            results = loggingConfigurationFromDictionary(cofigDict)
        } catch {
            print("error: \(error)")
        }
        
        //let resultDict : NSDictionary = try! NSJSONSerialization.JSONObjectWithData(data.dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
        
        return results!
    }
    
    
    open class func loggingConfigurationFromDictionary(_ configDict:[String:AnyObject]) -> ILConfiguration {
        
        var loggingConfig:ILConfiguration
        
        var logLevels = [ILLogLevel]()
        var logLevleSpec:LogLevelSpecification = .atLevelsOnly
        
        if let levels = configDict["levels"] as? [String:AnyObject] {
            
            if let levelsList = levels["AtLevelAndHigher"] as? [String] {
                
                logLevels.append(ILLogLevel.from(levelsList.first!))
                logLevleSpec =  .atLeveleAndHigher
            }
            else if let levelsList = levels["AtLevelAndHigher"] as? String {
                
                logLevels.append(ILLogLevel.from(levelsList))
                logLevleSpec =  .atLeveleAndHigher
            }
            else if let levelsList = levels["AtLevelsOnly"] as? [String] {
                
                for each in levelsList {
                    logLevels.append(ILLogLevel.from(each))
                }
                logLevleSpec =  .atLevelsOnly
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
                    
                    provider = ILProviderConfig.init(withType:.typeConsole, props: value as? [String : AnyObject])
                }
                else if type == "remote" || type == "Remote" {
                    
                    let prop = value["addProps"] as? [String : AnyObject]
                    let endPoint = value["endpoint"] as? [String : AnyObject]
                    let headers = value["headers"] as? [String : String]
                    provider = ILProviderConfig.init(withType: .typeRemote, endpoint: endPoint, headers: headers, props: prop)
                }
                else{
                    provider = ILProviderConfig.init(withType:.typeCustom, props: nil)
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


open class ILLevel{
    
    open var atLevel:LogLevelSpecification
    
    open var levels:[ILLogLevel]
    
    
    public init(withSpec:LogLevelSpecification, levels:[ILLogLevel]){
        
        self.atLevel = withSpec
        self.levels = levels
        
    }
}


open class ILProviderConfig {
    
    open var type:ProviderType
    
    open var addProps:[String:AnyObject]?
    open var endpoint:[String:AnyObject]?
    open var headers:[String:String]?
    
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
