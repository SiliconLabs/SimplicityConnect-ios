//
//  UIButton+OutlineButton.swift
//  BlueGecko
//
//  Created by Anastazja Gradowska on 07/03/2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation

extension UIButton {
    func setupOutlineButton() {
        self.layer.borderColor = UIColor.sil_regularBlue().cgColor
        self.layer.borderWidth = 1
        self.backgroundColor = .white
        self.setTitleColor(.sil_regularBlue(), for: .normal)
    }
}
