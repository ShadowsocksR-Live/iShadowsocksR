//
//  CloudSetManager.swift
//
//  Created by LEI on 8/13/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import Foundation
import Async
import RealmSwift

class CloudSetManager {

    static let shared = CloudSetManager()

    fileprivate init() {

    }

    func update() {
        Async.background(after: 1.5) {
            let realm = try! Realm()
            let uuids = realm.objects(ProxyRuleSet.self).filter("isSubscribe = true").map({$0.uuid})
            
            var uuidsArray: [String] = []
            /*
             // TODO: realm removed
            var iterator: LazyMapIterator<RLMIterator<ProxyRuleSet>, String>? = nil
            iterator = uuids.makeIterator()
            iterator?.forEach({ (tObj) in
                uuidsArray.append(tObj as String)
            })
            */
            ///custom modify: disable cloudset update
            /*
            API.updateProxyRuleSetListDetail(uuidsArray) { (response) in
                if let sets = response.result.value {
                    do {
                        try ProxyRuleSet.addRemoteArray(sets)
                    }catch {
                        error.log("Unable to save updated rulesets")
                        return
                    }
                }else {
                    response.result.error?.log("Fail to update ruleset details")
                }
            }
             */
        }
    }
}
