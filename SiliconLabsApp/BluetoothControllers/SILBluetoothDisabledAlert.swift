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
    case interoperabilityTest
    case throughput
    case gattConfigurator
    case blinky
    case motion
    case environment
    case wifiCommissioning
    case rssiGraph
    
    var title: String {
        "Bluetooth Disabled"
    }
    
    var message: String {
        let backMsg = "You will be redirected to the home screen."
        let turnOnMsg = "Turn on Bluetooth to"
        switch self {
        case .browser:
            return "\(backMsg) \(turnOnMsg) use Browser."
        case .advertiser:
            return "\(turnOnMsg) start any Advertiser."
        case .healthThermometer:
            return "\(backMsg) \(turnOnMsg) use Health Thermometer."
        case .rangeTest:
            return "\(backMsg) \(turnOnMsg) use Range Test."
        case .connectedLighting:
            return "\(backMsg) \(turnOnMsg) use Connected Lighting."
        case .interoperabilityTest:
            return "\(backMsg) \(turnOnMsg) run Interoperability Test."
        case .throughput:
            return "\(backMsg) \(turnOnMsg) use Throughput."
        case .gattConfigurator:
            return "\(turnOnMsg) start any GATT Server."
        case .blinky:
            return "\(backMsg) \(turnOnMsg) use Blinky."
        case .motion:
            return "\(backMsg) \(turnOnMsg) use Motion"
        case .environment:
            return "\(backMsg) \(turnOnMsg) use Environment"
        case .wifiCommissioning:
            return "\(backMsg) \(turnOnMsg) use WiFi Commissioning"
        case .rssiGraph:
            return "\(backMsg) \(turnOnMsg) use RSSI Graph"
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
