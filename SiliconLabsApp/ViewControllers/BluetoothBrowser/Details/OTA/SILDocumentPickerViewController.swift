//
//  SILDocumentPickerViewController.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 10/04/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILDocumentPickerViewController: UIDocumentPickerViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UINavigationBar.appearance().tintColor = UIView().tintColor
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIView().tintColor], for: .normal)
        UITabBar.appearance().isHidden = false
    }
}
