//
//  ProxyRuleSet.swift
//  Potatso
//
//  Created by LEI on 4/6/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import RealmSwift

public enum ProxyRuleSetError: Error {
    case invalidProxyRuleSet
    case emptyName
    case nameAlreadyExists
}

extension ProxyRuleSetError: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .invalidProxyRuleSet:
            return "Invalid rule set"
        case .emptyName:
            return "Empty name"
        case .nameAlreadyExists:
            return "Name already exists"
        }
    }
    
}

public final class ProxyRuleSet: BaseModel {
    @objc public dynamic var editable = true
    @objc public dynamic var name = ""
    @objc public dynamic var remoteUpdatedAt: TimeInterval = Date().timeIntervalSince1970
    @objc public dynamic var desc = ""
    @objc public dynamic var ruleCount = 0
    @objc public dynamic var rulesJSON = ""
    @objc public dynamic var isSubscribe = false
    @objc public dynamic var isOfficial = false

    fileprivate var cachedRules: [Rule]? = nil

    public var rules: [Rule] {
        get {
            if let cachedRules = cachedRules {
                return cachedRules
            }
            updateCahcedRules()
            return cachedRules!
        }
        set {
            let json = (newValue.map({ $0.json }) as NSArray).jsonString() ?? ""
            rulesJSON = json
            updateCahcedRules()
            ruleCount = newValue.count
        }
    }

    public override func validate(inRealm realm: Realm) throws {
        guard name.count > 0 else {
            throw ProxyRuleSetError.emptyName
        }
    }

    fileprivate func updateCahcedRules() {
        guard let jsonArray = rulesJSON.jsonArray() as? [[String: AnyObject]] else {
            cachedRules = []
            return
        }
        cachedRules = jsonArray.compactMap({ Rule(json: $0) })
    }

    public func addRule(_ rule: Rule) {
        var newRules = rules
        newRules.append(rule)
        rules = newRules
    }

    public func insertRule(_ rule: Rule, atIndex index: Int) {
        var newRules = rules
        newRules.insert(rule, at: index)
        rules = newRules
    }

    public func removeRule(atIndex index: Int) {
        var newRules = rules
        newRules.remove(at: index)
        rules = newRules
    }

    public func move(_ fromIndex: Int, toIndex: Int) {
        var newRules = rules
        let rule = newRules[fromIndex]
        newRules.remove(at: fromIndex)
        insertRule(rule, atIndex: toIndex)
        rules = newRules
    }
    
    public override static func indexedProperties() -> [String] {
        return ["name"]
    }
    
}

extension ProxyRuleSet {
    
    public convenience init(dictionary: [String: AnyObject], inRealm realm: Realm) throws {
        self.init()
        guard let name = dictionary["name"] as? String else {
            throw ProxyRuleSetError.invalidProxyRuleSet
        }
        self.name = name
        if realm.objects(ProxyRuleSet.self).filter("name = '\(name)'").first != nil {
            self.name = "\(name) \(ProxyRuleSet.dateFormatter.string(from: Date()))"
        }
        guard let rulesStr = dictionary["rules"] as? [String] else {
            throw ProxyRuleSetError.invalidProxyRuleSet
        }
        rules = try rulesStr.map({ try Rule(str: $0) })
    }
    
}

public func ==(lhs: ProxyRuleSet, rhs: ProxyRuleSet) -> Bool {
    return lhs.uuid == rhs.uuid
}
