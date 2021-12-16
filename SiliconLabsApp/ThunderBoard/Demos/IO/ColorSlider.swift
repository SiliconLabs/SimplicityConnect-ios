//
//  ColorSlider.swift
//  Thunderboard
//
//  Created by Jan Wisniewski on 12/02/2020.
//  Copyright © 2020 Silicon Labs. All rights reserved.
//

import UIKit

@IBDesignable
class ColorSlider: UISlider {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setMinimumTrackImage(UIImage(named: "interface - color line")?.stretchableImage(withLeftCapWidth: Int(self.bounds.size.width), topCapHeight: 0), for: .normal)
        self.setMaximumTrackImage(UIImage(named: "interface - color line"), for: .normal)
    }
    
}
