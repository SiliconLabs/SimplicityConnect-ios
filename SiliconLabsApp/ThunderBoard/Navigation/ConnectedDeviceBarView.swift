//
//  ConnectedDeviceBarView.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit

@IBDesignable
class ConnectedDeviceBarView: UIView {
    
    @IBOutlet weak var dot: RoundView!
    @IBOutlet weak var connectedToLabel: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var batteryStatusLabel: UILabel!
    @IBOutlet weak var batteryStatusImageView: BatteryIcon!
    @IBOutlet weak var firmwareVersionLabel: UILabel!
    var defaultValue = 0
    
    var level: Int = 0 {
        didSet {
            batteryStatusLabel.text = "\(level)%"
            switch level {
            case 0...10:
                batteryStatusImageView.level = 0
            case 11...25:
                batteryStatusImageView.level = 1
            case 26...50:
                batteryStatusImageView.level = 2
            case 51...75:
                batteryStatusImageView.level = 3
            default:
                batteryStatusImageView.level = 4
            }
        }
    }
    
    var powerType: PowerSource = .unknown {
        didSet {
            batteryStatusLabel.isHidden = powerType == .unknown
            batteryStatusImageView.isHidden = powerType == .unknown
            switch powerType {
            case .unknown:
                level = 0
            case .usb:
                level = 0
                batteryStatusImageView.image = UIImage(named: "icon - usb - opt2")
                batteryStatusLabel.text = ""
            case .aa(let level):
                self.level = level
            case .coinCell(let level):
                if level == defaultValue {
                    let initialBatteryLevel: Int = UserDefaults.standard.integer(forKey: "initialBatteryLevel")
                    self.level = initialBatteryLevel
                } else {
                    self.level = level
                }
            case .genericBattery(let level):
                self.level = level
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        deviceNameLabel.lineBreakMode = .byTruncatingMiddle
        batteryStatusLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: NSLayoutConstraint.Axis.horizontal)
    }
}
