//
//  DeviceScanner.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

protocol DeviceScanner: class {
    var scanningDelegate: DeviceScannerDelegate? { get set }
    
    func startScanning()
    func stopScanning()
}

protocol DeviceScannerDelegate: DeviceTransportPowerDelegate {
    func discoveredDevice(_ device: Device)
}
