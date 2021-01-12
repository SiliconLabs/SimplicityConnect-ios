//
//  UIViewController+Alert.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 22.12.2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

@objc
extension UIViewController {
    @objc func alertWithOKButton(title: String, message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        
        let okButton = UIAlertAction(title: "OK", style: .default, handler: completion)
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
    }
}
