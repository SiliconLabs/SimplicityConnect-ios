//
//  SILDemoNavigationViewController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 13/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILDemoNavigationViewController: UINavigationController, UINavigationControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let demoController = viewController as? SILAppSelectionViewController, let demoApps = SILApp.demoApps() as? [SILApp] {
            demoController.appsArray = demoApps
        }
    }
}
