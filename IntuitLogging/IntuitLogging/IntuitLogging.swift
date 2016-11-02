//
//  IntuitLogging.swift
//  IntuitLogging
//
//  Created by Gowda, Karthik on 9/27/16.
//  Copyright © 2016 Intuit. All rights reserved.
//

import Foundation

public struct ILLogLevel : OptionSet {
    
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
    static func from(_ string:String) -> ILLogLevel {
        
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
    case cuLoggerTypeConsole    = 0x00000
    case cuLoggerTypeRemote     = 0x00001
}

open class IntuitLogging: NSObject {

    
    open var activeLogLevels : ILLogLevel = ILLogLevel.ILLogLevelError
    open var runtimeProps = [String:AnyObject]()
    
    var providers = NSMutableOrderedSet()
    var config:ILConfiguration?
    
    
    override init() {
        self.activeLogLevels =  [ILLogLevel.ILLogLevelWarn, ILLogLevel.ILLogLevelError, ILLogLevel.ILLogLevelFatal]
        
        let consoleProviderConfig = ILProviderConfig.init(withType: ProviderType.typeConsole, props: nil)
        self.providers.add(ILConsoleLoggingProvider.init(WithConfigDict:consoleProviderConfig))
        
    }
    
    convenience init(WithConfigDict config:ILConfiguration) {
        self.init()
        setConfig(WithConfigDict: config)
    }
    
    open static var sharedInstance: IntuitLogging = IntuitLogging()
    
    open func initialize(WithConfig config:ILConfiguration?) {
        
        if config != nil {
            setConfig(WithConfigDict: config!)
        }
    }
    
    open func setConfig(WithConfigDict config:ILConfiguration?) {
        
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
        
        if logLevels.atLevel == LogLevelSpecification.atLeveleAndHigher {
            
            let logLeveStr:String = logLevelString.first!
            self.activeLogLevels = ILUtilities.makeInclusiveLogLevelOptionFromString(logLeveStr)
        }
        else if logLevels.atLevel == LogLevelSpecification.atLevelsOnly {
            
            self.activeLogLevels = ILUtilities.makeLogLevelOptionFromString(logLevelString)
        }
        
        
        //Initialize providers
        if let providerDict:Dictionary<String, ILProviderConfig> = settings.providers{
            
            for (_,  element) in providerDict.enumerated() {
                
                let loggerObj:AnyObject? = IntuitLogging.makeProvider(element.0, provider: element.1)
                
                if loggerObj != nil{
                    self.providers.add(loggerObj!)
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
    
    
    class func makeProvider(_ name:String, provider:ILProviderConfig)-> AnyObject? {
        
        var result:AnyObject?
        
        
        if provider.type == ProviderType.typeConsole {
            result = ILConsoleLoggingProvider.init(WithName: name, config: provider)
        }
        else if provider.type == ProviderType.typeRemote {
            result = ILRemoteLoggingProvider.init(WithName: name, config: provider)
        }
        
        return result
    }
    
    
    func log(_ message:String, logLevel:ILLogLevel, props:Dictionary<String, AnyObject>?, error:Any?) {
        
        let shouldLog: Bool = ((self.activeLogLevels.rawValue & logLevel.rawValue) == logLevel.rawValue) ? true : false
        
        if shouldLog {
            
            for provider in self.providers {
                
                if let providerObj = provider as? LoggingProvider {
                    
                    var addProps = mergeRuntimPropsWith(props)
                    addProps["loglevel"] = ILLogLevel.string(from: logLevel) as AnyObject?
                    
                    if (error != nil && error is exception){
                        
                        providerObj.logMessage(message, withException: error as! exception, logLevel: logLevel, props:addProps)
                    }
                    else if (error != nil && error is Error){
                        
                        providerObj.logMessage(message, withError: error as! Error, logLevel: logLevel, props: addProps)
                    }
                    else{
                        
                        providerObj.logMessage(message, logLevel: logLevel, props: addProps)
                    }
                }
            }
        }
        
    }
    
    
    
    func mergeRuntimPropsWith(_ addProb:[String:AnyObject]?) -> [String:AnyObject] {
        
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
    
    open func addProvider(_ logProvider:LoggingProvider) {
        
        self.providers.add(logProvider)
    }
    
    
    open func removeProvider(_ logProvider:LoggingProvider) {
        
        self.providers.remove(logProvider)
    }
    
    
    open func debug(_ message:String, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelDebug, props: props, error: nil)
    }
    
    open func info(_ message:String, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelInfo, props: props, error: nil)
    }
    
    open func warn(_ message:String, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelWarn, props: props, error: nil)
    }
    
    open func error(_ message:String, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelError, props: props, error: nil)
    }
    
    open func fatal(_ message:String, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelFatal, props: props, error: nil)
    }
    
    //With Exceptions
    open func debug(_ message:String, withException:exception, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelDebug, props: props, error: withException)
    }
    
    open func info(_ message:String, withException:exception, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelInfo, props: props, error: withException)
    }
    
    open func warn(_ message:String, withException:exception, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelWarn, props: props, error: withException)
    }
    
    open func error(_ message:String, withException:exception, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelError, props: props, error: withException)
    }
    
    open func fatal(_ message:String, withException:exception, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelFatal, props: props, error: withException)
    }
    
    //With ErrorType
    open func debug(_ message:String, withError:Error, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelDebug, props: props, error: withError)
    }
    
    open func info(_ message:String, withError:Error, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelInfo, props: props, error: withError)
    }
    
    open func warn(_ message:String, withError:Error, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelWarn, props: props, error: withError)
    }
    
    open func error(_ message:String, withError:Error, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelError, props: props, error: withError)
    }
    
    open func fatal(_ message:String, withError:Error, props:Dictionary<String, AnyObject>?) {
        
        log(message, logLevel: ILLogLevel.ILLogLevelFatal, props: props, error: withError)
    }
    
}
