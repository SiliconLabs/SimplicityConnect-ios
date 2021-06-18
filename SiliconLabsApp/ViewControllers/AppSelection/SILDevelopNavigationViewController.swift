//
//  SILDevelopNavigationViewController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 13/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILDevelopNavigationViewController: UINavigationController, UINavigationControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let developController = viewController as? SILAppSelectionViewController, let developApps = SILApp.developApps() as? [SILApp] {
            developController.appsArray = developApps
            developController.isDisconnectedIntentionally = false
            let tabBar = self.tabBarController?.tabBar as? SILTabBar
            tabBar?.setMuliplierForSelectedIndex(1)
        }
    }
}
