//
//  IndexViewController.swift
//
//  Created by LEI on 5/27/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import Foundation
import PotatsoLibrary
import PotatsoModel
import Eureka
import ICDMaterialActivityIndicatorView
import Cartography

private let kFormName = "name"
private let kFormDNS = "dns"
private let kFormProxies = "proxies"
private let kFormDefaultToProxy = "defaultToProxy"

class HomeVC: FormViewController, UINavigationControllerDelegate, HomePresenterProtocol, UITextFieldDelegate {

    let presenter = HomePresenter()

    var status: VPNStatus {
        didSet {
            updateConnectButton(by: status)
        }
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.status = .off
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        presenter.bindToVC(self)
        presenter.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Fix a UI stuck bug
        navigationController?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.titleView = titleButton
        // Post an empty message so we could attach to packet tunnel process
        Manager.sharedManager.postMessage()
        handleRefreshUI()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: "List".templateImage, style: .plain, target: presenter, action: #selector(HomePresenter.chooseConfigGroups))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: presenter, action: #selector(HomePresenter.showAddConfigGroup))
    }

    // MARK: - HomePresenter Protocol

    func handleRefreshUI() {
        if presenter.group.isDefault {
            status = Manager.sharedManager.vpnStatus
        }else {
            status = .off
        }
        updateTitle()
        updateForm()
    }

    func updateTitle() {
        titleButton.setTitle(presenter.group.name, for: .normal)
        titleButton.sizeToFit()
    }

    func updateForm() {
        form.delegate = nil
        form.removeAll()
        form +++ generateProxySection()
        form.delegate = self
        tableView?.reloadData()
    }

    func updateConnectButton(by value: VPNStatus) {
        connectButton.isEnabled = [VPNStatus.on, VPNStatus.off].contains(value)
        connectButton.setTitleColor(UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: UIControlState())
        switch value {
        case .connecting, .disconnecting:
            connectButton.animating = true
        default:
            connectButton.setTitle(value.hintDescription, for: .normal)
            connectButton.animating = false
        }
        connectButton.backgroundColor = value.color
    }

    // MARK: - Form

    func generateProxySection() -> Section {
        let proxySection = Section()
        if let proxyNode = presenter.proxyNode {
            proxySection <<< ProxyNodeRow(kFormProxies) {
                $0.value = proxyNode
            }.cellSetup({ (cell, row) -> () in
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            }).onCellSelection({ [unowned self](cell, row) -> () in
                cell.setSelected(false, animated: true)
                self.presenter.chooseProxy()
            })
        }else {
            proxySection <<< LabelRow() {
                $0.title = "Proxy".localized()
                $0.value = "None".localized()
            }.cellSetup({ (cell, row) -> () in
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            }).onCellSelection({ [unowned self](cell, row) -> () in
                cell.setSelected(false, animated: true)
                self.presenter.chooseProxy()
            })
        }

        proxySection <<< SwitchRow(kFormDefaultToProxy) {
            $0.title = "Default To Proxy".localized()
            $0.value = presenter.group.defaultToProxy
            $0.hidden = Condition.function([kFormProxies]) { [unowned self] form in
                return self.presenter.proxyNode == nil
            }
        }.onChange({ [unowned self] (row) in
            DBUtils.writeSharedRealm(completionQueue: .main) { error in
                if error == nil {
                    self.presenter.group.defaultToProxy = row.value ?? true
                } else {
                    self.showTextHUD("\("Fail to modify default to proxy".localized()): \((error! as NSError).localizedDescription)", dismissAfterDelay: 1.5)
                }
            }
        })
        <<< TextRow(kFormDNS) {
            $0.title = "DNS".localized()
            $0.value = presenter.group.dns
        }.cellSetup { cell, row in
            cell.textField.placeholder = "System DNS".localized()
            cell.textField.autocorrectionType = .no
            cell.textField.autocapitalizationType = .none
        }
        return proxySection
    }

    // MARK: - Private Actions

    @objc func handleConnectButtonPressed() {
        if status == .on {
            status = .disconnecting
        }else {
            status = .connecting
        }
        presenter.switchVPN()
    }

    @objc func handleTitleButtonPressed() {
        presenter.changeGroupName()
    }

    // MARK: - TableView

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            DBUtils.writeSharedRealm(completionQueue: .main) { error in
                if error == nil {
                    self.presenter.group.ruleSets.remove(at: indexPath.row)
                    self.form[indexPath].hidden = true
                    self.form[indexPath].evaluateHidden()
                } else {
                    self.showTextHUD("\("Fail to delete item".localized()): \((error! as NSError).localizedDescription)", dismissAfterDelay: 1.5)
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }

    // MARK: - TextRow

    override func textInputDidEndEditing<T>(_ textInput: UITextInput, cell: Cell<T>) {
        guard let textField = textInput as? UITextField, let dnsString = textField.text, cell.row.tag == kFormDNS else {
            return
        }
        presenter.updateDNS(dnsString)
        textField.text = presenter.group.dns
    }

    // MARK: - View Setup

    fileprivate let connectButtonHeight: CGFloat = 48

    override func loadView() {
        super.loadView()
        view.backgroundColor = Color.Background
        view.addSubview(connectButton)
        setupLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubview(toFront: connectButton)
        tableView?.contentInset = UIEdgeInsetsMake(0, 0, connectButtonHeight, 0)
    }

    func setupLayout() {
        constrain(connectButton, view) { connectButton, view in
            connectButton.trailing == view.trailing
            connectButton.leading == view.leading
            connectButton.height == connectButtonHeight
            connectButton.bottom == view.bottom
        }
    }

    lazy var connectButton: FlatButton = {
        let v = FlatButton(frame: CGRect.zero)
        v.addTarget(self, action: #selector(HomeVC.handleConnectButtonPressed), for: .touchUpInside)
        return v
    }()

    lazy var titleButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setTitleColor(UIColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0), for: UIControlState())
        b.addTarget(self, action: #selector(HomeVC.handleTitleButtonPressed), for: .touchUpInside)
        if let titleLabel = b.titleLabel {
            titleLabel.font = UIFont.boldSystemFont(ofSize: titleLabel.font.pointSize)
        }
        return b
    }()

}

extension VPNStatus {

    var color: UIColor {
        switch self {
        case .on, .disconnecting:
            return Color.StatusOn
        case .off, .connecting:
            return Color.StatusOff
        }
    }

    var hintDescription: String {
        switch self {
        case .on, .disconnecting:
            return "Disconnect".localized()
        case .off, .connecting:
            return "Connect".localized()
        }
    }
}
