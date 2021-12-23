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

private let rowHeight: CGFloat = 107
private let kProxyCellIdentifier = "proxy"

class ProxyListViewController: FormViewController {

    var proxies: [Proxy?] = []
    let allowNone: Bool
    let chooseCallback: ((Proxy?) -> Void)?

    init(allowNone: Bool = false, chooseCallback: ((Proxy?) -> Void)? = nil) {
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
        reloadData()
    }

    @objc func add() {
        let vc = ProxyConfigurationViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    func reloadData() {
        proxies = DBUtils.allNotDeleted(Proxy.self, sorted: "createAt").map({ $0 })
        if allowNone {
            proxies.insert(nil, at: 0)
        }
        form.delegate = nil
        form.removeAll()
        let section = Section()
        for proxy in proxies {
            section
                <<< ProxyRow () {
                    $0.value = proxy
                }.cellSetup({ (cell, row) -> () in
                    cell.selectionStyle = .none
                }).onCellSelection({ [unowned self] (cell, row) in
                    cell.setSelected(false, animated: true)
                    let proxy = row.value
                    if let cb = self.chooseCallback {
                        cb(proxy)
                        self.close()
                    }else {
                        if proxy?.type != .none {
                            self.showProxyConfiguration(proxy)
                        }
                    }
                })
        }
        form +++ section
        form.delegate = self
        tableView?.reloadData()
    }

    func showProxyConfiguration(_ proxy: Proxy?) {
        let vc = ProxyConfigurationViewController(upstreamProxy: proxy)
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
        let ac = UIAlertController(title: "Delete item".localized(), message: "Do you really want to delete the item?".localized(), preferredStyle: .alert)
        ac.addAction( UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil) )
        let aaOK = UIAlertAction(title: "OK".localized(), style: .default) { (action) in
            guard indexPath.row < self.proxies.count, let item = (self.form[indexPath] as? ProxyRow)?.value else {
                return
            }
            do {
                try DBUtils.softDelete(item.uuid, type: Proxy.self)
                self.proxies.remove(at: indexPath.row)
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
        guard indexPath.row < proxies.count, let _ = (form[indexPath] as? ProxyRow)?.value else {
            return
        }
        let proxy = proxies[indexPath.row]
        
        let qrcode = QrCodeController()
        qrcode.qrCodeInfo = proxy?.uri
        
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
            let proxy = self.proxies[indexPath.row]
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
            let proxy = self.proxies[indexPath.row]
            if proxy?.type != .none {
                self.showProxyConfiguration(proxy)
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

}
