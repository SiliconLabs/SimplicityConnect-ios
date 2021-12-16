//
//  BatteryIcon.swift
//  Thunderboard
//
//  Created by Jan Wisniewski on 21/02/2020.
//  Copyright © 2020 Silicon Labs. All rights reserved.
//

import UIKit

class BatteryIcon: UIImageView {

    private let iconFileString: String = "icon - battery - "
    
    var level: Int = 0 {
        didSet {
            self.image = UIImage(named: "\(self.iconFileString)\(self.level)")
        }
    }

}
