//
//  SILSegmentedControl.swift
//  SiliconLabsApp
//
//  Created by Kamil Czajka on 15.12.2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

@IBDesignable
class SILSegmentedControl: UISegmentedControl {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
    }
}
