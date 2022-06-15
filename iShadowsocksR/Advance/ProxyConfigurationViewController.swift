//
//  ProxyConfigurationViewController.swift
//
//  Created by LEI on 3/4/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import UIKit
import Eureka
import PotatsoLibrary
import PotatsoModel

private let kProxyFormType = "type"
private let kProxyFormName = "name"
private let kProxyFormHost = "host"
private let kProxyFormPort = "port"
private let kProxyFormEncryption = "encryption"
private let kProxyFormPassword = "password"
private let kProxyFormOta = "ota"
private let kProxyFormObfs = "obfs"
private let kProxyFormObfsParam = "obfsParam"
private let kProxyFormProtocol = "protocol"
private let kProxyFormProtocolParam = "protocolParam"

public let kSsrotEnable = "ot_enable"
public let kSsrotDomain = "ot_domain"
public let kSsrotPath = "ot_path"

class ProxyConfigurationViewController: FormViewController {
    
    var upstreamProxyNode: ProxyNode
    let isEdit: Bool
    
    override convenience init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.init()
    }
    
    init(upstreamProxyNode: ProxyNode? = nil) {
        if let proxyNode = upstreamProxyNode {
            self.upstreamProxyNode = ProxyNode(value: proxyNode)
            self.isEdit = true
        }else {
            self.upstreamProxyNode = ProxyNode()
            self.isEdit = false
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if isEdit {
            self.navigationItem.title = "Edit Proxy".localized()
        }else {
            self.navigationItem.title = "Add Proxy".localized()
        }
        generateForm()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(save))
    }
    
    func generateForm() {
        form +++ Section()
            <<< ActionSheetRow<ProxyNodeType>(kProxyFormType) {
                $0.title = "Proxy Type".localized()
                $0.options = [ProxyNodeType.Shadowsocks, ProxyNodeType.ShadowsocksR]
                $0.value = self.upstreamProxyNode.type
                $0.selectorTitle = "Choose Proxy Type".localized()
            }
            <<< TextRow(kProxyFormName) {
                $0.title = "Name".localized()
                $0.value = self.upstreamProxyNode.name
            }.cellSetup { cell, row in
                cell.textField.placeholder = "Proxy Name".localized()
            }
            <<< TextRow(kProxyFormHost) {
                $0.title = "Host".localized()
                $0.value = self.upstreamProxyNode.host
            }.cellSetup { cell, row in
                cell.textField.placeholder = "Proxy Server Host".localized()
                cell.textField.keyboardType = .URL
                cell.textField.autocorrectionType = .no
                cell.textField.autocapitalizationType = .none
            }
            <<< IntRow(kProxyFormPort) {
                $0.title = "Port".localized()
                if self.upstreamProxyNode.port > 0 {
                    $0.value = self.upstreamProxyNode.port
                }
                let numberFormatter = NumberFormatter()
                numberFormatter.locale = .current
                numberFormatter.numberStyle = .none
                numberFormatter.minimumFractionDigits = 0
                $0.formatter = numberFormatter
                }.cellSetup { cell, row in
                    cell.textField.placeholder = "Proxy Server Port".localized()
            }
            <<< ActionSheetRow<String>(kProxyFormEncryption) {
                $0.title = "Encryption".localized()
                $0.options = ProxyNode.ssSupportedEncryption
                $0.value = self.upstreamProxyNode.authscheme ?? $0.options?[8]
                $0.selectorTitle = "Choose encryption method".localized()
                $0.hidden = Condition.function([kProxyFormType]) { form in
                    if let r1 : ActionSheetRow<ProxyNodeType> = form.rowBy(tag:kProxyFormType), let isSS = r1.value?.isShadowsocks {
                        return !isSS
                    }
                    return false
                }
            }
            <<< TextRow(kProxyFormPassword) {
                $0.title = "Password".localized()
                $0.value = self.upstreamProxyNode.password ?? nil
            }.cellSetup { cell, row in
                cell.textField.placeholder = "Proxy Password".localized()
            }
            <<< SwitchRow(kProxyFormOta) {
                $0.title = "One Time Auth".localized()
                $0.value = self.upstreamProxyNode.ota
                $0.disabled = true
                $0.hidden = Condition.function([kProxyFormType]) { form in
                    if let r1 : ActionSheetRow<ProxyNodeType> = form.rowBy(tag:kProxyFormType) {
                        return r1.value != ProxyNodeType.Shadowsocks
                    }
                    return false
                }
            }
            <<< ActionSheetRow<String>(kProxyFormProtocol) {
                $0.title = "Protocol".localized()
                $0.options = ProxyNode.ssrSupportedProtocol
                $0.value = self.upstreamProxyNode.ssrProtocol ?? $0.options?[6]
                $0.selectorTitle = "Choose SSR protocol".localized()
                $0.hidden = Condition.function([kProxyFormType]) { form in
                    if let r1 : ActionSheetRow<ProxyNodeType> = form.rowBy(tag:kProxyFormType) {
                        return r1.value != ProxyNodeType.ShadowsocksR
                    }
                    return false
                }
            }
            <<< TextRow(kProxyFormProtocolParam) {
                $0.title = "Protocol Param".localized()
                $0.value = self.upstreamProxyNode.ssrProtocolParam
                $0.hidden = Condition.function([kProxyFormType]) { form in
                    if let r1 : ActionSheetRow<ProxyNodeType> = form.rowBy(tag:kProxyFormType) {
                        return r1.value != ProxyNodeType.ShadowsocksR
                    }
                    return false
                }
            }.cellSetup { cell, row in
                cell.textField.placeholder = "SSR Protocol Param".localized()
                cell.textField.autocorrectionType = .no
                cell.textField.autocapitalizationType = .none
            }
            <<< ActionSheetRow<String>(kProxyFormObfs) {
                $0.title = "Obfs".localized()
                $0.options = ProxyNode.ssrSupportedObfs
                $0.value = self.upstreamProxyNode.ssrObfs ?? $0.options?[3]
                $0.selectorTitle = "Choose SSR obfs".localized()
                $0.hidden = Condition.function([kProxyFormType]) { form in
                    if let r1 : ActionSheetRow<ProxyNodeType> = form.rowBy(tag:kProxyFormType) {
                        return r1.value != ProxyNodeType.ShadowsocksR
                    }
                    return false
                }
            }
            <<< TextRow(kProxyFormObfsParam) {
                $0.title = "Obfs Param".localized()
                $0.value = self.upstreamProxyNode.ssrObfsParam
                $0.hidden = Condition.function([kProxyFormType]) { form in
                    if let r1 : ActionSheetRow<ProxyNodeType> = form.rowBy(tag:kProxyFormType) {
                        return r1.value != ProxyNodeType.ShadowsocksR
                    }
                    return false
                }
            }.cellSetup { cell, row in
                cell.textField.placeholder = "SSR Obfs Param".localized()
                cell.textField.autocorrectionType = .no
                cell.textField.autocapitalizationType = .none
            }
            <<< SwitchRow(kSsrotEnable) { row in
                row.title = "SSRoT Enable".localized()
                row.value = self.upstreamProxyNode.ssrotEnable
                row.hidden = Condition.function([kProxyFormType]) { form in
                    if let r1 : ActionSheetRow<ProxyNodeType> = form.rowBy(tag:kProxyFormType) {
                        return r1.value != ProxyNodeType.ShadowsocksR
                    }
                    return false
                }
                row.onChange { row in
                    if let ssrotDomain : TextRow = self.form.rowBy(tag: kSsrotDomain) {
                        ssrotDomain.disabled = Condition.function([kSsrotEnable]) { form in
                            return row.value != true
                        }
                    }
                    if let ssrotPath : TextRow = self.form.rowBy(tag: kSsrotPath) {
                        ssrotPath.disabled = Condition.function([kSsrotEnable]) { form in
                            return row.value != true
                        }
                    }
                }
            }
            <<< TextRow(kSsrotDomain) {
                $0.title = "SSRoT Domain".localized()
                $0.value = self.upstreamProxyNode.ssrotDomain
                $0.hidden = Condition.function([kProxyFormType]) { form in
                    if let r1 : ActionSheetRow<ProxyNodeType> = form.rowBy(tag:kProxyFormType) {
                        return r1.value != ProxyNodeType.ShadowsocksR
                    }
                    return false
                }
                $0.disabled = Condition.function([kSsrotEnable]) { form in
                    if let r1 : SwitchRow = form.rowBy(tag:kSsrotEnable) {
                        return r1.value != true
                    }
                    return false
                }
            }.cellSetup { cell, row in
                cell.textField.placeholder = "mygooodsite.com".localized()
                cell.textField.autocorrectionType = .no
                cell.textField.autocapitalizationType = .none
            }
            <<< TextRow(kSsrotPath) {
                $0.title = "SSRoT Path".localized()
                $0.value = self.upstreamProxyNode.ssrotPath
                $0.hidden = Condition.function([kProxyFormType]) { form in
                    if let r1 : ActionSheetRow<ProxyNodeType> = form.rowBy(tag:kProxyFormType) {
                        return r1.value != ProxyNodeType.ShadowsocksR
                    }
                    return false
                }
                $0.disabled = Condition.function([kSsrotEnable]) { form in
                    if let r1 : SwitchRow = form.rowBy(tag:kSsrotEnable) {
                        return r1.value != true
                    }
                    return false
                }
            }.cellSetup { cell, row in
                cell.textField.placeholder = "/5mhk8LPOzXvjlAut/".localized()
                cell.textField.autocorrectionType = .no
                cell.textField.autocapitalizationType = .none
            }
    }
    
    @objc func save() {
        do {
            let values = form.values()
            guard let type = values[kProxyFormType] as? ProxyNodeType else {
                throw "You must choose a proxy type".localized()
            }
            guard let name = (values[kProxyFormName] as? String)?.trimmingCharacters(in: CharacterSet.whitespaces), name.count > 0 else {
                throw "Name can't be empty".localized()
            }
            if !self.isEdit {
                if DBUtils.objectExistOf(type: ProxyNode.self, by: name) {
                    throw "Name already exists".localized()
                }
            }
            guard let host = (values[kProxyFormHost] as? String)?.trimmingCharacters(in: CharacterSet.whitespaces), host.count > 0 else {
                throw "Host can't be empty".localized()
            }
            guard let port = values[kProxyFormPort] as? Int else {
                throw "Port can't be empty".localized()
            }
            guard port > 0 && port <= Int(UINT16_MAX) else {
                throw "Invalid port".localized()
            }
            var authscheme: String?
            let user: String? = nil
            var password: String?
            switch type {
            case .Shadowsocks, .ShadowsocksR:
                guard let encryption = values[kProxyFormEncryption] as? String, encryption.count > 0 else {
                    throw "You must choose a encryption method".localized()
                }
                guard let pass = values[kProxyFormPassword] as? String, pass.count > 0 else {
                    throw "Password can't be empty".localized()
                }
                authscheme = encryption
                password = pass
            default:
                break
            }
            upstreamProxyNode.type = type
            upstreamProxyNode.name = name
            upstreamProxyNode.host = host
            upstreamProxyNode.port = port
            upstreamProxyNode.authscheme = authscheme
            upstreamProxyNode.user = user
            upstreamProxyNode.password = password
            upstreamProxyNode.ota = values[kProxyFormOta] as? Bool ?? false
            upstreamProxyNode.ssrProtocol = values[kProxyFormProtocol] as? String
            upstreamProxyNode.ssrProtocolParam = values[kProxyFormProtocolParam] as? String
            upstreamProxyNode.ssrObfs = values[kProxyFormObfs] as? String
            upstreamProxyNode.ssrObfsParam = values[kProxyFormObfsParam] as? String
            
            upstreamProxyNode.ssrotEnable = values[kSsrotEnable] as? Bool ?? false
            upstreamProxyNode.ssrotDomain = values[kSsrotDomain] as? String ?? ""
            upstreamProxyNode.ssrotPath = values[kSsrotPath] as? String ?? ""
            
            try DBUtils.add(upstreamProxyNode)
            close()
        }catch {
            showTextHUD("\(error)", dismissAfterDelay: 1.0)
        }
    }

}
