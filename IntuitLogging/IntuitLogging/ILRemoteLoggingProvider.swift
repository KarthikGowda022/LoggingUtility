//
//  ILRemoteLoggingProvider.swift
//  IntuitLogging
//
//  Created by Gowda, Karthik on 9/28/16.
//  Copyright © 2016 Intuit. All rights reserved.
//

import Foundation

enum ServiceError: Error {
    case noEndpoint
    case noConnection
    case failure
}

enum ParameterError: Error {
    case missingParameters
    case missingApplicationID
    case missingComponentName
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
    
    
    func lookupValuefor(_ key:String, props:[String:AnyObject]) -> String {
        
        var result = ""
        
        if  let substitute = props[key] as? String {
            
            result = substitute
        }
        else if let logLevelDict = props[key] as? [String:AnyObject] {
            
            if  let source = logLevelDict["source"] as? String, let mapValue = logLevelDict["mapValues"] as? [String:String] {
                
                let sourceValue = props[source] as! String
                
                var replacedValue = sourceValue
                
                if mapValue[sourceValue] != nil {
                    replacedValue = mapValue[sourceValue]!
                }
                else{
                    let lookUpKey = mapValue["#default"]
                    
                    if let value = lookUpKey as String! , value.contains("${") {
                        
                        let startIdx = value.range(of: "${")!
                        let endIdx = value.range(of: "}")!
                        //let range = value.startIndex.advancedBy(2)..<value.endIndex.advancedBy(-1)
                        
                        let range = startIdx.upperBound..<endIdx.lowerBound
                        let replaceKey = value.substring(with: range)
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
    
    func checkForSpecialSymbolsInAddProps(_ valueDict:[String:AnyObject], props:Dictionary<String,AnyObject>) -> [String:AnyObject] {
        
        var resultsDict = [String:AnyObject]()
        
        for (key, value) in valueDict{
            
            if let value = value as? String {
                
                var substituteValue:String = value
                
                if value.contains("${") {
                    
                    let startIdx = value.range(of: "${")!
                    let endIdx = value.range(of: "}")!
                    //let range = value.startIndex.advancedBy(2)..<value.endIndex.advancedBy(-1)
                    
                    let range = startIdx.upperBound..<endIdx.lowerBound
                    let replaceKey = value.substring(with: range)
                    let replacementString = lookupValuefor(replaceKey, props:props)
                    
                    if replacementString.characters.count > 0 {

                         let replaceRange =  startIdx.lowerBound..<endIdx.upperBound //value.index(startIdx.lowerBound, offsetBy: replaceKey.characters.count)

                        substituteValue = substituteValue.replacingCharacters(in: replaceRange, with: replacementString)

                    }
                    
                }
                resultsDict[key] = substituteValue as AnyObject?
            }
            else if value is [String:AnyObject] {
                
                resultsDict[key] = checkForSpecialSymbolsInAddProps(value as! [String : AnyObject], props: props) as AnyObject?
            }
            
            
        }
        
        return resultsDict
    }
    
    func logRemoteMessage(_ message: String, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?, error:Any?) throws {
        
        var requestUrl: String = ""
        
        if self.config.endpoint == nil {
            print("No End point URL!!!")
            throw ServiceError.noEndpoint
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
            throw ServiceError.noEndpoint
            
        }
        
        var appId:String? = nil
        
        if self.config.headers != nil {
            
            let parsedHeader = checkForSpecialSymbolsInAddProps(self.config.headers! as [String : AnyObject], props: props!)
            
            appId = parsedHeader["Application-ID"] as? String
            
        }
        
        //let appId:String? = props!["Application-ID"] as? String
        
        if appId == nil {
            throw ParameterError.missingApplicationID
        }
        
        
        let component:String? = props!["component"] as? String
        
        if component == nil {
            throw ParameterError.missingComponentName
        }
        
        
        var postData = NSData(data: "appId=\(appId!)".data(using: String.Encoding.utf8)!) as Data
        postData.append("&component=\(component!)".data(using: String.Encoding.utf8)!)
        postData.append("&message=\(message)".data(using: String.Encoding.utf8)!)
        postData.append("&authid=11".data(using: String.Encoding.utf8)!)
        postData.append("&userid=uuuuu".data(using: String.Encoding.utf8)!)
        
        
        var request = URLRequest(url: URL(string: requestUrl)!,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10)
        request.httpMethod = "POST"
        request.httpBody = postData
        
        
        //It is an optional Header
        //        if let headers = self.config["headers"] as? [String:String] {
        //            request.allHTTPHeaderFields = headers
        //        }
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            
            if (error != nil) {
                 print(error!.localizedDescription)
            } else {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse)
            }
        })
        
        dataTask.resume()
        //sleep(30)
        
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
    
    
    
    func logMessage(_ message: String, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?){
        
        do{
            let addProps = mergeRuntimPropsWith(props)
            try logRemoteMessage(message, logLevel: logLevel, props: addProps, error:nil)
            
        }
        catch ParameterError.missingComponentName{
            print("Excetion raised - Component name missing!!!")
        }
        catch ParameterError.missingApplicationID{
            print("Excetion raised - Application-ID is missing!!!")
        }
        catch ServiceError.noEndpoint{
            print("Excetion raised - Missing Endpoint")
        }
        catch{
            print("Other exception raised...!!!")
        }
    }
    
    func logMessage(_ message: String, withException exc:exception, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?){
        
        
        do{
            let addProps = mergeRuntimPropsWith(props)
            try  logRemoteMessage(message, logLevel: logLevel, props: addProps, error:exc)
        }
        catch ParameterError.missingComponentName{
            print("Excetion raised - Missing ComponentName")
        }
        catch ParameterError.missingApplicationID{
            print("Excetion raised - Missing ApplicationID")
        }
        catch ServiceError.noEndpoint{
            print("Excetion raised - Missing Endpoint")
        }
        catch{
            print("Other exception raised...!!!")
        }
        
    }
    
    func logMessage(_ message: String, withError error:Error, logLevel:ILLogLevel, props:Dictionary<String,AnyObject>?){
        
        
        do{
            let addProps = mergeRuntimPropsWith(props)
            try logRemoteMessage(message, logLevel: logLevel, props: addProps, error:error)
        }
        catch ParameterError.missingComponentName{
            print("Excetion raised - Missing ComponentName")
        }
        catch ParameterError.missingApplicationID{
            print("Excetion raised - Missing ApplicationID")
        }
        catch ServiceError.noEndpoint{
            print("Excetion raised - Missing Endpoint")
        }
        catch{
            print("Other exception raised...!!!")
        }
        
    }
}
