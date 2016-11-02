//
//  IntuitLoggingTests.swift
//  IntuitLoggingTests
//
//  Created by Gowda, Karthik on 9/27/16.
//  Copyright © 2016 Intuit. All rights reserved.
//

import XCTest
@testable import IntuitLogging

class IntuitLoggingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testBasicLoggerInstantiation(){
        
        
        let configDict:Dictionary<String, AnyObject> = configurationDictionary()
        
        let loggingConfig = ILConfiguration.loggingConfigurationFromDictionary(configDict)
        
        let loggingA = IntuitLogging.sharedInstance(loggingConfig)
        loggingA.setConfig(WithConfigDict: loggingConfig)
        
        let defualLogLevel:ILLogLevel = ILLogLevel(rawValue: ILLogLevel.ILLogLevelWarn.rawValue | ILLogLevel.ILLogLevelError.rawValue | ILLogLevel.ILLogLevelFatal.rawValue)
        
        XCTAssertEqual(loggingA.activeLogLevels, defualLogLevel, "Active Levels should include Warn, Error, Fatal by default.")
        
        let excludeInfo:ILLogLevel = ILLogLevel(rawValue: defualLogLevel.rawValue & ILLogLevel.ILLogLevelInfo.rawValue)
        let excludeDebug:ILLogLevel = ILLogLevel(rawValue: defualLogLevel.rawValue & ILLogLevel.ILLogLevelDebug.rawValue)
        
        XCTAssertNotEqual(loggingA.activeLogLevels, excludeInfo, "Active Levels should NOT include Warn, Error, Fatal by default.")
        XCTAssertNotEqual(loggingA.activeLogLevels, excludeDebug, "Active Levels should NOT include Debug, Error, Fatal by default.")
        
        
        let includeError:ILLogLevel = ILLogLevel(rawValue: defualLogLevel.rawValue & ILLogLevel.ILLogLevelError.rawValue)
        let includeWarn:ILLogLevel = ILLogLevel(rawValue: defualLogLevel.rawValue & ILLogLevel.ILLogLevelWarn.rawValue)
        let includeFatal:ILLogLevel = ILLogLevel(rawValue: defualLogLevel.rawValue & ILLogLevel.ILLogLevelFatal.rawValue)
        
        XCTAssertEqual(ILLogLevel.ILLogLevelError.rawValue, includeError.rawValue, "Active Levels should be include Warn, Error, Fatal by default.")
        XCTAssertEqual(ILLogLevel.ILLogLevelWarn.rawValue, includeWarn.rawValue, "Active Levels should be include Debug, Error, Fatal by default.")
        XCTAssertEqual(ILLogLevel.ILLogLevelFatal.rawValue, includeFatal.rawValue, "Active Levels should be include Debug, Error, Fatal by default.")
        
    }
    
    func testProviderListManagement() {
        
        let configDict:Dictionary<String, AnyObject> = configurationDictionary()
        let loggingConfig = ILConfiguration.loggingConfigurationFromDictionary(configDict)
        let logging = IntuitLogging.sharedInstance(nil)
        logging.setConfig(WithConfigDict: loggingConfig)
        let providerCount = logging.providers.count
        
        let UTLogger = UnitTestLoggingProvider.init(WithConfigDict: [:])
        logging.addProvider(UTLogger)
        
        XCTAssertEqual( logging.providers.count, providerCount+1, "AddProvider should add a provider");
        XCTAssertNotEqual(logging.providers.index(of: UTLogger), NSNotFound, "AddProvider to add correct provider");
        
        logging.removeProvider(UTLogger)
        XCTAssertEqual( logging.providers.count, providerCount, "removeProvider should remove a provider");
        XCTAssertEqual(logging.providers.index(of: UTLogger), NSNotFound, "removeProvider to remove correct provider");
    }
    
    func testLoggingLevels() {
        
        let loggingConfig = ILConfiguration.loggingConfigurationFromDictionary(configurationWithRemoteLogging())
        let loggerObj = IntuitLogging.sharedInstance(loggingConfig)
        loggerObj.setConfig(WithConfigDict: loggingConfig)
        
        loggerObj.runtimeProps["extraProbs"] = "Test Value"
        //To be ignored
        loggerObj.debug("This is Debugggggggggggggg message!!!!", props: additionalProps())
        loggerObj.info("This is infoooooooooooooooo message!!!!", props: additionalProps())
        
        //To be logged
        loggerObj.warn("This is Warninggggggggggggg message!!!!", props: additionalProps())
        loggerObj.error("This is Errorrrrrrrrrrrrrr message!!!!", props: additionalProps())
        loggerObj.fatal("This is Fatal errorrrrrrrr message!!!!", props: additionalProps())
        
        //XCTAssertEqual(UTLogger.history.count, 3, "Shouldn't log debug and info")
        
        //With Exceptioins
        let exceptionVar = exception.init()
        //To be ignored
        loggerObj.debug("This is Debugggggggggggggg message!!!!", withException: exceptionVar, props:additionalProps())
        loggerObj.info("This is infoooooooooooooooo message!!!!", withException:exceptionVar, props: additionalProps())
        
        //To be logged
        loggerObj.warn("This is Warninggggggggggggg message!!!!", withException:exceptionVar, props: additionalProps())
        loggerObj.error("This is Errorrrrrrrrrrrrrr message!!!!", withException:exceptionVar, props: additionalProps())
        loggerObj.fatal("This is Fatal errorrrrrrrr message!!!!", withException:exceptionVar, props: additionalProps())
        
        
        //With Errors
        //To be ignored
        loggerObj.debug("This is Debugggggggggggggg message!!!!", withError:ServiceError.noEndpoint, props:additionalProps())
        loggerObj.info("This is infoooooooooooooooo message!!!!", withError:ServiceError.noEndpoint, props: additionalProps())
        
        //To be logged
        loggerObj.warn("This is Warninggggggggggggg message!!!!",  withError:ServiceError.noEndpoint, props: additionalProps())
        loggerObj.error("This is Errorrrrrrrrrrrrrr message!!!!",  withError:ServiceError.noEndpoint, props: additionalProps())
        loggerObj.fatal("This is Fatal errorrrrrrrr message!!!!",  withError:ServiceError.noEndpoint, props: additionalProps())
    }

    
    func testConfigurationFromBundleLogLevelsExplicit() {
        
        
        let settings = ILConfiguration.configurationFromJSON("{ \"levels\":{ \"AtLevelsOnly\": [\"info\",\"error\"] }}")
        print(settings);
        XCTAssertNotNil(settings, "JSON config should be valid");
        let loggerObj = IntuitLogging.sharedInstance(nil)
        loggerObj.setConfig(WithConfigDict: settings)
        
        //Assert that logging.providers has  correct activelevels
        let activeLogLevel:ILLogLevel = ILLogLevel(rawValue: ILLogLevel.ILLogLevelInfo.rawValue | ILLogLevel.ILLogLevelError.rawValue)
        XCTAssertEqual(loggerObj.activeLogLevels, activeLogLevel, "Active Levels should only be Info and Error from the config.")
        
        let UTLogger = UnitTestLoggingProvider.init(WithConfigDict:configurationDictionary())
        loggerObj.addProvider(UTLogger)
        
        //Assert that logging.providers has console provider
        XCTAssertEqual(loggerObj.providers.count, 1, "Console Log Provider should be added by default.");
        
        //To be ignored
        loggerObj.warn("This is Warninggggggggggggg message!!!!", props: nil)
        loggerObj.fatal("This is Fatal errorrrrrrrr message!!!!", props: nil)
        loggerObj.debug("This is Debugggggggggggggg message!!!!", props: nil)
        
        //To be logged
        loggerObj.error("This is Errorrrrrrrrrrrrrr message!!!!", props: nil)
        loggerObj.info("This is infoooooooooooooooo message!!!!", props: nil)
        
        
        
        
        
        let configDict:Dictionary<String, AnyObject> = configurationDictionaryAtLevelOnly()
        let loggingConfig1 = ILConfiguration.loggingConfigurationFromDictionary(configDict)
        
        let loggerA = IntuitLogging.sharedInstance(loggingConfig1)
        loggerA.setConfig(WithConfigDict: loggingConfig1)
        //To be ignored
        loggerA.fatal("This is Fatal errorrrrrrrr message!!!!", props: nil)
        loggerA.debug("This is Debugggggggggggggg message!!!!", props: nil)
        loggerA.error("This is Errorrrrrrrrrrrrrr message!!!!", props: nil)
        loggerA.info("This is infoooooooooooooooo message!!!!", props: nil)
        
        //To be logged
        loggerA.warn("This is Warninggggggggggggg message!!!!", props: nil)
        
        
    }

    func configurationDictionary() -> [String:AnyObject] {
        
        return ["levels" : ["AtLevelAndHigher": "warn"],
                "providers" : ["console" : ["type": "local"] ]]
    }
    
    func configurationDictionaryAtLevelOnly() -> [String:AnyObject] {
        
        return ["levels" : ["AtLevelsOnly": ["warn"]],
                "providers" : ["console" : ["type": "local"] ]]
    }
    
    func additionalProps() -> [String:AnyObject] {
        
        return ["AppId":"123" as AnyObject,
                "SessionId": "0924" as AnyObject]
    }
    
    func configurationWithRemoteLogging() -> [String:AnyObject] {
        
        return  [
            "levels": [
                "AtLevelAndHigher": "debug"
            ],
            "providers": [
                "console": [
                    "type": "local"
                ],
                "TTUIlogger": [
                    "type": "remote",
                    "addProps": [
                        "loglevel": "${CU_MSGLEVEL}",
                        "uiloglevel": [
                            "source": "loglevel",
                            "mapValues": [
                                "debug": "error",
                                "#default": "${loglevel}"
                            ]
                        ],
                        "component" : "UnitTestSample"
                    ],
                    "endpoint": [
                        "protocol": "https",
                        "host": "cqa.unit2.turbotaxonline.intuit.com",
                        "basepath": "/services/uilogger/${uiloglevel}",
                        "query": [
                            "page": "page_${pageid}",
                            "app": "${appid}"
                        ]
                    ],
                    "headers": [
                        "Application-ID": "${appid}",
                        "Cache-Control": "no-cache",
                        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
                    ]
                ]
            ]
        ]
    }
    
    func configurationWithRemoteLoggingWithoutAppId() -> [String:AnyObject] {
        
        return  [
            "levels": [
                "AtLevelAndHigher": "debug"
            ],
            "providers": [
                "console": [
                    "type": "local"
                ],
                "TTUIlogger": [
                    "type": "remote",
                    "addProps": [
                        "loglevel": "${CU_MSGLEVEL}",
                        "uiloglevel": [
                            "source": "loglevel",
                            "mapValues": [
                                "debug": "error",
                                "#default": "${loglevel}"
                            ]
                        ],
                        "Application-ID": "123"
                    ],
                    "endpoint": [
                        "port" : 87,
                        "protocol": "https",
                        "host": "cqa.unit2.turbotaxonline.intuit.com",
                        "basepath": "/services/uilogger/${uiloglevel}"
                    ]
                ]
            ]
        ]
    }
    func configurationWithRemoteLoggingWithoutComponentId() -> [String:AnyObject] {
        
        return  [
            "levels": [
                "AtLevelAndHigher": "debug"
            ],
            "providers": [
                "console": [
                    "type": "local"
                ],
                "TTUIlogger": [
                    "type": "remote",
                    "addProps": [
                        "loglevel": "${CU_MSGLEVEL}",
                        "uiloglevel": [
                            "source": "loglevel",
                            "mapValues": [
                                "debug": "error",
                                "#default": "${loglevel}"
                            ]
                        ]
                    ],
                    "endpoint": [
                        "port" : "87",
                        "protocol": "https",
                        "host": "cqa.unit2.turbotaxonline.intuit.com",
                        "basepath": "/services/uilogger/${uiloglevel}"
                    ]
                ]
            ]
        ]
    }
    
    func configurationWithRemoteLoggingWithoutEndpoint() -> [String:AnyObject] {
        
        return  [
            "levels": [
                "AtLevelAndHigher": "debug"
            ],
            "providers": [
                
                "TTUIlogger": [
                    "type": "remote",
                ]
            ]
        ]
    }
    
}

    
