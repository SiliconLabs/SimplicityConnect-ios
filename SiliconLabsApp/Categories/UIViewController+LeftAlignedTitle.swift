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
        
    func setCustomBackButton(title: String = "Back", action: Selector) {
        self.navigationItem.hidesBackButton = true
        let backButton = UIButton(type: .system)
        if let backImage = UIImage(systemName: "chevron.backward") {
            backButton.setImage(backImage, for: .normal)
        }
        backButton.setTitle(title, for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 21)
        backButton.tintColor = .white
        backButton.contentHorizontalAlignment = .left
        backButton.addTarget(self, action: action, for: .touchUpInside)
        // Adjust spacing between image and text
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        backButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -8)
        let backBarButton = UIBarButtonItem(customView: backButton)
        self.navigationItem.leftBarButtonItem = backBarButton
    }
}
