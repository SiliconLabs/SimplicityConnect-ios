//
//  SwitchView.swift
//  Thunderboard
//
//  Created by Jan Wisniewski on 12/02/2020.
//  Copyright © 2020 Silicon Labs. All rights reserved.
//

import UIKit

@IBDesignable
class SwitchView: UIView {
    @IBOutlet weak var switchLabel: UILabel!
    @IBOutlet weak var dot: RoundView!
    
    enum SwitchStatus: String {
        case on = "ON"
        case off = "OFF"
    }
    
    var switchStatus: SwitchStatus = .off {
        didSet {
            switch self.switchStatus {
            case .on:
                dot.isOn = true
            case .off:
                dot.isOn = false
            }
            switchLabel.text = NSLocalizedString(self.switchStatus.rawValue, comment: "")
        }
    }
}
