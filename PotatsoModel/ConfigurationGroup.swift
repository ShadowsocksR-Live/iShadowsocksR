//
//  ConfigurationGroup.swift
//
//  Created by LEI on 4/6/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import RealmSwift

public enum ConfigurationGroupError: Error {
    case invalidConfigurationGroup
    case emptyName
    case nameAlreadyExists
}

extension ConfigurationGroupError: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .invalidConfigurationGroup:
            return "Invalid config group"
        case .emptyName:
            return "Empty name"
        case .nameAlreadyExists:
            return "Name already exists"
        }
    }
    
}


open class ConfigurationGroup: BaseModel {
    @objc open dynamic var editable = true
    @objc open dynamic var name = ""
    @objc open dynamic var defaultToProxy = true
    @objc open dynamic var dns = ""
    open var proxyNodes = List<ProxyNode>()
    open var ruleSets = List<RuleSet>()
    
    public override static func indexedProperties() -> [String] {
        return ["name"]
    }
    
    open override func validate() throws {
        guard name.count > 0 else {
            throw ConfigurationGroupError.emptyName
        }
    }

    open override var description: String {
        return name
    }
}

extension ConfigurationGroup {
    
    public convenience init(dictionary: [String: AnyObject]) throws {
        self.init()
        guard let name = dictionary["name"] as? String else {
            throw ConfigurationGroupError.invalidConfigurationGroup
        }
        self.name = name
        if DBUtils.objectExistOf(type: RuleSet.self, by: name) {
            self.name = "\(name) \(ConfigurationGroup.dateFormatter.string(from: Date()))"
        }
        if let proxyNodeName = dictionary["proxy"] as? String, let proxyNode = DBUtils.objectOf(type: ProxyNode.self, by: proxyNodeName) {
            self.proxyNodes.removeAll()
            self.proxyNodes.append(proxyNode)
        }
        if let ruleSetsName = dictionary["ruleSets"] as? [String] {
            for ruleSetName in ruleSetsName {
                if let ruleSet = DBUtils.objectOf(type: RuleSet.self, by: ruleSetName) {
                    self.ruleSets.append(ruleSet)
                }
            }
        }
        if let defaultToProxy = dictionary["defaultToProxy"] as? NSString {
            self.defaultToProxy = defaultToProxy.boolValue
        }
        if let dns = dictionary["dns"] as? String {
            self.dns = dns
        }
        if let dns = dictionary["dns"] as? [String] {
            self.dns = dns.joined(separator: ",")
        }
    }

    
}

public func ==(lhs: ConfigurationGroup, rhs: ConfigurationGroup) -> Bool {
    return lhs.uuid == rhs.uuid
}
