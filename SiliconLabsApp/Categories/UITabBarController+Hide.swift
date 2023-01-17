//
//  UITabBarController+Hide.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 12/12/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

extension UITabBarController {
    @objc func hideTabBarAndUpdateFrames() {
        tabBar.isHidden = true
        view.frame = CGRect(x: view.frame.origin.x,
                            y: view.frame.origin.y,
                            width: view.frame.size.width,
                            height: view.frame.height + tabBar.bounds.size.height)
    }
    
    @objc func showTabBarAndUpdateFrames() {
        tabBar.isHidden = false
        view.frame = CGRect(x: view.frame.origin.x,
                            y: view.frame.origin.y,
                            width: view.frame.size.width,
                            height: view.frame.height - tabBar.bounds.size.height)
    }
}
