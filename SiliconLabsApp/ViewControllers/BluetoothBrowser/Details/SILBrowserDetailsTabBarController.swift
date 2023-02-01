//
//  SILBrowserDetailsTabBarController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 11/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

@objcMembers
class SILBrowserDetailsTabBarController: SILTabBarController {
    private let RemoteTabIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        defaultIndex = RemoteTabIndex
        self.tabBar.isTranslucent = false
        self.tabBar.tintColor = .sil_regularBlue()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.tabBarController?.hideTabBarAndUpdateFrames()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.tabBarController?.showTabBarAndUpdateFrames()
    }
}
