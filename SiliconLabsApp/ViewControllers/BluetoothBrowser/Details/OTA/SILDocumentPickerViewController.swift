//
//  SILDocumentPickerViewController.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 10/04/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILDocumentPickerViewController: UIDocumentPickerViewController {
    private var originalTabBarTitlePosition: UIOffset?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UINavigationBar.appearance().tintColor = UIView().tintColor
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIView().tintColor], for: .normal)
        self.originalTabBarTitlePosition = UITabBarItem.appearance().titlePositionAdjustment
        UITabBarItem.appearance().titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 0)
        UITabBar.appearance().isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UITabBarItem.appearance().titlePositionAdjustment = originalTabBarTitlePosition!
    }
}
