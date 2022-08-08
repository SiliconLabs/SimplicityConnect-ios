//
//  IoDemoConnection.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

protocol IoDemoConnection: DemoConnection {
    var connectionDelegate: IoDemoConnectionDelegate? { get set }

    var numberOfLeds: Int { get }
    var numberOfSwitches: Int { get }
    
    func setLed(_ led: Int, state: LedState)
    func ledState(_ led: Int) -> LedState

    func isSwitchPressed(_ switchIndex: Int) -> Bool
}

protocol IoDemoConnectionDelegate: class {
    func demoDeviceDisconnected()
    func buttonPressed(_ button: Int, pressed: Bool)
    func updatedLed(_ led: Int, state: LedState)
}

extension IoDemoConnection {
    var capabilities: Set<DeviceCapability> {
        let enabledDeviceCapabilities = device.capabilities.filter({ (capability) -> Bool in
            if device.model != .sense {
                return true
            }
            
            // Disable RGB on coin cell power
            switch capability {
            case .rgbOutput:
                switch device.power {
                case .coinCell:
                    return false
                case .usb, .aa, .genericBattery, .unknown:
                    return true
                }
                
            default:
                return true
            }
        })
        
        return DeviceCapability.ioDemoCapabilities.intersection(enabledDeviceCapabilities)
    }
    
    var missingCapabilities: Set<DeviceCapability> {
        return DeviceCapability.ioDemoCapabilities.intersection(device.missingCapabilities)
    }
}
