//
//  SILBluetoothDisabledAlert.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 22.12.2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

@objc
enum SILBluetoothDisabledAlert: Int {
    case browser
    case advertiser
    case healthThermometer
    case rangeTest
    case connectedLighting
    
    var title: String {
        "Bluetooth Disabled"
    }
    
    var message: String {
        let backMsg = "You will back to the home screen."
        let turnOnMsg = "Turn on Bluetooth to"
        switch self {
        case .browser:
            return "\(backMsg) \(turnOnMsg) using Browser."
        case .advertiser:
            return "\(turnOnMsg) start any Advertiser."
        case .healthThermometer:
            return "\(backMsg) \(turnOnMsg) using Health Thermometer."
        case .rangeTest:
            return "\(backMsg) \(turnOnMsg) using Range Test."
        case .connectedLighting:
            return "\(backMsg) \(turnOnMsg) using Connected Lighting."
        }
    }
}

@objc
class SILBluetoothDisabledAlertObjc: NSObject {
    private let bluetoothDisabledAlert: SILBluetoothDisabledAlert
    
    @objc init(bluetoothDisabledAlert: SILBluetoothDisabledAlert) {
        self.bluetoothDisabledAlert = bluetoothDisabledAlert
    }
    
    @objc func getTitle() -> String {
        return bluetoothDisabledAlert.title
    }
    
    @objc func getMessage() -> String {
        return bluetoothDisabledAlert.message
    }
}
