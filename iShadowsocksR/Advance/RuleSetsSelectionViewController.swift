//
//  ProxyRuleSetsSelectionViewController.swift
//
//  Created by LEI on 3/9/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import UIKit
import Eureka
import PotatsoLibrary
import PotatsoModel

class ProxyRuleSetsSelectionViewController: FormViewController {

    var selectedProxyRuleSets: [ProxyRuleSet]
    var callback: (([ProxyRuleSet]) -> Void)?
    var ruleSets: [ProxyRuleSet] = []
    
    init(selectedProxyRuleSets: [ProxyRuleSet], callback: (([ProxyRuleSet]) -> Void)?) {
        self.selectedProxyRuleSets = selectedProxyRuleSets
        self.callback = callback
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Choose Rule Set".localized()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        generateForm()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        selectedProxyRuleSets.removeAll()
        let values = form.values()
        for ruleSet in ruleSets {
            if let checked = values[ruleSet.name] as? Bool, checked {
                selectedProxyRuleSets.append(ruleSet)
            }
        }
        self.callback?(selectedProxyRuleSets)
    }
    
    func generateForm() {
        form.delegate = nil
        form.removeAll()
        ruleSets = defaultRealm.objects(ProxyRuleSet.self).sorted(byKeyPath: "createAt").map({ $0 })
        form +++ Section("Rule Set".localized())
        for ruleSet in ruleSets {
            form[0]
                <<< CheckRow(ruleSet.name) {
                    $0.title = ruleSet.name
                    $0.value = selectedProxyRuleSets.contains(ruleSet)
                }
        }
        form[0] <<< BaseButtonRow () {
            $0.title = "Add Rule Set".localized()
        }.cellUpdate({ (cell, row) in
            cell.textLabel?.textColor = Color.Brand
        }).onCellSelection({ [unowned self] (cell, row) -> () in
            self.showProxyRuleSetConfiguration(nil)
        })
        form.delegate = self
        tableView?.reloadData()
    }
    
    func showProxyRuleSetConfiguration(_ ruleSet: ProxyRuleSet?) {
        let vc = ProxyRuleSetConfigurationViewController(ruleSet: ruleSet)
        navigationController?.pushViewController(vc, animated: true)
    }

}
