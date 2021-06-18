//
//  SILBrowserDetailsTabBar.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 13/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILBrowserDetailsTabBar: SILTabBar {
    
    override func setupIndicatorView() {
        super.setupIndicatorView()
        indicatorConstantIPadFor0 = -0.19
        indicatorConstantIPadFor1 = 0.18
        setMuliplierForSelectedIndex(0)
    }
}
