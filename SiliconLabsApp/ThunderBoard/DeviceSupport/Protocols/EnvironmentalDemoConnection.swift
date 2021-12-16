//
//  EnvironmentDemoConnection.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

protocol EnvironmentDemoConnection: DemoConnection {
    var connectionDelegate: EnvironmentDemoConnectionDelegate? { get set }

    func resetTamper()
}

protocol EnvironmentDemoConnectionDelegate: class {
    func demoDeviceDisconnected()
    func updatedEnvironmentData(_ data: EnvironmentData)
}

extension EnvironmentDemoConnection {
    var capabilities: Set<DeviceCapability> {
        let environmentCapabilities: Set<DeviceCapability> = [
            .temperature,
            .uvIndex,
            .ambientLight,
            .humidity,
            .soundLevel,
            .airQualityCO2,
            .airQualityVOC,
            .airPressure,
            .hallEffectState,
            .hallEffectFieldStrength,
        ]
        
        // Filter AirQuality capabilities if the Sense board is on CoinCell power
        let enabledDeviceCapabilities = device.capabilities.filter({ (capability) -> Bool in
            if device.model != .sense {
                return true
            }

            switch capability {
            case .airQualityCO2: fallthrough
            case .airQualityVOC:
                switch device.power {
                case .unknown, .coinCell:
                    return false
                case .usb, .aa, .genericBattery:
                    return true
                }
                
            default:
                return true
            }
        })
        
        return environmentCapabilities.intersection(enabledDeviceCapabilities)
    }
}
