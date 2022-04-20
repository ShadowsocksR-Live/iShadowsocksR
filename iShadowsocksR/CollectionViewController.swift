//
//  CollectionViewController.swift
//
//  Created by LEI on 5/31/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import Foundation
import Cartography

private let rowHeight: CGFloat = 135

class CollectionViewController: SegmentPageVC {

    let pageVCs = [
        ProxyListViewController(),
    ]

    override func pageViewControllersForSegmentPageVC() -> [UIViewController] {
        return pageVCs
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showPage(0)
    }

    override func segmentsForSegmentPageVC() -> [String] {
        return ["Proxy".localized()]
    }

    override func showPage(_ index: Int) {
        if index < pageVCs.count {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add(sender:)))
        }else {
            navigationItem.rightBarButtonItem = nil
        }
        super.showPage(index)
    }

    @objc func add(sender: UIBarButtonItem) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            let ac = (self.pageVCs[0] as! ProxyListViewController).imprortProxyNodeController(sender: sender)
            self.present(ac, animated: true)
        default:
            break
        }
    }
    
}

