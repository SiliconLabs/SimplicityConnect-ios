//
//  BrightnessSlider.swift
//  Thunderboard
//
//  Created by Jan Wisniewski on 12/02/2020.
//  Copyright © 2020 Silicon Labs. All rights reserved.
//

import UIKit

class BrightnessSlider: UISlider {

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setMinimumTrackImage(UIImage(named: "interface - gray line"), for: .normal)
        self.setMaximumTrackImage(UIImage(named: "interface - gray line"), for: .normal)
    }
    

}
