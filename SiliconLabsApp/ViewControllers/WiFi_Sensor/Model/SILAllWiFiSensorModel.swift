//
//  SILAllWiFiSensorModel.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 11/07/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import Foundation
enum SensorImage {
    static let temp = UIImage(named: "icon - temp")
    static let motion = UIImage(named: "WiFi_motion_icon")
    static let humidity = UIImage(named: "icon - environment")
    static let LED_Status = UIImage(named: "WiFi_led_icon")
    static let ambient = UIImage(named: "icon - light")
    static let whiteLight = UIImage(named: "icon - light")
    static let unknown = UIImage(named: "icon - environment")
}

enum SensorType: String {
    case temp = "Temperature"
    case humudity = "Humidity"
    case ambient = "Ambient Light"
    case whiteLight = "White Light"
    case led = "LED"
    case motion = "Motion"
    static let allSensors = ["Temperature", "Humidity", "Ambient Light", "White Light", "Motion", "LED"]
}
enum SensorTitle: String {
    case temperatureTitle = "Temperature"
    case humudityTitle = "Humidity"
    case ambientLightTitle = "Ambient Light"
    case whiteLightTitle = "White Light"
    case ledLightTitle = "LED"
    case motionTitle = "Motion"
}
enum SensorePopupViewName: String {
    case temperaturePopupViewTitle = "Temperature Sensor"
    case humudityPopupViewTitle = "Humidity Sensor"
    case ambientLightPopupViewTitle = "Ambient Light Sensor"
    case whiteLightPopupViewTitle = "White Light Sensor"
    case ledLightPopupViewTitle = "LED Control"
    case motionPopupViewTitle = "Motion Sensor"
}

