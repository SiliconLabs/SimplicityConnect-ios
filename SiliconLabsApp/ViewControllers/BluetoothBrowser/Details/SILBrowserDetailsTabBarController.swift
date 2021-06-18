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
        setupRemoteTabItem()
        setupLocalTabItem()
        self.tabBar.isTranslucent = false
    }
    
    func setupRemoteTabItem() {
        tabBar.items?[0].selectedImage = UIImage(named: SILDetailsTabBarRemoteOn)?.withRenderingMode(.alwaysOriginal)
        tabBar.items?[0].image = UIImage(named: SILDetailsTabBarRemoteOff)?.withRenderingMode(.alwaysOriginal)
    }

    func setupLocalTabItem() {
        tabBar.items?[1].selectedImage = UIImage(named: SILDetailsTabBarLocalOn)?.withRenderingMode(.alwaysOriginal)
        tabBar.items?[1].image = UIImage(named: SILDetailsTabBarLocalOff)?.withRenderingMode(.alwaysOriginal)
    }
}
