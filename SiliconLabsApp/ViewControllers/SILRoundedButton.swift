//
//  SILRoundedButton.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 27/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@IBDesignable
class SILRoundedButton: UIButton {

    override func draw(_ rect: CGRect) {
        self.layer.cornerRadius = CornerRadiusForButtons
        self.layer.masksToBounds = true
    }
    

}
