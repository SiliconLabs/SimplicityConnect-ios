//
//  SILAWSIoTValueCell.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 19/02/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import UIKit

class SILAWSIoTValueCell: UICollectionViewCell {
    @IBOutlet weak var canvasView: UIView!
    @IBOutlet weak var sensorIconImage: UIImageView!
    @IBOutlet weak var sensorTitleLabel: UILabel!
    @IBOutlet weak var sensorValueLabel: UILabel!
    
    @IBOutlet weak var titleTop: NSLayoutConstraint!
    let cornerRadius: CGFloat = 16.0
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupCellAppearence()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.masksToBounds = false
        backgroundColor = UIColor.clear
        addShadow(withOffset: SILCellShadowOffset, radius: SILCellShadowRadius)
    }

    private func setupCellAppearence() {
        canvasView.layer.cornerRadius = cornerRadius
    }
    
    func updateSensorValue(sensorsData: Dictionary<String, Any>) {
        //print(sensorsData)
        var valOfSensor = ""

        switch "\(sensorsData["title"] ?? "")" {
        case SensorType.temp.rawValue:
            valOfSensor = "\(sensorsData["value"] ?? "")°C"
            titleTop.constant = 5
            self.layoutIfNeeded()
        case SensorType.humudity.rawValue:
            valOfSensor = "\(sensorsData["value"] ?? "")%"
            titleTop.constant = 5
            self.layoutIfNeeded()
        case SensorType.ambient.rawValue:
            if let ambientDic: Dictionary = sensorsData["value"] as? Dictionary<String, Any> {
                valOfSensor = "\(ambientDic["ambient_light_lux"] ?? "")lx"
            }
//            valOfSensor = "\(sensorsData["value"] ?? "")"
            titleTop.constant = 5
            self.layoutIfNeeded()
        case SensorType.whiteLight.rawValue:
            if let ambientDic: Dictionary = sensorsData["value"] as? Dictionary<String, Any> {
                valOfSensor = "\(ambientDic["white_light_lux"] ?? "")lx"
            }
            titleTop.constant = 5
            self.layoutIfNeeded()
        default:
            //print("Have you done something new?")
            titleTop.constant = 15
            self.layoutIfNeeded()
        }
        sensorTitleLabel.text = "\(sensorsData["title"] ?? "")"
        sensorValueLabel.text = "\(valOfSensor)"
        if sensorsData["title"] as! String == SensorType.temp.rawValue {
            sensorIconImage.image = SensorImage.temp
        }else if sensorsData["title"] as! String == SensorType.humudity.rawValue {
            sensorIconImage.image = SensorImage.humidity
        }else if sensorsData["title"] as! String == SensorType.ambient.rawValue {
            sensorIconImage.image = SensorImage.ambient
        }else if sensorsData["title"] as! String == SensorType.led.rawValue {
            sensorIconImage.image = SensorImage.LED_Status
        }else if sensorsData["title"] as! String == SensorType.motion.rawValue {
            sensorIconImage.image = SensorImage.motion
        }
    }
}
