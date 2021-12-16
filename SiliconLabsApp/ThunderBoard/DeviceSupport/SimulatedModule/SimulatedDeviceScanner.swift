//
//  SimulatedDeviceScanner.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

class SimulatedDeviceScanner : DeviceScanner, DeviceConnection {
    
    fileprivate var discoveryTimer: WeakTimer?
    init() {
        delay(1) {
            // simulate delayed Bluetooth initialization
            self.powerState = .enabled
        }
        
//        delay(5) {
//            // simulate disabling Bluetooth
//            self.powerState = .Disabled
//        }
//        
//        delay(7) {
//            // simulate disabling Bluetooth
//            self.powerState = .Enabled
//        }
    }
    
    //MARK: - Simulated API
    
    func simulateLostConnection(_ device: SimulatedDevice) {
        device.connectionState = .disconnected
    }
    
    //MARK: - DeviceScanner
    
    var scanningDelegate: DeviceScannerDelegate?
    func startScanning() {
        if powerState == .enabled {
            discoveryTimer = WeakTimer.scheduledTimer(0.1, repeats: true, action: { [weak self] in
                self?.simulateDiscoveredDevice()
            })
        }
    }
    
    func stopScanning() {
        discoveryTimer = nil
    }
    
    //MARK: - DeviceConnection
    
    weak var connectionDelegate: DeviceConnectionDelegate?
    var currentDevice: Device?
    func connect(_ device: Device) {
        guard let device = device as? SimulatedDevice else {
            fatalError()
        }
        
        currentDevice = device
        device.connectionState = .connecting

        delay(0.8) {
            device.connectionState = .connected
            self.connectionDelegate?.connectedToDevice(device)
        }
    }
    
    func isConnectedToDevice(_ device: Device) -> Bool {
        guard let current = currentDevice else {
            return false
        }
        
        return current.deviceIdentifier == device.deviceIdentifier
    }
    
    func disconnectAllDevices() {
        self.currentDevice = nil
    }
    
    //MARK: - Bluetooth Simulation
    
    weak var applicationDelegate: DeviceTransportPowerDelegate? {
        didSet {
            notifyDelegates()
        }
    }
    
    fileprivate var powerState: DeviceTransportState = .disabled {
        didSet {
            
            notifyDelegates()
            
            // notify implicit scanning behaviors
            switch(powerState){
            case .disabled:
                stopScanning()
                
            case .enabled:
                break
            }
        }
    }

    //MARK: - Internal
    
    fileprivate func notifyDelegates() {
        self.applicationDelegate?.transportPowerStateUpdated(powerState)
        self.scanningDelegate?.transportPowerStateUpdated(powerState)
    }
    
    fileprivate lazy var discoveredDevices: [SimulatedDevice] = {
        let reactCapabilities: Set<DeviceCapability> = [
            .temperature,
            .humidity,
            .ambientLight,
            .uvIndex,
            .calibration,
            .orientation,
            .acceleration,
            .revolutions,
        ]
        
        let senseCapabilities: Set<DeviceCapability> = [
            .temperature,
            .humidity,
            .ambientLight,
            .uvIndex,
            .airQualityCO2,
            .airQualityVOC,
            .airPressure,
            .soundLevel,
            .rgbOutput,
            .calibration,
            .orientation,
            .acceleration,
            .hallEffectState,
            .hallEffectFieldStrength,
        ]
        
        let devices: [SimulatedDevice] = [
            SimulatedDevice(name: "Thunderboard-React #58771", identifier: DeviceId(1), capabilities: reactCapabilities, model: .react),
            SimulatedDevice(name: "Thunderboard-Sense #58772", identifier: DeviceId(2), capabilities: senseCapabilities, model: .sense),
        ]
        
        return devices
    }()
    
    fileprivate func simulateDiscoveredDevice() {
        discoveredDevices.forEach({
            $0.simulatedScanner = self
            $0.RSSI = (-1 * Int(arc4random()) % 100)
            self.scanningDelegate?.discoveredDevice($0)
        })
    }
}
