//
//  SILSensorCell.swift
//  BlueGecko
//
//  Created by Mantosh Kumar on 05/04/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit



class SILSensorCell: UICollectionViewCell {

    @IBOutlet weak var canvasView: UIView!
    @IBOutlet weak var sensorIconImage: UIImageView!
    @IBOutlet weak var sensorTitleLabel: UILabel!
    @IBOutlet weak var sensorValueLabel: UILabel!
    
    let cornerRadius: CGFloat = 16.0

    override func awakeFromNib() {
        super.awakeFromNib()
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
        print(sensorsData)
        var valOfSensor = ""

        switch "\(sensorsData["title"] ?? "")" {
        case SensorType.temp.rawValue:
            valOfSensor = "\(sensorsData["value"] ?? "")°C"
        case SensorType.humudity.rawValue:
            valOfSensor = "\(sensorsData["value"] ?? "")%"
        case SensorType.ambient.rawValue:
            if let ambientDic: Dictionary = sensorsData["value"] as? Dictionary<String, Any> {
                valOfSensor = "\(ambientDic["ambient_light_lux"] ?? "")lx"
            }
//            valOfSensor = "\(sensorsData["value"] ?? "")"
        default:
            print("Have you done something new?")
        }
        sensorTitleLabel.text = "\(sensorsData["title"] ?? "")"
        //sensorValueLabel.text = "\(valOfSensor)"
        if sensorsData["title"] as? String == SensorType.temp.rawValue {
            sensorIconImage.image = SensorImage.temp
        }else if sensorsData["title"] as? String == SensorType.humudity.rawValue {
            sensorIconImage.image = SensorImage.humidity
        }else if sensorsData["title"] as? String == SensorType.ambient.rawValue {
            sensorIconImage.image = SensorImage.ambient
        }else if sensorsData["title"] as? String == SensorType.led.rawValue {
            sensorIconImage.image = SensorImage.LED_Status
        }else if sensorsData["title"] as? String == SensorType.motion.rawValue {
            sensorIconImage.image = SensorImage.motion
        }
    }
}
