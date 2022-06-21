//
//  Proxy.swift
//
//  Created by LEI on 4/6/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

public enum ProxyNodeType: String {
    case None = "NONE"
    case Shadowsocks = "SS"
    case ShadowsocksR = "SSR"
    case Https = "HTTPS"
    case Socks5 = "SOCKS5"
    case Subscription = "Subscription URL"
}

extension ProxyNodeType: CustomStringConvertible {
    
    public var description: String {
        return rawValue
    }
    
    public var isShadowsocks: Bool {
        return self == .Shadowsocks || self == .ShadowsocksR
    }
    
}

public enum ProxyNodeError: Error {
    case invalidType
    case invalidName
    case invalidHost
    case invalidPort
    case invalidAuthScheme
    case nameAlreadyExists
    case invalidUri
    case invalidPassword
}

extension ProxyNodeError: CustomStringConvertible {
    
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

public enum SourceType : Int {
    case fromCustom = 0
    case fromSubscribe = 1
    case fromOrganization = 2
}

open class ProxyNode: BaseModel {
    @objc open dynamic var typeRaw = ProxyNodeType.ShadowsocksR.rawValue
    @objc open dynamic var sourceTypeRaw = SourceType.fromCustom.rawValue
    @objc open dynamic var sourceUuid: String?
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
    
    public static let ssUriPrefix = "ss://"
    public static let ssrUriPrefix = "ssr://"
    
    public static let ssrSupportedProtocol = [
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
    public static let ssrSupportedObfs = [
        "plain",
        "http_simple",
        "http_post",
        "tls1.2_ticket_auth",
        "tls1.2_ticket_fastauth"
    ]
    
    public static let ssSupportedEncryption = [
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
    public override static func indexedProperties() -> [String] {
        return ["name"]
    }
    
    open override func validate() throws {
        guard let _ = ProxyNodeType(rawValue: typeRaw)else {
            throw ProxyNodeError.invalidType
        }
        guard name.count > 0 else{
            throw ProxyNodeError.invalidName
        }
        guard host.count > 0 else {
            throw ProxyNodeError.invalidHost
        }
        guard port > 0 && port <= Int(UINT16_MAX) else {
            throw ProxyNodeError.invalidPort
        }
        switch type {
        case .Shadowsocks, .ShadowsocksR:
            guard let _ = authscheme else {
                throw ProxyNodeError.invalidAuthScheme
            }
        default:
            break
        }
    }
    
}

// Public Accessor
extension ProxyNode {
    
    public var type: ProxyNodeType {
        get {
            return ProxyNodeType(rawValue: typeRaw) ?? .Shadowsocks
        }
        set(v) {
            typeRaw = v.rawValue
        }
    }
    
    public var sourceType: SourceType {
        get {
            return SourceType(rawValue: sourceTypeRaw) ?? .fromCustom
        }
        set(v) {
            sourceTypeRaw = v.rawValue
        }
    }
    
    public var uri: String {
        switch type {
        case .Shadowsocks:
            return buildSsUri()
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
    
    public func buildSsUri() -> String {
        if let authscheme = authscheme, let password = password {
            let mainInfo = "\(authscheme):\(password)@\(host):\(port)"
            let b64 = ProxyNode.base64EncodeUrlSafe(mainInfo)
            if name.count > 0 {
                let remarks = name.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                return "ss://\(b64)#\(remarks)"
            } else {
                return "ss://\(b64)"
            }
        }
        return ""
    }
    
    public func buildSsrUri() -> String {
        var base = "\(host):\(port):\(ssrProtocol ?? ProxyNode.ssrSupportedProtocol[0]):\(authscheme ?? ProxyNode.ssSupportedEncryption[0]):\(ssrObfs ?? ProxyNode.ssrSupportedObfs[0]):\(ProxyNode.base64EncodeUrlSafe(password))"
        var param:String?
        var tmp:[String] = []

        param = (ssrObfsParam?.count ?? 0)>0 ? "obfsparam=\(ProxyNode.base64EncodeUrlSafe(ssrObfsParam))" : nil
        if (param != nil) { tmp.append(param!) }
        
        param = (ssrProtocolParam?.count ?? 0)>0 ? "protoparam=\(ProxyNode.base64EncodeUrlSafe(ssrProtocolParam))" : nil
        if (param != nil) { tmp.append(param!) }

        param = (name.count > 0) ? "remarks=\(ProxyNode.base64EncodeUrlSafe(name))" : nil
        if (param != nil) { tmp.append(param!) }
        
        if ssrotEnable {
            param = (ssrotEnable) ? "ot_enable=1" : nil
            if (param != nil) { tmp.append(param!) }
            
            param = ((ssrotDomain?.count ?? 0) > 0) ? "ot_domain=\(ProxyNode.base64EncodeUrlSafe(ssrotDomain))" : nil
            if (param != nil) { tmp.append(param!) }
            
            param = ((ssrotPath?.count ?? 0) > 0) ? "ot_path=\(ProxyNode.base64EncodeUrlSafe(ssrotPath))" : nil
            if (param != nil) { tmp.append(param!) }
        }
        
        param = tmp.joined(separator: "&")

        if (param?.count ?? 0) > 0 {
            base = base + "/?" + param!
        }
        
        base = ProxyNode.ssrUriPrefix + ProxyNode.base64EncodeUrlSafe(base)

        return base
    }
    
}

// API
extension ProxyNode {
    
    
    
}

// Import
extension ProxyNode {
    
    public convenience init(dictionary: [String: AnyObject]) throws {
        self.init()
        if var uriString = dictionary["uri"] as? String {
            guard let name = dictionary["name"] as? String else{
                throw ProxyNodeError.invalidName
            }
            self.name = name
            if uriString.lowercased().hasPrefix(ProxyNode.ssUriPrefix) {
                // Shadowsocks
                let array = uriString.components(separatedBy: "#")
                if array.count > 1 {
                    uriString = array[0]
                    self.name = array[1].removingPercentEncoding!
                }
                let index = uriString.index(uriString.startIndex, offsetBy: ProxyNode.ssUriPrefix.count)
                let undecodedString = String(uriString[index...])
                let tmp = undecodedString.components(separatedBy: "@")
                if tmp.count > 1 {
                    //
                    // ss://YmYtY2ZiOnRlc3Q@192.168.100.1:8888/?plugin=value1&arguments=value2#Dummy+profile+name.
                    //
                    let tmp2 = undecodedString.components(separatedBy: "/?")
                    if tmp2.count > 1 {
                        // FIXME: do not suppprt plugin parameters.
                        throw ProxyNodeError.invalidUri
                    }
                    let array2 = tmp2[0].components(separatedBy: "@")
                    
                    let userinfo = ProxyNode.base64DecodeUrlSafe(array2[0])
                    let m_p = userinfo?.components(separatedBy: ":")
                    if m_p?.count != 2 {
                        throw ProxyNodeError.invalidUri
                    }
                    self.authscheme = m_p?[0]
                    self.password = m_p?[1]
                    
                    let h_p = array2[1].components(separatedBy: ":")
                    if h_p.count != 2 {
                        throw ProxyNodeError.invalidUri
                    }
                    self.host = h_p[0]
                    self.port = Int(h_p[1]) ?? 0
                    if self.port == 0 {
                        throw ProxyNodeError.invalidUri
                    }
                    
                    self.type = .Shadowsocks
                    return
                }

                guard let proxyString = ProxyNode.base64DecodeUrlSafe(undecodedString),
                      let _ = proxyString.range(of: ":")?.lowerBound else {
                    throw ProxyNodeError.invalidUri
                }
                guard let pc1 = proxyString.range(of: ":")?.lowerBound,
                      let pc2 = proxyString.range(of: ":", options: .backwards)?.lowerBound,
                      let pcm = proxyString.range(of: "@", options: .backwards)?.lowerBound else {
                    throw ProxyNodeError.invalidUri
                }
                if !(pc1 < pcm && pcm < pc2) {
                    throw ProxyNodeError.invalidUri
                }
                let fullAuthscheme = String(proxyString.lowercased()[proxyString.startIndex..<pc1])
                if let pOTA = fullAuthscheme.range(of: "-auth", options: .backwards)?.lowerBound {
                    self.authscheme = String(fullAuthscheme[..<pOTA])
                    self.ota = true
                }else {
                    self.authscheme = fullAuthscheme
                }
                self.password = String(proxyString[proxyString.index(after: pc1)..<pcm])
                self.host = String(proxyString[proxyString.index(after: pcm)..<pc2])
                guard let p = Int(String(proxyString[proxyString.index(after: pc2)..<proxyString.endIndex])) else {
                    throw ProxyNodeError.invalidPort
                }
                self.port = p
                self.type = .Shadowsocks
            } else if uriString.lowercased().hasPrefix(ProxyNode.ssrUriPrefix) {
                let index = uriString.index(uriString.startIndex, offsetBy: ProxyNode.ssrUriPrefix.count)
                let undecodedString = String(uriString[index...])
                guard let proxyString = ProxyNode.base64DecodeUrlSafe(undecodedString),
                      let _ = proxyString.range(of: ":")?.lowerBound else {
                    throw ProxyNodeError.invalidUri
                }
                var hostString: String = proxyString
                var queryString: String = ""
                if let queryMarkIndex = proxyString.range(of: "?", options: .backwards)?.lowerBound {
                    hostString = String(proxyString[..<queryMarkIndex])
                    let index = proxyString.index(after: queryMarkIndex)
                    queryString = String(proxyString[index...])
                }
                if let hostSlashIndex = hostString.range(of: "/", options: .backwards)?.lowerBound {
                    hostString = String(hostString[..<hostSlashIndex])
                }
                let hostComps = hostString.components(separatedBy: ":")
                guard hostComps.count == 6 else {
                    throw ProxyNodeError.invalidUri
                }
                self.host = hostComps[0]
                guard let p = Int(hostComps[1]) else {
                    throw ProxyNodeError.invalidPort
                }
                self.port = p
                self.ssrProtocol = hostComps[2]
                self.authscheme = hostComps[3]
                self.ssrObfs = hostComps[4]
                self.password = ProxyNode.base64DecodeUrlSafe(hostComps[5])
                for queryComp in queryString.components(separatedBy: "&") {
                    let comps = queryComp.components(separatedBy: "=")
                    guard comps.count == 2 else {
                        continue
                    }
                    switch comps[0] {
                    case "protoparam":
                        self.ssrProtocolParam = ProxyNode.base64DecodeUrlSafe(comps[1])
                    case "obfsparam":
                        self.ssrObfsParam = ProxyNode.base64DecodeUrlSafe(comps[1])
                    case "remarks":
                        self.name = ProxyNode.base64DecodeUrlSafe(comps[1]) ?? name
                    case "ot_enable":
                        self.ssrotEnable = (Int(comps[1]) != 0)
                    case "ot_domain":
                        self.ssrotDomain = ProxyNode.base64DecodeUrlSafe(comps[1]) ?? ""
                    case "ot_path":
                        self.ssrotPath = ProxyNode.base64DecodeUrlSafe(comps[1]) ?? ""
                    default:
                        continue
                    }
                }
                self.type = .ShadowsocksR
            }else {
                // Not supported yet
                throw ProxyNodeError.invalidUri
            }
        }else {
            guard let name = dictionary["name"] as? String else{
                throw ProxyNodeError.invalidName
            }
            guard let host = dictionary["host"] as? String else{
                throw ProxyNodeError.invalidHost
            }
            guard let typeRaw = (dictionary["type"] as? String)?.uppercased(),
                  let type = ProxyNodeType(rawValue: typeRaw) else {
                throw ProxyNodeError.invalidType
            }
            guard let portStr = (dictionary["port"] as? String), let port = Int(portStr) else{
                throw ProxyNodeError.invalidPort
            }
            guard let encryption = dictionary["encryption"] as? String else{
                throw ProxyNodeError.invalidAuthScheme
            }
            guard let password = dictionary["password"] as? String else{
                throw ProxyNodeError.invalidPassword
            }
            self.host = host
            self.port = port
            self.password = password
            self.authscheme = encryption
            self.name = name
            self.type = type
        }
        if DBUtils.objectExistOf(type: ProxyNode.self, by: name) {
            let randomInt = Int.random(in: 0..<1000)
            self.name = "\(name)-\(String(format: "%04d", randomInt))"
        }
        try validate()
    }
    
    public class func base64DecodeUrlSafe(_ proxyString: String) -> String? {
        if let _ = proxyString.range(of: ":")?.lowerBound {
            return proxyString
        }
        let base64String = proxyString.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let padding = base64String.count + (base64String.count % 4 != 0 ? (4 - base64String.count % 4) : 0)
        let base64String2 = base64String.padding(toLength: padding, withPad: "=", startingAt: 0)
        if let decodedData = Data(base64Encoded: base64String2, options: NSData.Base64DecodingOptions(rawValue: 0)),
           let decodedString = NSString(data: decodedData, encoding: String.Encoding.utf8.rawValue) {
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
        return uri.lowercased().hasPrefix(ProxyNode.ssUriPrefix) || uri.lowercased().hasPrefix(ProxyNode.ssrUriPrefix)
    }
    
}

public func ==(lhs: ProxyNode, rhs: ProxyNode) -> Bool {
    return lhs.uuid == rhs.uuid
}
