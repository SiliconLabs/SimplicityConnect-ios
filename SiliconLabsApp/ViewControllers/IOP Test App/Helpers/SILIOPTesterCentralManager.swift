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
        debugPrint("CONNECTING PERIPHERAL \(String(describing: discoveredPeripheral.peripheral))")
        self.centralManager.connect(discoveredPeripheral.peripheral)
    }
    
    func disconnect(peripheral: CBPeripheral) {
        self.centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            debugPrint("CENTRAL MANAGER powered off")
            self.stopScanningActions()
            self.publishConnectionStatus.value = .bluetoothEnabled(enabled: false)
        case .poweredOn:
            debugPrint("CENTRAL MANAGER powered on")
            self.publishConnectionStatus.value = .bluetoothEnabled(enabled: true)
        case .resetting:
            debugPrint("CENTRAL MANAGER resetting")
            self.stopScanningActions()
            self.publishConnectionStatus.value = .bluetoothEnabled(enabled: false)
        case .unauthorized:
            debugPrint("CENTRAL MANAGER unauthorized")
            self.stopScanningActions()
            self.publishConnectionStatus.value = .bluetoothEnabled(enabled: false)
        case .unknown:
            debugPrint("CENTRAL MANAGER unknown")
            self.stopScanningActions()
            self.publishConnectionStatus.value = .bluetoothEnabled(enabled: false)
        case .unsupported:
            debugPrint("CENTRAL MANAGER UNSUPPORTED")
            self.publishConnectionStatus.value = .bluetoothEnabled(enabled: false)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        debugPrint("DID DISCOVER PERIPHERAL \(peripheral)")
        if let discoveredPeripheral = self.discoveredPeripherals.first(where: { discoveredPeripheral in discoveredPeripheral.peripheral == peripheral }) {
            discoveredPeripheral.update(withAdvertisementData: advertisementData, rssi: RSSI, andDiscoveringTimestamp: Date.timeIntervalBetween1970AndReferenceDate)
        } else {
            if let newDiscoveredPeripheral = SILDiscoveredPeripheral(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI, andDiscoveringTimestamp: Date.timeIntervalBetween1970AndReferenceDate) {
                self.discoveredPeripherals.append(newDiscoveredPeripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        debugPrint("DID CONNECT \(peripheral)")
        publishConnectionStatus.value = .connected(peripheral: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        debugPrint("DID DISCONNECT \(peripheral) WITH ERROR \(error.debugDescription)")
        publishConnectionStatus.value = .disconnected(peripheral: peripheral, error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        debugPrint("DID FAIL TO CONNECT \(peripheral) WITH EROR \(error.debugDescription)")
        publishConnectionStatus.value = .failToConnect(peripheral: peripheral, error: error)
    }
}
