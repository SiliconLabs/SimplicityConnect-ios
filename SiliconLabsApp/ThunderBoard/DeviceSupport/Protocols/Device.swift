//
//  Device.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

enum DeviceConnectionState {
    case disconnected
    case connecting
    case connected
}

typealias DeviceId = UInt64
extension DeviceId {
    func toString() -> String {
        return "\(self)"
    }
}

enum DeviceModel {
    case unknown
    case react
    case sense
}

enum DeviceCapability {
    // IO
    case digitalInput   // switches
    case digitalOutput  // binary LEDs
    case rgbOutput      // RGB LEDs
    
    // Environment
    case temperature
    case humidity
    case ambientLight
    case uvIndex
    case airQualityCO2
    case airQualityVOC
    case airPressure
    case soundLevel
    case hallEffectState
    case hallEffectFieldStrength
    
    // Motion
    case calibration    // Calibrate Control
    case orientation
    case acceleration
    case revolutions    // Hall Effect
    
    // Device Details
    case powerSource
}

enum PowerSource : Equatable {
    case unknown
    case usb
    case genericBattery(Int) // React
    
    // Specifc Batteries (Sense)
    case aa(Int) // also AAA
    case coinCell(Int)
}

protocol Device : DemoConfiguration {
    var model: DeviceModel { get }
    var modelName: String { get }
    var name: String? { get }
    var advertisementDataLocalName: String? { get }
    var deviceIdentifier: DeviceId? { get }
    var RSSI: Int? { get }
    var power: PowerSource { get }
    var firmwareVersion: String? { get }
    var connectionState: DeviceConnectionState { get }
    var capabilities: Set<DeviceCapability> { get }
    
    var connectedDelegate: ConnectedDeviceDelegate? { get set }
    
    func ledColor(_ index: Int) -> LedStaticColor
    func displayName() -> String
}

func ==(lhs: PowerSource, rhs: PowerSource) -> Bool {
    switch (lhs, rhs) {
    case (.unknown, .unknown):
        return true
    case (.usb, .usb):
        return true
    case (.genericBattery, .genericBattery):
        return true
    case (.aa, .aa):
        return true
    case (.coinCell, .coinCell):
        return true
    default:
        return false
    }
}
