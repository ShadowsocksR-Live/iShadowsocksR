//
//  DBInitializer.swift
//
//  Created by LEI on 3/8/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import UIKit
import ICSMainFramework
import NetworkExtension
import Async
import RealmSwift
import Realm

class DataInitializer: NSObject, AppLifeCycleProtocol {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Manager.sharedManager.setup()
        CloudSetManager.shared.update()
        sync()
        return true
    }
    
    var taskID: UIBackgroundTaskIdentifier? = nil
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if #available(iOS 12, *) {
            if (taskID != nil) {
                return
            }
            taskID = application.beginBackgroundTask(withName: "application_did_enter_background") {
                NSLog("running regenerateConfigFiles")
                _ = try? Manager.sharedManager.regenerateConfigFiles()
                application.endBackgroundTask(self.taskID!)
                self.taskID = nil
            }
        } else {
            _ = try? Manager.sharedManager.regenerateConfigFiles()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async(execute: {
            NSLog("running applicationWillEnterForeground task")
            Receipt.shared.validate()
            self.sync()
        })
    }

    func sync() {
    }

}
