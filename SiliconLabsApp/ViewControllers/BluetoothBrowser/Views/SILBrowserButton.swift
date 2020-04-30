//
//  SILBrowserButton.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 03/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@IBDesignable
class SILBrowserButton: UIButton {

    @IBInspectable var cornerRadius: CGFloat = CornerRadiusForButtons
    
    override func draw(_ rect: CGRect) {
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
    }

}
