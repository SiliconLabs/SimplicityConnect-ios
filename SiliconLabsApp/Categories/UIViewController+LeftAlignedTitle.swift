//
//  UIViewController+LeftAlignedTitle.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 21/10/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

extension UIViewController {
    @objc func setLeftAlignedTitle(_ text: String) {
        let titleLabel = UILabel()
        titleLabel.text = text
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 21)
        
        let customTitle = UIBarButtonItem.init(customView: titleLabel)
        self.navigationItem.leftBarButtonItems = [customTitle]
        self.navigationItem.leftItemsSupplementBackButton = true
        self.navigationItem.title = ""
    }
}
