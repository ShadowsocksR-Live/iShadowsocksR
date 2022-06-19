//
//  Importer.swift
//
//  Created by LEI on 4/15/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import Foundation
import Async
import PotatsoModel
import PotatsoLibrary
import QRScanner

struct Importer {
    
    weak var viewController: UIViewController?
    var completion: ((Bool) -> Void)?
    
    init(vc: UIViewController, completion: ((Bool) -> Void)? = nil) {
        self.viewController = vc
        self.completion = completion
    }
    
    func importConfigFromUrl() {
        var urlTextField: UITextField?
        let alert = UIAlertController(title: "Import Config From URL".localized(), message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Input URL".localized()
            urlTextField = textField
        }
        alert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: { (action) in
            if let input = urlTextField?.text {
                self.onImportInput(input)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        viewController?.present(alert, animated: true, completion: nil)
    }
    
    func importProxyNodesFromSubscriptionUrl() {
        var urlTextField: UITextField?
        let alert = UIAlertController(title: "Import nodes from subscription URL".localized(), message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Input subscription URL".localized()
            urlTextField = textField
        }
        alert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: { (action) in
            if let input = urlTextField?.text {
                self.importSubscription(input)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        viewController?.present(alert, animated: true, completion: nil)
    }
    
    func importConfigFromQRCode() {
        let parent = self.viewController?.navigationController
        let scanner = QRScannerController()
        scanner.success = { code in
            parent?.dismiss(animated: true, completion: nil)
            if code != nil {
                self.onImportInput(code!)
            }
        }
        parent?.present(scanner, animated: true, completion: nil)
    }
    
    func onImportInput(_ result: String) {
        if ProxyNode.uriIsShadowsocks(result) {
            importSS(result)
        }else {
            NSLog("Not support anymore")
        }
    }
    
    func importSS(_ source: String) {
        do {
            let defaultName = "___scanresult"
            let proxyNode = try ProxyNode(dictionary: ["name": defaultName as AnyObject, "uri": source as AnyObject])
            var urlTextField: UITextField?
            let alert = UIAlertController(title: "Add a new proxy".localized(), message: "Please set name for the new proxy".localized(), preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "Input name".localized()
                if proxyNode.name != defaultName {
                    textField.text = proxyNode.name
                }
                urlTextField = textField
            }
            alert.addAction(UIAlertAction(title: "OK".localized(), style: .default){ (action) in
                guard let text = urlTextField?.text?.trimmingCharacters(in: CharacterSet.whitespaces) else {
                    self.onConfigSaveCallback(false, error: "Name can't be empty".localized())
                    return
                }
                proxyNode.name = text
                do {
                    try proxyNode.validate()
                    try DBUtils.add(proxyNode)
                    self.onConfigSaveCallback(true, error: nil)
                }catch {
                    self.onConfigSaveCallback(false, error: error)
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel) { action in
            })
            viewController?.present(alert, animated: true, completion: nil)
        }catch {
            self.onConfigSaveCallback(false, error: error)
        }
        if let vc = viewController {
            Alert.show(vc, message: "Fail to parse proxy config".localized())
        }
    }
    
    func onConfigSaveCallback(_ success: Bool, error: Error?) {
        Async.main(after: 0.5) {
            self.viewController?.hideHUD()
            if !success {
                var errorDesc = ""
                if let error = error {
                    errorDesc = "(\(error))"
                }
                if let vc = self.viewController {
                    Alert.show(vc, message: "\("Fail to save config.".localized()) \(errorDesc)")
                }
            }else {
                self.viewController?.showTextHUD("Import Success".localized(), dismissAfterDelay: 1.5)
            }
            self.completion?(success)
        }
    }

    func importSubscription(_ result: String) {
    }
}
