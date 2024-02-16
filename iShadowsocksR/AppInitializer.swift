//
//  AppInitilizer.swift
//
//  Created by LEI on 12/27/15.
//  Copyright © 2015 TouchingApp. All rights reserved.
//

import Foundation
import ICSMainFramework
import CocoaLumberjackSwift

class AppInitializer: NSObject, AppLifeCycleProtocol {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        _  = UIViewController.shared
        
        configLogging()
        return true
    }

    func configLogging() {
        let fileLogger = DDFileLogger() // File Logger
        fileLogger.rollingFrequency = TimeInterval(60*60*24*3)  // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)

        #if DEBUG
            DDLog.add(DDTTYLogger.sharedInstance!) // TTY = Xcode console
            DDLog.add(DDOSLogger.sharedInstance) // ASL = Apple System Logs
            DDLog.setLevel(DDLogLevel.all, for: DDTTYLogger.self)
            DDLog.setLevel(DDLogLevel.all, for: DDOSLogger.self)
        #else

        #endif
    }
    
}
