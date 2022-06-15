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
    case bobcat
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
    
    static let environmentDemoCapabilities: Set<DeviceCapability> = [
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
    
    static let ioDemoCapabilities: Set<DeviceCapability> = [
        .digitalInput,
        .digitalOutput,
        .rgbOutput
    ]
    
    static let motionDemoCapabilities: Set<DeviceCapability> = [
        .acceleration,
        .orientation,
        .calibration,
        .revolutions,
        .rgbOutput
    ]
    
    var name: String {
        switch self {
        // IO
        case .digitalInput:
            return "Switches"
        case .digitalOutput:
            return "LEDs"
        case .rgbOutput:
            return "RGB LEDs"
        
        // Enviroment
        case .temperature:
            return "Temperature"
        case .humidity:
            return "Humidity"
        case .ambientLight:
            return "Ambient Light"
        case .uvIndex:
            return "UV Index"
        case .airQualityCO2:
            return "Carbon Dioxide"
        case .airQualityVOC:
            return "VOCs"
        case .airPressure:
            return "Air Pressure"
        case .soundLevel:
            return "Sound Level"
        case .hallEffectState:
            return "Door State"
        case .hallEffectFieldStrength:
            return "Magnetic Field"
        
        // Motion
        case .calibration:
            return "Calibrate"
        case .orientation:
            return "Orientation"
        case .acceleration:
            return "Acceleration"
        case .revolutions:
            return "Hall State"

        default:
            return ""
        }
    }
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
    var missingCapabilities: Set<DeviceCapability> { get }
    
    var connectedDelegate: ConnectedDeviceDelegate? { get set }
    
    func ledColor(_ index: Int) -> LedStaticColor
    func displayName() -> String
    func isThunderboardDevice() -> Bool
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
