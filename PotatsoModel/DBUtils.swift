//
//  DBUtils.swift
//
//  Created by LEI on 8/3/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

open class DBUtils {

    fileprivate static func currentRealm() -> Realm {
        return sharedRealm
    }

    public static func add(_ object: BaseModel, update: Bool = true, setModified: Bool = true) throws {
        let mRealm = currentRealm()
        mRealm.beginWrite()
        if setModified {
            object.setModified()
        }
        mRealm.add(object, update: update ? .all : .modified)
        try mRealm.commitWrite()
    }

    public static func add<S: Sequence>(_ objects: S, update: Bool = true, setModified: Bool = true) throws where S.Iterator.Element: BaseModel {
        let mRealm = currentRealm()
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
        let mRealm = currentRealm()
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
        let mRealm = currentRealm()
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
        let mRealm = currentRealm()
        guard let object: T = DBUtils.get(id, type: type) else {
            return
        }
        mRealm.beginWrite()
        object.synced = synced
        try mRealm.commitWrite()
    }

    public static func markAll(syncd: Bool) throws {
        let mRealm = currentRealm()
        mRealm.beginWrite()
        for proxyNode in mRealm.objects(ProxyNode.self) {
            proxyNode.synced = false
        }
        for ruleset in mRealm.objects(ProxyRuleSet.self) {
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

    public static func allNotDeleted<T: BaseModel>(_ type: T.Type, filter: String? = nil, sorted: String? = nil) -> Results<T> {
        let deleteFilter = "deleted = false"
        var mFilter = deleteFilter
        if let filter = filter {
            mFilter += " && " + filter
        }
        return all(type, filter: mFilter, sorted: sorted)
    }

    public static func all<T: BaseModel>(_ type: T.Type, filter: String? = nil, sorted: String? = nil) -> Results<T> {
        let mRealm = currentRealm()
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
        let mRealm = currentRealm()
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
        let mRealm = currentRealm()
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

    public static func appendProxyRuleSet(forGroupId groupId: String, rulesetId: String) throws {
        try DBUtils.modify(ConfigurationGroup.self, id: groupId) { (realm, group) -> Error? in
            if let ruleset = DBUtils.get(rulesetId, type: ProxyRuleSet.self) {
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

