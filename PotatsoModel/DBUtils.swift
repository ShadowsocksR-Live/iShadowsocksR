//
//  DBUtils.swift
//
//  Created by LEI on 8/3/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import CommUtils

private let version: UInt64 = 18

open class DBUtils {
    
    public static var sharedQueueForRealm = {
        return DispatchQueue.main
    } ()

    public static var sharedRealm: Realm! = {
        var config = Realm.Configuration()
        let sharedURL = AppProfile.sharedDatabaseUrl()
        if let originPath = config.fileURL?.path {
            if FileManager.default.fileExists(atPath: originPath) {
                _ = try? FileManager.default.moveItem(atPath: originPath, toPath: sharedURL.path)
            }
        }
        config.fileURL = sharedURL
        config.schemaVersion = version
        config.migrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion < 18 {
                // Migrating old rules list to json
                migrateRulesList(migration, oldSchemaVersion: oldSchemaVersion)
            }
        }
        Realm.Configuration.defaultConfiguration = config

        var realm: Realm? = nil
        let block = {
            do {
                realm = try Realm(configuration: config, queue: sharedQueueForRealm)
                print(realm!)
            } catch {
                print(error)
                do {
                    try FileManager.default.removeItem(at: sharedURL)
                    realm = try Realm(configuration: config, queue: sharedQueueForRealm)
                    print(realm!)
                } catch {
                    print(error)
                    assert(false)
                }
            }
        }
        if sharedQueueForRealm != DispatchQueue.main {
            sharedQueueForRealm.sync {
                block()
            }
        } else {
            block()
        }
        return realm
    } ()
    
    // MARK: - Migration
    private static func migrateRulesList(_ migration: Migration, oldSchemaVersion: UInt64) {
        migration.enumerateObjects(ofType: RuleSet.className(), { (oldObject, newObject) in
            if oldSchemaVersion > 11 {
                guard let deleted = oldObject!["deleted"] as? Bool, !deleted else {
                    return
                }
            }
            guard let rules = oldObject!["rules"] as? List<DynamicObject> else {
                return
            }
            var rulesJSONArray: [[AnyHashable: Any]] = []
            for rule in rules {
                if oldSchemaVersion > 11 {
                    guard let deleted = rule["deleted"] as? Bool, !deleted else {
                        return
                    }
                }
                guard let typeRaw = rule["typeRaw"]as? String, let contentJSONString = rule["content"] as? String, let contentJSON = contentJSONString.jsonDictionary() else {
                    return
                }
                var ruleJSON = contentJSON
                ruleJSON["type"] = typeRaw
                rulesJSONArray.append(ruleJSON)
            }
            if let newJSON = (rulesJSONArray as NSArray).jsonString() {
                newObject!["rulesJSON"] = newJSON
                newObject!["ruleCount"] = rulesJSONArray.count
            }
            newObject!["synced"] = false
        })
    }

    public static func writeSharedRealm(completionQueue: DispatchQueue, completion: @escaping ((Error?) -> Void)) {
        if completionQueue == sharedQueueForRealm {
            do {
                try sharedRealm.write {
                    completion(nil)
                }
            } catch {
                completion(error)
            }
        } else {
            sharedQueueForRealm.async {
                do {
                    try sharedRealm.write {
                        completionQueue.async {
                            completion(nil)
                        }
                    }
                } catch {
                    completionQueue.async {
                        completion(error)
                    }
                }
            }
        }
    }

    public static func objectExistOf<T: BaseModel>(type: T.Type, by name: String) -> Bool {
        if let _ = objectOf(type: type, by: name) {
            return true
        }
        return false
    }
    
    public static func objectOf<T: BaseModel>(type: T.Type, by name: String) -> T? {
        return sharedRealm.objects(type.self).filter("name = '\(name)'").first
    }
    
    public static func countOf<T: BaseModel>(type: T.Type) -> Int {
        return sharedRealm.objects(type.self).count
    }

    public static func add(_ object: BaseModel, update: Bool = true, setModified: Bool = true) throws {
        let mRealm = sharedRealm!
        mRealm.beginWrite()
        if setModified {
            object.setModified()
        }
        mRealm.add(object, update: update ? .all : .modified)
        try mRealm.commitWrite()
    }

    public static func add<S: Sequence>(_ objects: S, update: Bool = true, setModified: Bool = true) throws where S.Iterator.Element: BaseModel {
        let mRealm = sharedRealm!
        mRealm.beginWrite()
        objects.forEach({
            if setModified {
                $0.setModified()
            }
        })
        mRealm.add(objects, update: update ? .all : .modified)
        try mRealm.commitWrite()
    }

    public static func softDelete<T: BaseModel>(_ id: String, type: T.Type) throws {
        let mRealm = sharedRealm!
        guard let object: T = DBUtils.get(id, type: type) else {
            return
        }
        mRealm.beginWrite()
        object.deleted = true
        object.setModified()
        try mRealm.commitWrite()
    }

    public static func softDelete<T: BaseModel>(_ ids: [String], type: T.Type) throws {
        for id in ids {
            try softDelete(id, type: type)
        }
    }

    public static func hardDelete<T: BaseModel>(_ id: String, type: T.Type) throws {
        let mRealm = sharedRealm!
        guard let object: T = DBUtils.get(id, type: type) else {
            return
        }
        mRealm.beginWrite()
        mRealm.delete(object)
        try mRealm.commitWrite()
    }

    public static func hardDelete<T: BaseModel>(_ ids: [String], type: T.Type) throws {
        for id in ids {
            try hardDelete(id, type: type)
        }
    }

    public static func mark<T: BaseModel>(_ id: String, type: T.Type, synced: Bool) throws {
        let mRealm = sharedRealm!
        guard let object: T = DBUtils.get(id, type: type) else {
            return
        }
        mRealm.beginWrite()
        object.synced = synced
        try mRealm.commitWrite()
    }

    public static func markAll(syncd: Bool) throws {
        let mRealm = sharedRealm!
        mRealm.beginWrite()
        for proxyNode in mRealm.objects(ProxyNode.self) {
            proxyNode.synced = false
        }
        for ruleset in mRealm.objects(RuleSet.self) {
            ruleset.synced = false
        }
        for group in mRealm.objects(ConfigurationGroup.self) {
            group.synced = false
        }
        try mRealm.commitWrite()
    }
}


// Query
extension DBUtils {
    
    public static func refreshSubscriptions(_ completion:((Bool)->Void)? = nil) {
        sharedQueueForRealm.async {
            var success = false
            var newNodes: [ProxyNode] = []
            let proxyNodes: [ProxyNode?] = allNotDeleted(ProxyNode.self, sorted: "createAt").map({ $0 })
            
            proxyNodes.forEach { node in
                if let node = node, node.type == .Subscription, let url = URL(string: node.host) {
                    do {
                        let contents = try String(contentsOf: url)
                        let nodes = parseNodes(contents, sourceUuid: node.uuid)
                        newNodes.append(contentsOf: nodes)
                    } catch {
                    }
                }
            }
            
            // if we get new subscription nodes successfully
            if newNodes.count > 0 {
                // delete all old subscribed nodes from database
                proxyNodes.filter { node in
                    node?.sourceType != .fromCustom
                }.forEach { node in
                    do {
                        try DBUtils.softDelete(node?.uuid ?? "", type: ProxyNode.self)
                    } catch {
                        print("delete failed")
                    }
                }
                
                // write new nodes to database
                for node in newNodes {
                    do {
                        try DBUtils.add(node)
                    } catch {
                        print("write node failed")
                    }
                }
                success = true
            }
            completion?(success)
        }
    }
    
    private static func parseNodes(_ contents:String, sourceUuid:String) -> [ProxyNode] {
        var nodes:[ProxyNode] = []
        var c0:String
        if !contents.contains(ProxyNode.ssUriPrefix) && !contents.contains(ProxyNode.ssrUriPrefix) {
            c0 = ProxyNode.base64DecodeUrlSafe(contents) ?? ""
        } else {
            c0 = contents
        }
        
        let lines = c0.split { $0 == "\n" || $0 == "\r\n" || $0 == " " }.map(String.init)
        for line in lines {
            do {
                let randomInt = Int.random(in: 0..<1000)
                var name = "Outer-" + String(format: "%04d", randomInt)
                let proxyNode = try ProxyNode(dictionary: ["name": name as AnyObject, "uri": line as AnyObject])
                proxyNode.sourceType = .fromSubscribe
                proxyNode.sourceUuid = sourceUuid
                name = proxyNode.name
                if name.count > 13 {
                    let index = name.index(name.startIndex, offsetBy: 13)
                    proxyNode.name = String(name[...index])
                }
                nodes.append(proxyNode)
            } catch {
                print("%@", error)
            }
        }
        return nodes
    }

    public static func allNotDeleted<T: BaseModel>(_ type: T.Type, filter: String? = nil, sorted: String? = nil) -> Results<T> {
        let deleteFilter = "deleted = false"
        var mFilter = deleteFilter
        if let filter = filter {
            mFilter += " && " + filter
        }
        return all(type, filter: mFilter, sorted: sorted)
    }

    public static func all<T: BaseModel>(_ type: T.Type, filter: String? = nil, sorted: String? = nil) -> Results<T> {
        let mRealm = sharedRealm!
        var res = mRealm.objects(type)
        if let filter = filter {
            res = res.filter(filter)
        }
        if let sorted = sorted {
            res = res.sorted(byKeyPath: sorted)
        }
        return res
    }

    public static func get<T: BaseModel>(_ uuid: String, type: T.Type, filter: String? = nil, sorted: String? = nil) -> T? {
        let mRealm = sharedRealm!
        var mFilter = "uuid = '\(uuid)'"
        if let filter = filter {
            mFilter += " && " + filter
        }
        var res = mRealm.objects(type).filter(mFilter)
        if let sorted = sorted {
            res = res.sorted(byKeyPath: sorted)
        }
        return res.first
    }

    public static func modify<T: BaseModel>(_ type: T.Type, id: String, modifyBlock: ((Realm, T) -> Error?)) throws {
        let mRealm = sharedRealm!
        guard let object: T = DBUtils.get(id, type: type) else {
            return
        }
        mRealm.beginWrite()
        if let error = modifyBlock(mRealm, object) {
            throw error
        }
        do {
            try object.validate()
        }catch {
            mRealm.cancelWrite()
            throw error
        }
        object.setModified()
        try mRealm.commitWrite()
    }

}

// BaseModel API
extension BaseModel {

    func setModified() {
        updatedAt = Date().timeIntervalSince1970
        synced = false
    }

}


// Config Group API
extension ConfigurationGroup {

    public static func changeProxyNode(forGroupId groupId: String, nodeId: String?) throws {
        try DBUtils.modify(ConfigurationGroup.self, id: groupId) { (realm, group) -> Error? in
            group.proxyNodes.removeAll()
            if let nodeId = nodeId, let proxyNode = DBUtils.get(nodeId, type: ProxyNode.self){
                group.proxyNodes.append(proxyNode)
            }
            return nil
        }
    }

    public static func appendRuleSet(forGroupId groupId: String, rulesetId: String) throws {
        try DBUtils.modify(ConfigurationGroup.self, id: groupId) { (realm, group) -> Error? in
            if let ruleset = DBUtils.get(rulesetId, type: RuleSet.self) {
                group.ruleSets.append(ruleset)
            }
            return nil
        }
    }

    public static func changeDNS(forGroupId groupId: String, dns: String?) throws {
        try DBUtils.modify(ConfigurationGroup.self, id: groupId) { (realm, group) -> Error? in
            group.dns = dns ?? ""
            return nil
        }
    }

    public static func changeName(forGroupId groupId: String, name: String) throws {
        try DBUtils.modify(ConfigurationGroup.self, id: groupId) { (realm, group) -> Error? in
            group.name = name
            return nil
        }
    }

}

