//
//  SILHomeTabBarController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 13/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILHomeTabBarController: SILTabBarController {
    private let DevelopTabIndex: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        defaultIndex = DevelopTabIndex
        setupDevelopTabItem()
        setupDemoTabItem()
    }
    
    func setupDemoTabItem() {
        tabBar.items?[0].selectedImage = UIImage(named: SILImageHomeTabBarDemoOn)?.withRenderingMode(.alwaysOriginal)
        tabBar.items?[0].image = UIImage(named: SILImageHomeTabBarDemoOff)?.withRenderingMode(.alwaysOriginal)
    }

    func setupDevelopTabItem() {
        tabBar.items?[1].selectedImage = UIImage(named: SILImageHomeTabBarDevelopOn)?.withRenderingMode(.alwaysOriginal)
        tabBar.items?[1].image = UIImage(named: SILImageHomeTabBarDevelopOff)?.withRenderingMode(.alwaysOriginal)
    }
}
