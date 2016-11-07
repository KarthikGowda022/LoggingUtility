//
//  IntuitLogging.swift
//  IntuitLogging
//
//  Created by Gowda, Karthik on 9/27/16.
//  Copyright © 2016 Intuit. All rights reserved.
//

import Foundation

public struct ILLogLevel : OptionSetType {
    
    public let rawValue: Int
    
    public init(rawValue:Int) {
        self.rawValue = rawValue
    }
    
    public static let ILLogLevelNone     = ILLogLevel(rawValue:0)
    public static let ILLogLevelDebug    = ILLogLevel(rawValue:1 << 1)
    public static let ILLogLevelInfo     = ILLogLevel(rawValue:1 << 2)
    public static let ILLogLevelWarn     = ILLogLevel(rawValue:1 << 3)
    public static let ILLogLevelError    = ILLogLevel(rawValue:1 << 4)
    public static let ILLogLevelFatal    = ILLogLevel(rawValue:1 << 5)
    
}

extension ILLogLevel {
    
    //Mapping String -> Enum
    static func from(string:String) -> ILLogLevel {
        
        var result:ILLogLevel = ILLogLevel.ILLogLevelNone
        
        if string == "debug" {
            result = ILLogLevel.ILLogLevelDebug
        }
        else if string == "info" {
            result = ILLogLevel.ILLogLevelInfo
        }
        else if string == "warn" {
            result = ILLogLevel.ILLogLevelWarn
        }
        else if string == "error" {
            result = ILLogLevel.ILLogLevelError
        }
        else if string == "fatal" {
            result = ILLogLevel.ILLogLevelFatal
        }
        
        return result
    }
    
    static func string(from level:ILLogLevel) -> String{
        
        var result:String = ""
        
        if level == .ILLogLevelDebug {
            result = "debug"
        }
        else if level == .ILLogLevelInfo {
            result = "info"
        }
        else if level == .ILLogLevelWarn {
            result = "warn"
        }
        else if level == .ILLogLevelError {
            result = "error"
        }
        else if level == .ILLogLevelFatal {
            result = "fatal"
        }
        
        return result
        
    }
}

public enum LoggerType : UInt {
    case CULoggerTypeConsole    = 0x00000
    case CULoggerTypeRemote     = 0x00001
}

public class IntuitLogging: NSObject {
    
    public var activeLogLevels : ILLogLevel = ILLogLevel.ILLogLevelError
    public var runtimeProps = [String:AnyObject]()
    
    var providers = NSMutableOrderedSet()
    var config:ILConfiguration?
    
    
    override init() {
        self.activeLogLevels =  [ILLogLevel.ILLogLevelWarn, ILLogLevel.ILLogLevelError, ILLogLevel.ILLogLevelFatal]
        
        let consoleProviderConfig = ILProviderConfig.init(withType: ProviderType.TypeConsole, props: nil)
        self.providers.addObject(ILConsoleLoggingProvider.init(WithConfigDict:consoleProviderConfig))
        
    }
    
    convenience init(WithConfigDict config:ILConfiguration) {
        self.init()
        setConfig(WithConfigDict: config)
    }
    
    
    public class func sharedInstance(config:ILConfiguration?) -> IntuitLogging {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: IntuitLogging? = nil
        }
        dispatch_once(&Static.onceToken) {
            
            if config != nil {
                Static.instance = IntuitLogging.init(WithConfigDict: config!)
                
            }else{
                //Default configuration (Console logger only, with logLevel set to 'warn' and above)
                Static.instance = IntuitLogging.init()
            }
            
        }
        return Static.instance!
    }
    
    public func setConfig(WithConfigDict config:ILConfiguration?) {
        
        //Don't modify the defaults.!!!
        if config == nil {
            return
        }
        
        if self.providers.count > 0 {
            self.providers.removeAllObjects()
        }
        
        let settings:ILConfiguration = config!

        
        self.config = settings
        let logLevels:ILLevel = settings.level
        
        
        var logLevelString = [String]()
        for element in logLevels.levels
        {
            logLevelString.append(ILLogLevel.string(from: element))
        }
        
        if logLevels.atLevel == LogLevelSpecification.AtLeveleAndHigher {
            
            let logLeveStr:String = logLevelString.first!
            self.activeLogLevels = ILUtilities.makeInclusiveLogLevelOptionFromString(logLeveStr)
        }
        else if logLevels.atLevel == LogLevelSpecification.AtLevelsOnly {
            
            self.activeLogLevels = ILUtilities.makeLogLevelOptionFromString(logLevelString)
        }
        
        
        //Initialize providers
        if let providerDict:Dictionary<String, ILProviderConfig> = settings.providers{
            
            for (_,  element) in providerDict.enumerate() {
                
                let loggerObj:AnyObject? = IntuitLogging.makeProvider(element.0, provider: element.1)
                
                if loggerObj != nil{
                    self.providers.addObject(loggerObj!)
                }
                else{
                    print("Failed to initialize provider \(element.0)")
                }
            }
        }
        
        //Store the 'addProps'
        if let runProps =  config?.additionalProps {
            self.runtimeProps = runProps
        }
        
    }
    
    
    class func makeProvider(name:String, provider:ILProviderConfig)-> AnyObject? {
        
        var result:AnyObject?
        
        
        if provider.type == ProviderType.TypeConsole {
            result = ILConsoleLoggingProvider.init(WithName: name, config: provider)
        }
        else if provider.type == ProviderType.TypeRemote {
            result = ILRemoteLoggingProvider.init(WithName: name, config: provider)
        }
        
        return result
    }
    
    
    func log(message:String, logLevel:ILLogLevel, props:Dictionary<String, AnyObject>?, error:Any?) {
        
        let shouldLog: Bool = ((self.activeLogLevels.rawValue & logLevel.rawValue) == logLevel.rawValue) ? true : false
        
        if shouldLog {
            
            for provider in self.providers {
                
                if let providerObj = provider as? LoggingProvider {
                    
                    var addProps = mergeRuntimPropsWith(props)
                    addProps["loglevel"] = ILLogLevel.string(from: logLevel)
                    
                    if (error != nil && error is exception){
                        
                        providerObj.logMessage(message, withException: error as! exception, logLevel: logLevel, props:addProps)
                    }
                    else if (error != nil && error is ErrorType){
                        
                        providerObj.logMessage(message, withError: error as! ErrorType, logLevel: logLevel, props: addProps)
                    }
                    else{
                        
                        providerObj.logMessage(message, logLevel: logLevel, props: addProps)
                    }
                }
            }
        }
        
    }
    
    
    
    func mergeRuntimPropsWith(addProb:[String:AnyObject]?) -> [String:AnyObject] {
        
        var resultProps = [String:AnyObject]()
        
        for (key, value) in self.runtimeProps {
            resultProps[key] = value
        }
        
        if addProb != nil {
            for (key, value) in addProb! {
                resultProps[key] = value
            }
        }
        
        return resultProps
    }
    
    
    // Public methods
    
    public func addProvider(logProvider:LoggingProvider) {
        
        self.providers.addObject(logProvider)
    }
    
    
    public func removeProvider(logProvider:LoggingProvider) {
        
        self.providers.removeObject(logProvider)
    }
    
    
    public func debug(message:String, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelDebug, props: props, error: nil)
    }
    
    public func info(message:String, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelInfo, props: props, error: nil)
    }
    
    public func warn(message:String, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelWarn, props: props, error: nil)
    }
    
    public func error(message:String, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelError, props: props, error: nil)
    }
    
    public func fatal(message:String, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelFatal, props: props, error: nil)
    }
    
    //With Exceptions
    public func debug(message:String, withException:exception, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelDebug, props: props, error: withException)
    }
    
    public func info(message:String, withException:exception, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelInfo, props: props, error: withException)
    }
    
    public func warn(message:String, withException:exception, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelWarn, props: props, error: withException)
    }
    
    public func error(message:String, withException:exception, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelError, props: props, error: withException)
    }
    
    public func fatal(message:String, withException:exception, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelFatal, props: props, error: withException)
    }
    
    //With ErrorType
    public func debug(message:String, withError:ErrorType, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelDebug, props: props, error: withError)
    }
    
    public func info(message:String, withError:ErrorType, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelInfo, props: props, error: withError)
    }
    
    public func warn(message:String, withError:ErrorType, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelWarn, props: props, error: withError)
    }
    
    public func error(message:String, withError:ErrorType, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelError, props: props, error: withError)
    }
    
    public func fatal(message:String, withError:ErrorType, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelFatal, props: props, error: withError)
    }
    
}
