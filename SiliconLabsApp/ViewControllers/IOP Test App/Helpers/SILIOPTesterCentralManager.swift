//
//  SILIOPTesterCentralManager.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 26.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth

enum SILIOPTesterCentralManagerConnectionStatus {
    case connected(peripheral: CBPeripheral)
    case disconnected(peripheral: CBPeripheral, error: Error?)
    case failToConnect(peripheral: CBPeripheral, error: Error?)
    case bluetoothEnabled(enabled: Bool)
    case unknown
}

@objcMembers class SILIOPTesterCentralManager: NSObject, CBCentralManagerDelegate {
    private let log = IOPLog()
    private var centralManager: CBCentralManager!
    private var shouldScan = false
    
    private var discoveredPeripherals: [SILDiscoveredPeripheral] = []
    var publishDiscoveredPeripherals: SILObservable<[SILDiscoveredPeripheral]> = SILObservable(initialValue: [])
    var publishConnectionStatus: SILObservable<SILIOPTesterCentralManagerConnectionStatus> = SILObservable(initialValue: .unknown)
    private var timer: Timer?
    
    var bluetoothState: Bool {
        get {
            centralManager.state == .poweredOn
        }
    }
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func newPublishConnectionStatus() -> SILObservable<SILIOPTesterCentralManagerConnectionStatus> {
        publishConnectionStatus = SILObservable(initialValue: .bluetoothEnabled(enabled: centralManager.state == .poweredOn))
        return publishConnectionStatus
    }
    
    func newPublishDiscoveredPeripherals() -> SILObservable<[SILDiscoveredPeripheral]> {
        publishDiscoveredPeripherals = SILObservable(initialValue: [])
        return publishDiscoveredPeripherals
    }

    func startScanning() {
        if !self.shouldScan {
            self.shouldScan = true

            if self.centralManager.state == .poweredOn {
                self.startScanningActions()
            }
        }
    }
    
    fileprivate func startScanningActions() {
        self.centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        self.timer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(publishPeripherals), userInfo: nil, repeats: true)
    }
    
    @objc func publishPeripherals() {
        self.publishDiscoveredPeripherals.value = self.discoveredPeripherals
    }
    
    func stopScanning() {
        if self.shouldScan {
            self.shouldScan = false
            self.stopScanningActions()
        }
    }
    
    fileprivate func stopScanningActions() {
        self.centralManager.stopScan()
        if let timer = self.timer {
            timer.invalidate()
        }
        self.discoveredPeripherals = []
    }
    
    func connect(to discoveredPeripheral: SILDiscoveredPeripheral) {
        guard let peripheral = discoveredPeripheral.peripheral else {
            log.step(source: "SILIOPTesterCentralManager",
                     action: "Cannot connect to discovered peripheral",
                     detail: "Discovered peripheral object is nil.")
            return
        }
        log.connection(source: "SILIOPTesterCentralManager",
                       action: "Connecting to peripheral",
                       peripheralName: peripheral.name,
                       identifier: peripheral.identifier)
        
        //self.centralManager.connect(peripheral)
        let deviceUUID = UserDefaults.standard.value(forKey: "deviceUUIDToConnect")
        guard let peripheralUUID: String = deviceUUID as? String else {
            return
        }
        if peripheral.identifier.uuidString  == peripheralUUID{
            self.centralManager.connect(peripheral)
        }
    }
    
    func disconnect(peripheral: CBPeripheral) {
        self.centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            log.step(source: "SILIOPTesterCentralManager", action: "Bluetooth central state changed", detail: "State=poweredOff")
            self.stopScanningActions()
            self.publishConnectionStatus.value = .bluetoothEnabled(enabled: false)
        case .poweredOn:
            log.step(source: "SILIOPTesterCentralManager", action: "Bluetooth central state changed", detail: "State=poweredOn")
            self.publishConnectionStatus.value = .bluetoothEnabled(enabled: true)
        case .resetting:
            log.step(source: "SILIOPTesterCentralManager", action: "Bluetooth central state changed", detail: "State=resetting")
            self.stopScanningActions()
            self.publishConnectionStatus.value = .bluetoothEnabled(enabled: false)
        case .unauthorized:
            log.step(source: "SILIOPTesterCentralManager", action: "Bluetooth central state changed", detail: "State=unauthorized")
            self.stopScanningActions()
            self.publishConnectionStatus.value = .bluetoothEnabled(enabled: false)
        case .unknown:
            log.step(source: "SILIOPTesterCentralManager", action: "Bluetooth central state changed", detail: "State=unknown")
            self.stopScanningActions()
            self.publishConnectionStatus.value = .bluetoothEnabled(enabled: false)
        case .unsupported:
            log.step(source: "SILIOPTesterCentralManager", action: "Bluetooth central state changed", detail: "State=unsupported")
            self.publishConnectionStatus.value = .bluetoothEnabled(enabled: false)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let discoveredPeripheral = self.discoveredPeripherals.first(where: { discoveredPeripheral in discoveredPeripheral.peripheral == peripheral }) {
            discoveredPeripheral.update(withAdvertisementData: advertisementData, rssi: RSSI, andDiscoveringTimestamp: Date.timeIntervalBetween1970AndReferenceDate)
        } else {
            //let newDiscoveredPeripheral = SILDiscoveredPeripheral(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI, andDiscoveringTimestamp: Date.timeIntervalBetween1970AndReferenceDate)
            //self.discoveredPeripherals.append(newDiscoveredPeripheral)
            let deviceUUID = UserDefaults.standard.value(forKey: "deviceUUIDToConnect")
            guard let peripheralUUID: String = deviceUUID as? String else {
                return
            }
            if peripheral.identifier.uuidString  == peripheralUUID {
                log.connection(source: "SILIOPTesterCentralManager",
                               action: "Discovered target peripheral during scan",
                               peripheralName: peripheral.name,
                               identifier: peripheral.identifier)
                let newDiscoveredPeripheral = SILDiscoveredPeripheral(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI, andDiscoveringTimestamp: Date.timeIntervalBetween1970AndReferenceDate)
                self.discoveredPeripherals.append(newDiscoveredPeripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log.emit(source: "SILIOPTesterCentralManager",
                 message: "Did connect to peripheral | \(log.peripheralSummary(peripheral))")

        publishConnectionStatus.value = .connected(peripheral: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log.emit(source: "SILIOPTesterCentralManager",
                 message: "Did disconnect from peripheral | \(log.peripheralSummary(peripheral)) | error=\(log.formattedError(error))")

        publishConnectionStatus.value = .disconnected(peripheral: peripheral, error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log.emit(source: "SILIOPTesterCentralManager",
                 message: "Failed to connect to peripheral | \(log.peripheralSummary(peripheral)) | error=\(log.formattedError(error))")

        publishConnectionStatus.value = .failToConnect(peripheral: peripheral, error: error)
    }
}
