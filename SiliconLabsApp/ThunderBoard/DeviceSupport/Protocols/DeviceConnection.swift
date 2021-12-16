//
//  BleConnection.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

protocol DeviceConnection: class {
    var connectionDelegate: DeviceConnectionDelegate? { get set }
    func connect(_ device: Device)
    func disconnectAllDevices()
    func isConnectedToDevice(_ device: Device) -> Bool
}

protocol DeviceConnectionDelegate: class {
    func connectedToDevice(_ device: Device)
    func connectionToDeviceTimedOut(_ device: Device)
    func connectionToDeviceFailed()
}
