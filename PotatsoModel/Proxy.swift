//
//  Proxy.swift
//
//  Created by LEI on 4/6/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import RealmSwift
import CloudKit

public enum ProxyType: String {
    case Shadowsocks = "SS"
    case ShadowsocksR = "SSR"
    case Https = "HTTPS"
    case Socks5 = "SOCKS5"
    case None = "NONE"
}

extension ProxyType: CustomStringConvertible {
    
    public var description: String {
        return rawValue
    }
    
    public var isShadowsocks: Bool {
        return self == .Shadowsocks || self == .ShadowsocksR
    }
    
}

public enum ProxyError: Error {
    case invalidType
    case invalidName
    case invalidHost
    case invalidPort
    case invalidAuthScheme
    case nameAlreadyExists
    case invalidUri
    case invalidPassword
}

extension ProxyError: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .invalidType:
            return "Invalid type"
        case .invalidName:
            return "Invalid name"
        case .invalidHost:
            return "Invalid host"
        case .invalidAuthScheme:
            return "Invalid encryption"
        case .invalidUri:
            return "Invalid uri"
        case .nameAlreadyExists:
            return "Name already exists"
        case .invalidPassword:
            return "Invalid password"
        case .invalidPort:
            return "Invalid port"
        }
    }
    
}

open class Proxy: BaseModel {
    @objc open dynamic var typeRaw = ProxyType.ShadowsocksR.rawValue
    @objc open dynamic var name = ""
    @objc open dynamic var host = ""
    @objc open dynamic var port = 0
    @objc open dynamic var authscheme: String?  // method in SS
    @objc open dynamic var user: String?
    @objc open dynamic var password: String?
    @objc open dynamic var ota: Bool = false
    @objc open dynamic var ssrProtocol: String?
    @objc open dynamic var ssrProtocolParam: String?
    @objc open dynamic var ssrObfs: String?
    @objc open dynamic var ssrObfsParam: String?
    @objc open dynamic var ssrotEnable: Bool = false
    @objc open dynamic var ssrotDomain: String?
    @objc open dynamic var ssrotPath: String?
    
    open static let ssUriPrefix = "ss://"
    open static let ssrUriPrefix = "ssr://"
    
    open static let ssrSupportedProtocol = [
        "origin",
        "verify_simple",
        "auth_simple",
        "auth_sha1",
        "auth_sha1_v2",
        "auth_sha1_v4",
        "auth_aes128_md5",
        "auth_aes128_sha1",
        "auth_chain_a",
        "auth_chain_b",
        "auth_chain_c",
        "auth_chain_d",
        "auth_chain_e",
        "auth_chain_f",
        ]
    open static let ssrSupportedObfs = [
        "plain",
        "http_simple",
        "http_post",
        "tls1.2_ticket_auth",
        "tls1.2_ticket_fastauth"
    ]
    
    open static let ssSupportedEncryption = [
        "none",
        "table",
        "rc4",
        "rc4-md5-6",
        "rc4-md5",
        "aes-128-cfb",
        "aes-192-cfb",
        "aes-256-cfb",
        "aes-128-ctr",
        "aes-192-ctr",
        "aes-256-ctr",
        "bf-cfb",
        "camellia-128-cfb",
        "camellia-192-cfb",
        "camellia-256-cfb",
        "cast5-cfb",
        "des-cfb",
        "idea-cfb",
        "rc2-cfb",
        "seed-cfb",
        "salsa20",
        "chacha20",
        "chacha20-ietf",
        "aes-128-gcm",
        "aes-192-gcm",
        "aes-256-gcm",
        "chacha20-ietf-poly1305",
        "xchacha20-ietf-poly1305",
    ]
    open override static func indexedProperties() -> [String] {
        return ["name"]
    }
    
    open override func validate(inRealm realm: Realm) throws {
        guard let _ = ProxyType(rawValue: typeRaw)else {
            throw ProxyError.invalidType
        }
        guard name.count > 0 else{
            throw ProxyError.invalidName
        }
        guard host.count > 0 else {
            throw ProxyError.invalidHost
        }
        guard port > 0 && port <= Int(UINT16_MAX) else {
            throw ProxyError.invalidPort
        }
        switch type {
        case .Shadowsocks, .ShadowsocksR:
            guard let _ = authscheme else {
                throw ProxyError.invalidAuthScheme
            }
        default:
            break
        }
    }
    
}

// Public Accessor
extension Proxy {
    
    public var type: ProxyType {
        get {
            return ProxyType(rawValue: typeRaw) ?? .Shadowsocks
        }
        set(v) {
            typeRaw = v.rawValue
        }
    }
    
    public var uri: String {
        switch type {
        case .Shadowsocks:
            if let authscheme = authscheme, let password = password {
                return "ss://\(authscheme):\(password)@\(host):\(port)"
            }
        case .ShadowsocksR:
            return buildSsrUri()
        default:
            break
        }
        return ""
    }
    open override var description: String {
        return name
    }
    
    public func buildSsrUri() -> String {
        var base = "\(host):\(port):\(ssrProtocol ?? Proxy.ssrSupportedProtocol[0]):\(authscheme ?? Proxy.ssSupportedEncryption[0]):\(ssrObfs ?? Proxy.ssrSupportedObfs[0]):\(Proxy.base64EncodeUrlSafe(password))"
        var param:String?
        var tmp:[String] = []

        param = (ssrObfsParam?.count ?? 0)>0 ? "obfsparam=\(Proxy.base64EncodeUrlSafe(ssrObfsParam))" : nil
        if (param != nil) { tmp.append(param!) }
        
        param = (ssrProtocolParam?.count ?? 0)>0 ? "protoparam=\(Proxy.base64EncodeUrlSafe(ssrProtocolParam))" : nil
        if (param != nil) { tmp.append(param!) }

        param = (name.count > 0) ? "remarks=\(Proxy.base64EncodeUrlSafe(name))" : nil
        if (param != nil) { tmp.append(param!) }
        
        param = (ssrotEnable) ? "ot_enable=1" : nil
        if (param != nil) { tmp.append(param!) }
        
        param = ((ssrotDomain?.count ?? 0) > 0) ? "ot_domain=\(Proxy.base64EncodeUrlSafe(ssrotDomain))" : nil
        if (param != nil) { tmp.append(param!) }
        
        param = ((ssrotPath?.count ?? 0) > 0) ? "ot_path=\(Proxy.base64EncodeUrlSafe(ssrotPath))" : nil
        if (param != nil) { tmp.append(param!) }
        
        param = tmp.joined(separator: "&")

        if (param?.count ?? 0) > 0 {
            base = base + "/?" + param!
        }
        
        base = Proxy.ssrUriPrefix + Proxy.base64EncodeUrlSafe(base)

        return base
    }
    
}

// API
extension Proxy {
    
    
    
}

// Import
extension Proxy {
    
    public convenience init(dictionary: [String: AnyObject], inRealm realm: Realm) throws {
        self.init()
        if let uriString = dictionary["uri"] as? String {
            guard let name = dictionary["name"] as? String else{
                throw ProxyError.invalidName
            }
            self.name = name
            if uriString.lowercased().hasPrefix(Proxy.ssUriPrefix) {
                // Shadowsocks
                let undecodedString = uriString.substring(from: uriString.index(uriString.startIndex, offsetBy: Proxy.ssUriPrefix.count))
                guard let proxyString = base64DecodeUrlSafe(undecodedString), let _ = proxyString.range(of: ":")?.lowerBound else {
                    throw ProxyError.invalidUri
                }
                guard let pc1 = proxyString.range(of: ":")?.lowerBound, let pc2 = proxyString.range(of: ":", options: .backwards)?.lowerBound, let pcm = proxyString.range(of: "@", options: .backwards)?.lowerBound else {
                    throw ProxyError.invalidUri
                }
                if !(pc1 < pcm && pcm < pc2) {
                    throw ProxyError.invalidUri
                }
                let fullAuthscheme = proxyString.lowercased().substring(with: proxyString.startIndex..<pc1)
                if let pOTA = fullAuthscheme.range(of: "-auth", options: .backwards)?.lowerBound {
                    self.authscheme = fullAuthscheme.substring(to: pOTA)
                    self.ota = true
                }else {
                    self.authscheme = fullAuthscheme
                }
                self.password = proxyString.substring(with: proxyString.index(after: pc1)..<pcm)
                self.host = proxyString.substring(with: proxyString.index(after: pcm)..<pc2)
                guard let p = Int(proxyString.substring(with: proxyString.index(after: pc2)..<proxyString.endIndex)) else {
                    throw ProxyError.invalidPort
                }
                self.port = p
                self.type = .Shadowsocks
            }else if uriString.lowercased().hasPrefix(Proxy.ssrUriPrefix) {
                let undecodedString = uriString.substring(from: uriString.index(uriString.startIndex, offsetBy: Proxy.ssrUriPrefix.count))
                guard let proxyString = base64DecodeUrlSafe(undecodedString), let _ = proxyString.range(of: ":")?.lowerBound else {
                    throw ProxyError.invalidUri
                }
                var hostString: String = proxyString
                var queryString: String = ""
                if let queryMarkIndex = proxyString.range(of: "?", options: .backwards)?.lowerBound {
                    hostString = proxyString.substring(to: queryMarkIndex)
                    queryString = proxyString.substring(from: proxyString.index(after: queryMarkIndex))
                }
                if let hostSlashIndex = hostString.range(of: "/", options: .backwards)?.lowerBound {
                    hostString = hostString.substring(to: hostSlashIndex)
                }
                let hostComps = hostString.components(separatedBy: ":")
                guard hostComps.count == 6 else {
                    throw ProxyError.invalidUri
                }
                self.host = hostComps[0]
                guard let p = Int(hostComps[1]) else {
                    throw ProxyError.invalidPort
                }
                self.port = p
                self.ssrProtocol = hostComps[2]
                self.authscheme = hostComps[3]
                self.ssrObfs = hostComps[4]
                self.password = base64DecodeUrlSafe(hostComps[5])
                for queryComp in queryString.components(separatedBy: "&") {
                    let comps = queryComp.components(separatedBy: "=")
                    guard comps.count == 2 else {
                        continue
                    }
                    switch comps[0] {
                    case "protoparam":
                        self.ssrProtocolParam = base64DecodeUrlSafe(comps[1])
                    case "obfsparam":
                        self.ssrObfsParam = base64DecodeUrlSafe(comps[1])
                    case "remarks":
                        self.name = base64DecodeUrlSafe(comps[1]) ?? ""
                    case "ot_enable":
                        self.ssrotEnable = (Int(comps[1]) != 0)
                    case "ot_domain":
                        self.ssrotDomain = base64DecodeUrlSafe(comps[1]) ?? ""
                    case "ot_path":
                        self.ssrotPath = base64DecodeUrlSafe(comps[1]) ?? ""
                    default:
                        continue
                    }
                }
                self.type = .ShadowsocksR
            }else {
                // Not supported yet
                throw ProxyError.invalidUri
            }
        }else {
            guard let name = dictionary["name"] as? String else{
                throw ProxyError.invalidName
            }
            guard let host = dictionary["host"] as? String else{
                throw ProxyError.invalidHost
            }
            guard let typeRaw = (dictionary["type"] as? String)?.uppercased(), let type = ProxyType(rawValue: typeRaw) else{
                throw ProxyError.invalidType
            }
            guard let portStr = (dictionary["port"] as? String), let port = Int(portStr) else{
                throw ProxyError.invalidPort
            }
            guard let encryption = dictionary["encryption"] as? String else{
                throw ProxyError.invalidAuthScheme
            }
            guard let password = dictionary["password"] as? String else{
                throw ProxyError.invalidPassword
            }
            self.host = host
            self.port = port
            self.password = password
            self.authscheme = encryption
            self.name = name
            self.type = type
        }
        if realm.objects(Proxy.self).filter("name = '\(name)'").first != nil {
            self.name = "\(name) \(Proxy.dateFormatter.string(from: Date()))"
        }
        try validate(inRealm: realm)
    }
    
    fileprivate func base64DecodeUrlSafe(_ proxyString: String) -> String? {
        if let _ = proxyString.range(of: ":")?.lowerBound {
            return proxyString
        }
        let base64String = proxyString.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let padding = base64String.count + (base64String.count % 4 != 0 ? (4 - base64String.count % 4) : 0)
        if let decodedData = Data(base64Encoded: base64String.padding(toLength: padding, withPad: "=", startingAt: 0), options: NSData.Base64DecodingOptions(rawValue: 0)), let decodedString = NSString(data: decodedData, encoding: String.Encoding.utf8.rawValue) {
            return decodedString as String
        }
        return nil
    }
    
    public class func base64EncodeUrlSafe(_ orig: String?) -> String {
        let d = orig?.data(using: .utf8)
        guard let d2 = d?.base64EncodedData() else { return "" }
        let d3 = String(data: d2, encoding: .utf8)
        let base64String = d3?.replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
        return base64String?.replacingOccurrences(of: "=", with: "") ?? ""
    }
    
    public class func uriIsShadowsocks(_ uri: String) -> Bool {
        return uri.lowercased().hasPrefix(Proxy.ssUriPrefix) || uri.lowercased().hasPrefix(Proxy.ssrUriPrefix)
    }
    
}

public func ==(lhs: Proxy, rhs: Proxy) -> Bool {
    return lhs.uuid == rhs.uuid
}
