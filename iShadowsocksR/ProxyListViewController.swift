//
//  ProxyListViewController.swift
//
//  Created by LEI on 5/31/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import Foundation
import PotatsoModel
import Cartography
import Eureka
import Async

class ProxyListViewController: FormViewController {

    var proxyNodes: [ProxyNode?] = []
    let allowNone: Bool
    let chooseCallback: ((ProxyNode?) -> Void)?

    init(allowNone: Bool = false, chooseCallback: ((ProxyNode?) -> Void)? = nil) {
        self.chooseCallback = chooseCallback
        self.allowNone = allowNone
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = "Proxy".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add(sender:)))
        reloadData()
    }

    @objc func add(sender: UIBarButtonItem) {
        let vc = imprortProxyNodeController(sender: sender)
        navigationController?.present(vc, animated: true, completion: nil)
    }

    func reloadData() {
        proxyNodes = DBUtils.allNotDeleted(ProxyNode.self, sorted: "createAt").map({ $0 })
        if allowNone {
            proxyNodes.insert(nil, at: 0)
        }
        form.delegate = nil
        form.removeAll()
        let section = Section()
        for proxy in proxyNodes {
            section
                <<< ProxyNodeRow () {
                    $0.value = proxy
                }.cellSetup({ (cell, row) -> () in
                    cell.selectionStyle = .none
                }).onCellSelection({ [unowned self] (cell, row) in
                    cell.setSelected(false, animated: true)
                    if let proxy = row.value {
                        if let cb = self.chooseCallback {
                            switch proxy.type {
                            case .Shadowsocks, .ShadowsocksR:
                                cb(proxy)
                                self.close()
                            default: break
                            }
                        } else {
                            if proxy.type != .None {
                                self.showProxyConfiguration(proxy)
                            }
                        }
                    }
                })
        }
        form +++ section
        form.delegate = self
        tableView?.reloadData()
    }

    func showProxyConfiguration(_ proxyNode: ProxyNode?) {
        let vc = ProxyConfigurationViewController(upstreamProxyNode: proxyNode)
        navigationController?.pushViewController(vc, animated: true)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if allowNone && indexPath.row == 0 {
            return false
        }
        return true
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            doDeleteAction(indexPath)
        }
    }
    
    func doDeleteAction(_ indexPath: IndexPath) {
        let ac = UIAlertController(title: "Delete item".localized(), message: "Do you want to delete the item really?".localized(), preferredStyle: .alert)
        ac.addAction( UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil) )
        let aaOK = UIAlertAction(title: "OK".localized(), style: .default) { (action) in
            guard indexPath.row < self.proxyNodes.count, let node = (self.form[indexPath] as? ProxyNodeRow)?.value else {
                return
            }

            if node.type == .Subscription {
                self.deleteSubscriptionNode(node)
                return
            }

            do {
                try DBUtils.softDelete(node.uuid, type: ProxyNode.self)
                self.proxyNodes.remove(at: indexPath.row)
                self.form[indexPath].hidden = true
                self.form[indexPath].evaluateHidden()
            }catch {
                self.showTextHUD("\("Fail to delete item".localized()): \((error as NSError).localizedDescription)", dismissAfterDelay: 1.5)
            }
        }
        ac.addAction(aaOK)
        self.navigationController?.present(ac, animated: true, completion: nil)
    }
    
    func doShareAction(_ indexPath:IndexPath) {
        guard indexPath.row < proxyNodes.count, let _ = (form[indexPath] as? ProxyNodeRow)?.value else {
            return
        }
        let proxyNode = proxyNodes[indexPath.row]
        
        let qrcode = QrCodeController()
        qrcode.qrCodeInfo = proxyNode?.uri
        
        self.navigationController?.pushViewController(qrcode, animated: true)
    }

    @available(iOS 11.0, *)
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete =  UIContextualAction(style: .destructive, title: "Delete".localized(), handler: { (action, view, completionHandler) in
            self.doDeleteAction(indexPath)
            completionHandler(false)
        })
        let share =  UIContextualAction(style: .normal, title: "Share".localized(), handler: { (action, view, completionHandler) in
            self.doShareAction(indexPath)
            completionHandler(true)
        })
        share.backgroundColor = UIColor.blue
        let show =  UIContextualAction(style: .normal, title: "Details".localized(), handler: { (action, view, completionHandler) in
            let proxy = self.proxyNodes[indexPath.row]
            if proxy?.type != .none {
                self.showProxyConfiguration(proxy)
            }
            completionHandler(true)
        })
        show.backgroundColor = UIColor(byteRed: 100, green: 100, blue: 255)

        return UISwipeActionsConfiguration(actions:[delete, share, show, ])
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete".localized()) { (action, indexPath) in
            self.doDeleteAction(indexPath)
        }

        let share = UITableViewRowAction(style: .normal, title: "Share".localized()) { (action, indexPath) in
            self.doShareAction(indexPath)
        }
        share.backgroundColor = UIColor.blue

        let show = UITableViewRowAction(style: .normal, title: "Details".localized()) { (action, indexPath) in
            if let node = self.proxyNodes[indexPath.row], node.type != .None {
                self.showProxyConfiguration(node)
            }
        }
        show.backgroundColor = UIColor(byteRed: 100, green: 100, blue: 255)

        return [delete, share, show, ]
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView?.tableFooterView = UIView()
        tableView?.tableHeaderView = UIView()
    }
    
    func imprortProxyNodeController(sender:NSObject) -> UIAlertController {
        let ac = UIAlertController(title: "New node".localized(), message: "Create new node from...".localized(), preferredStyle: .actionSheet)
        
        let action1 = UIAlertAction(title: "Create manually".localized(), style: .default) { action in
            let vc = ProxyConfigurationViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }
        ac.addAction(action1)

        let action2 = UIAlertAction(title: "Import From URL".localized(), style: .default) { action in
            let importer = Importer(vc: self) { success in
                if success {
                    self.reloadData()
                }
            }
            importer.importConfigFromUrl()
        }
        ac.addAction(action2)

        let action3 = UIAlertAction(title: "Import From QRCode".localized(), style: .default) { action in
            let importer = Importer(vc: self) { success in
                if success {
                    self.reloadData()
                }
            }
            importer.importConfigFromQRCode()
        }
        ac.addAction(action3)

        let action4 = UIAlertAction(title: "Import From subscription URL".localized(), style: .default) { action in
            let importer = Importer(vc: self) { success in
                if success {
                    self.parseSubscriptions()
                }
            }
            importer.importProxyNodesFromSubscriptionUrl()
        }
        ac.addAction(action4)

        let action5 = UIAlertAction(title: "Refresh subscriptions".localized(), style: .default) { action in
            self.parseSubscriptions()
        }
        ac.addAction(action5)

        let action99 = UIAlertAction(title: "Cancel".localized(), style: .cancel) { action in
            NSLog("canceled")
        }
        ac.addAction(action99)

        if let popoverPresentationController = ac.popoverPresentationController {
            if let obj = sender as? UIBarButtonItem {
                popoverPresentationController.barButtonItem = obj
            } else if let obj = sender as? UIView {
                popoverPresentationController.sourceView = obj
                popoverPresentationController.sourceRect = obj.bounds
            } else {
                assert(false)
            }
        }

        return ac
    }
    
    func deleteSubscriptionNode(_ node:ProxyNode) {
        self.showProgreeHUD("Delete subscription node...".localized())
        DBUtils.deleteSubscriptionNode(node) { success, error in
            Async.main(after: 0.1) {
                self.hideHUD()
                if !success {
                    Alert.show(self, message: "Fail to delete node".localized())
                } else {
                    self.showTextHUD("Delete node successfully".localized(), dismissAfterDelay: 1.5)
                }
                self.reloadData()
            }
        }
    }
    
    func parseSubscriptions() {
        self.showProgreeHUD("Refresh subscription nodes...".localized())
        DBUtils.refreshSubscriptions { success in
            Async.main(after: 0.1) {
                self.hideHUD()
                if !success {
                    Alert.show(self, message: "Fail to refresh nodes".localized())
                } else {
                    self.showTextHUD("Refresh nodes successfully".localized(), dismissAfterDelay: 1.5)
                    self.reloadData()
                }
            }
        }
    }
}
