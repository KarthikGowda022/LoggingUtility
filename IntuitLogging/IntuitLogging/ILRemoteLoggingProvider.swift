//
//  ILRemoteLoggingProvider.swift
//  IntuitLogging
//
//  Created by Gowda, Karthik on 9/28/16.
//  Copyright © 2016 Intuit. All rights reserved.
//

import Foundation

enum ServiceError: ErrorType {
    case NoEndpoint
    case NoConnection
    case Failure
}

enum ParameterError: ErrorType {
    case MissingParameters
    case MissingApplicationID
    case MissingComponentName
}

class ILRemoteLoggingProvider:NSObject, LoggingProvider {
    
    let name:String
    //var config:Dictionary<String, AnyObject>
    var config:ILProviderConfig
    
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
    
    
    func lookupValuefor(key:String, props:[String:AnyObject]) -> String {
        
        var result = ""
        
        if  let substitute = props[key] as? String {
            
            result = substitute
        }
        else if let logLevelDict = props[key] as? [String:AnyObject] {
            
            if  let source = logLevelDict["source"] as? String, mapValue = logLevelDict["mapValues"] as? [String:String] {
                
                let sourceValue = props[source] as! String
                
                var replacedValue = sourceValue
                
                if mapValue[sourceValue] != nil {
                    replacedValue = mapValue[sourceValue]!
                }
                else{
                    let lookUpKey = mapValue["#default"]
                    
                    if let value = lookUpKey as String! where value.containsString("${") {
                        
                        let startIdx = value.rangeOfString("${")!
                        let endIdx = value.rangeOfString("}")!
                        //let range = value.startIndex.advancedBy(2)..<value.endIndex.advancedBy(-1)
                        
                        let range = startIdx.endIndex..<endIdx.startIndex
                        let replaceKey = value.substringWithRange(range)
                        replacedValue = lookupValuefor(replaceKey, props:props)
                        
                    }
                    else {
                        replacedValue = lookUpKey!
                    }
                    
                }
                
                result = replacedValue
            }
        }
        
        return result
    }
    
    func checkForSpecialSymbolsInAddProps(valueDict:[String:AnyObject], props:Dictionary<String,AnyObject>) -> [String:AnyObject] {
        
        var resultsDict = [String:AnyObject]()
        
        for (key, value) in valueDict{
            
            if let value = value as? String {
                
                var substituteValue = value
                
                if value.containsString("${") {
                    
                    let startIdx = value.rangeOfString("${")!
                    let endIdx = value.rangeOfString("}")!
                    //let range = value.startIndex.advancedBy(2)..<value.endIndex.advancedBy(-1)
                    
                    let range = startIdx.endIndex..<endIdx.startIndex
                    let replaceKey = value.substringWithRange(range)
                    let replacementString = lookupValuefor(replaceKey, props:props)
                    
                    if replacementString.characters.count > 0 {
                        let replaceRange = range.startIndex.advancedBy(-2)..<range.endIndex.advancedBy(1)
                        substituteValue.replaceRange(replaceRange, with: replacementString)
                    }
                    
                }
                resultsDict[key] = substituteValue
            }
            else if value is [String:AnyObject] {
                
                resultsDict[key] = checkForSpecialSymbolsInAddProps(value as! [String : AnyObject], props: props)
            }
            
            
        }
        
        return resultsDict
    }
    
    func logRemoteMessage(message: String, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?, error:Any?) throws {
        
        var requestUrl: String = ""
        
        if self.config.endpoint == nil {
            print("No End point URL!!!")
            throw ServiceError.NoEndpoint
        }
        
        let endPointDict:[String:AnyObject]? = checkForSpecialSymbolsInAddProps(self.config.endpoint!, props: props!)
        // print(endPointDict)
        
        if let endPointDict = endPointDict {
            
            //Creating the url
            
            let webProtocol:String = endPointDict["protocol"] as! String
            let host:String = endPointDict["host"] as! String
            
            var port = ""
            if  let portNumber = endPointDict["port"] as? NSNumber {
                
                port = portNumber.stringValue
            }
            else if  let portNumber = endPointDict["port"] as? String {
                
                port = portNumber
            }
            
            let basePath:String = endPointDict["basepath"] as! String
            
            
            if port != "" {
                requestUrl = "\(webProtocol)://\(host):\(port)\(basePath)"
                
            }else{
                requestUrl = "\(webProtocol)://\(host)\(basePath)"
                
            }
            
        }
        else{
            
            print("No End point URL!!!")
            throw ServiceError.NoEndpoint
            
        }
        
        var appId:String? = nil
        
        if self.config.headers != nil {
            
            let parsedHeader = checkForSpecialSymbolsInAddProps(self.config.headers!, props: props!)
            
            appId = parsedHeader["Application-ID"] as? String
            
        }
        
        //let appId:String? = props!["Application-ID"] as? String
        
        if appId == nil {
            throw ParameterError.MissingApplicationID
        }
        
        
        let component:String? = props!["component"] as? String
        
        if component == nil {
            throw ParameterError.MissingComponentName
        }
        
        
        let postData = NSMutableData(data: "appId=\(appId!)".dataUsingEncoding(NSUTF8StringEncoding)!)
        postData.appendData("&component=\(component!)".dataUsingEncoding(NSUTF8StringEncoding)!)
        postData.appendData("&message=\(message)".dataUsingEncoding(NSUTF8StringEncoding)!)
        postData.appendData("&authid=11".dataUsingEncoding(NSUTF8StringEncoding)!)
        postData.appendData("&userid=uuuuu".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        
        let request = NSMutableURLRequest(URL: NSURL(string: requestUrl)!,
                                          cachePolicy: .UseProtocolCachePolicy,
                                          timeoutInterval: 50.0)
        request.HTTPMethod = "POST"
        request.HTTPBody = postData
        
        
        //It is an optional Header
        //        if let headers = self.config["headers"] as? [String:String] {
        //            request.allHTTPHeaderFields = headers
        //        }
        
        let session = NSURLSession.sharedSession()
        let dataTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            if (error != nil) {
                print(NSHTTPURLResponse.localizedStringForStatusCode((error?.code)!))
            } else {
                let httpResponse = response as? NSHTTPURLResponse
                print(httpResponse)
            }
        })
        
        dataTask.resume()
        //sleep(30)
        
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
    
    
    
    func logMessage(message: String, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?){
        
        do{
            let addProps = mergeRuntimPropsWith(props)
            try logRemoteMessage(message, logLevel: logLevel, props: addProps, error:nil)
            
        }
        catch ParameterError.MissingComponentName{
            print("Excetion raised - Component name missing!!!")
        }
        catch ParameterError.MissingApplicationID{
            print("Excetion raised - Application-ID is missing!!!")
        }
        catch ServiceError.NoEndpoint{
            print("Excetion raised - Missing Endpoint")
        }
        catch{
            print("Other exception raised...!!!")
        }
    }
    
    func logMessage(message: String, withException exc:exception, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?){
        
        
        do{
            let addProps = mergeRuntimPropsWith(props)
            try  logRemoteMessage(message, logLevel: logLevel, props: addProps, error:exc)
        }
        catch ParameterError.MissingComponentName{
            print("Excetion raised - Missing ComponentName")
        }
        catch ParameterError.MissingApplicationID{
            print("Excetion raised - Missing ApplicationID")
        }
        catch ServiceError.NoEndpoint{
            print("Excetion raised - Missing Endpoint")
        }
        catch{
            print("Other exception raised...!!!")
        }
        
    }
    
    func logMessage(message: String, withError error:ErrorType, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?){
        
        
        do{
            let addProps = mergeRuntimPropsWith(props)
            try logRemoteMessage(message, logLevel: logLevel, props: addProps, error:error)
        }
        catch ParameterError.MissingComponentName{
            print("Excetion raised - Missing ComponentName")
        }
        catch ParameterError.MissingApplicationID{
            print("Excetion raised - Missing ApplicationID")
        }
        catch ServiceError.NoEndpoint{
            print("Excetion raised - Missing Endpoint")
        }
        catch{
            print("Other exception raised...!!!")
        }
        
    }
}