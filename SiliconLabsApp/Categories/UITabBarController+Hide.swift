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
                            height: view.frame.height - tabBar.frame.size.height)
        tabBar.layoutIfNeeded()
    }
    
    @objc func setTabBarVisible(visible: Bool, animated: Bool, controllerHeight: NSLayoutConstraint?) {
        if (tabBarIsVisible() == visible) {
            return
        }
        
        let height = self.tabBar.frame.size.height
        let offsetY = (visible ? -height : height)
        
        let duration = (animated ? 0.5 : 0.0)
        controllerHeight?.constant = visible ? 0 : -48
        
        UIView.animate(withDuration: duration, animations: {
            let frame = self.tabBar.frame
            self.tabBar.frame = frame.offsetBy(dx: 0, dy: offsetY)
            self.view.setNeedsDisplay()
            self.view.layoutIfNeeded()
        })
    }

    private func tabBarIsVisible() -> Bool {
        return self.tabBar.frame.origin.y < view.frame.maxY
    }
}
