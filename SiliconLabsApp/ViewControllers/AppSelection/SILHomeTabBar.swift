//
//  SILHomeTabBar.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 13/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILHomeTabBar: SILTabBar {
    override func setupIndicatorView() {
        super.setupIndicatorView()
        setIndicationOverDevelop()
    }
    
    private func setIndicationOverDevelop() {
        self.setMuliplierForSelectedIndex(1)
    }
}
