//
//  SILIOPTestReconnectManager.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 07/10/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

enum SILIOPTestReconnectStatus {
    case success(discoveredPeripheral: SILDiscoveredPeripheral?, stackVersion: String)
    case failure(reason: String)
    case unknown
}

class SILIOPTestReconnectManager: NSObject {
    private let log = IOPLog()
    
    private var iopCentralManager: SILIOPTesterCentralManager!
    private var peripheral: CBPeripheral!
    private var discoveredPeripheral: SILDiscoveredPeripheral?
    private var peripheralDelegate: SILPeripheralDelegate!
    private var discoverFirmwareInfo: SILDiscoverFirmwareInfo!
    
    var nameToReconnect: String?
    var reconnectStatus: SILObservable<SILIOPTestReconnectStatus> = SILObservable(initialValue: .unknown)
    private var lastSeenMismatchedLocalName: String?
    
    private var timer: Timer?
    private var connectionTimeout: Timer?
    
    private var discoveredPeripheralSubscription: SILObservableToken?
    
    private var observableTokens = [SILObservableToken?]()
    private var disposeBag = SILObservableTokenBag()
    
    init(with peripheral: CBPeripheral, iopCentralManager: SILIOPTesterCentralManager) {
        super.init()
        self.iopCentralManager = iopCentralManager
        self.peripheral = peripheral
        self.discoverFirmwareInfo = SILDiscoverFirmwareInfo()
    }
    
    func reconnectToDevice(withName name: String) {
        self.nameToReconnect = name
        self.lastSeenMismatchedLocalName = nil
        log.retry(source: "SILIOPTestReconnectManager",
                  testID: nil,
                  attempt: 1,
                  maxAttempts: 1,
                  action: "Start reconnect scan",
                  timeoutDescription: "scan 5 s / connect 10 s")
        log.connection(source: "SILIOPTestReconnectManager",
                       action: "Looking for peripheral to reconnect",
                       peripheralName: name,
                       identifier: peripheral?.identifier)
        self.setCentralManagerSubscription()
        
        self.observeDiscoveredPeripherals()
        self.iopCentralManager.startScanning()
        self.timer = Timer.scheduledTimer(timeInterval: 5,
                                          target: self,
                                          selector: #selector(self.scanIntervalTimerFired),
                                          userInfo: nil,
                                          repeats: false)
    }
    
    private func setCentralManagerSubscription() {
        weak var weakSelf = self
        let centralManagerSubscription = iopCentralManager.newPublishConnectionStatus().observe( { connectionStatus in
            guard let weakSelf = weakSelf else { return }
            switch connectionStatus {
            case let .connected(peripheral: peripheral):
                weakSelf.log.connection(source: "SILIOPTestReconnectManager",
                                        action: "Reconnect succeeded",
                                        peripheralName: self.nameToReconnect ?? peripheral.name,
                                        identifier: peripheral.identifier)
                weakSelf.peripheral = peripheral
                weakSelf.discoveredPeripheral?.peripheral = peripheral
                weakSelf.stopConnectionTimeout()
                weakSelf.peripheralDelegate = SILPeripheralDelegate(peripheral: peripheral)
                
                weakSelf.discoverServices()
            
                
            case let .disconnected(peripheral: _, error: error):
                weakSelf.log.connection(source: "SILIOPTestReconnectManager",
                                        action: "Reconnect disconnected before completion",
                                        peripheralName: weakSelf.nameToReconnect,
                                        identifier: weakSelf.peripheral?.identifier,
                                        error: error)
                weakSelf.connectionTimeout?.invalidate()
                weakSelf.reconnectStatus.value = .failure(reason: "Disconnected peripheral with error \(String(describing: error?.localizedDescription))")
                
            case let .failToConnect(peripheral: _, error: error):
                weakSelf.log.connection(source: "SILIOPTestReconnectManager",
                                        action: "Reconnect failed to connect",
                                        peripheralName: weakSelf.nameToReconnect,
                                        identifier: weakSelf.peripheral?.identifier,
                                        error: error)
                weakSelf.connectionTimeout?.invalidate()
                weakSelf.reconnectStatus.value = .failure(reason: "Did fail to connect to peripheral with error \(String(describing: error?.localizedDescription))")
                
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    weakSelf.log.step(source: "SILIOPTestReconnectManager",
                                      action: "Bluetooth disabled during reconnect",
                                      detail: "Reconnect cannot continue.")
                    weakSelf.connectionTimeout?.invalidate()
                    weakSelf.reconnectStatus.value = .failure(reason: "Bluetooth disabled.")
                }
                
            case .unknown:
                break
            }
        })
        disposeBag.add(token: centralManagerSubscription)
        observableTokens.append(centralManagerSubscription)
    }
    
    private func discoverServices() {
        weak var weakSelf = self
        let peripheralDelegateSubscription = peripheralDelegate.newStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .successForServices(discoveredServices):
                guard let _ = discoveredServices.first(where: { service in service.uuid == SILIOPPeripheral.SILIOPTest.cbUUID }) else {
                    weakSelf.log.gatt(source: "SILIOPTestReconnectManager",
                                      operation: "Discover services",
                                      serviceUUID: SILIOPPeripheral.SILIOPTest.cbUUID,
                                      outcome: "Expected IOP Test service not found after reconnect")
                    weakSelf.reconnectStatus.value = .failure(reason: "Discovered GATT Services don't match with expected.")
                    return
                }
                weakSelf.log.gatt(source: "SILIOPTestReconnectManager",
                                  operation: "Discover services",
                                  serviceUUID: SILIOPPeripheral.SILIOPTest.cbUUID,
                                  outcome: "Found expected IOP Test service")
                weakSelf.stopConnectionTimeout()
                weakSelf.discoverFirmwareVersion()
                
            case .unknown:
                break

            default:
                weakSelf.log.step(source: "SILIOPTestReconnectManager",
                                  action: "Reconnect service discovery failed",
                                  detail: "Peripheral delegate returned an unexpected status.")
                weakSelf.reconnectStatus.value = .failure(reason: "Unknown failure from peripheral delegate.")
            }
        })
        disposeBag.add(token: peripheralDelegateSubscription)
        observableTokens.append(peripheralDelegateSubscription)
        
        startConnectionTimeout()
        peripheralDelegate.discoverServices(services: [SILIOPPeripheral.SILIOPTest.cbUUID])
    }
    
    private func discoverFirmwareVersion() {
        prepareDiscoverFirmware()
        
        weak var weakSelf = self
        let discoverFirmwareInfoSubscription = self.discoverFirmwareInfo.state.observe( { state in
            guard let weakSelf = weakSelf else { return }
            switch state {
            case .failed:
                weakSelf.log.step(source: "SILIOPTestReconnectManager",
                                  action: "Read firmware version after reconnect",
                                  detail: "Firmware discovery helper reported failure.")
                weakSelf.reconnectStatus.value = .failure(reason: "Discover firmware version failed")
                break
                
            case let .completed(stackVersion: stackVersion):
                weakSelf.invalidateObservableTokens()
                weakSelf.stopConnectionTimeout()
                weakSelf.log.step(source: "SILIOPTestReconnectManager",
                                  action: "Reconnect completed",
                                  detail: "Firmware version=\(stackVersion)")
                
                weakSelf.reconnectStatus.value = .success(discoveredPeripheral: self.discoveredPeripheral, stackVersion: stackVersion)
                break
                
            default:
                break
            }
        })
        disposeBag.add(token: discoverFirmwareInfoSubscription)
        
        startConnectionTimeout()
        discoverFirmwareInfo.run()
    }
    
    private func prepareDiscoverFirmware() {
        var parameters = ["peripheral" : self.peripheral] as [String: Any]
        parameters["peripheralDelegate"] = self.peripheralDelegate
        parameters["iopCentralManager"] = self.iopCentralManager
        
        discoverFirmwareInfo.injectParameters(parameters: parameters)
    }
    
    @objc private func scanIntervalTimerFired() {
        stopScanning()
        let failureReason: String
        if let expectedName = nameToReconnect, let observedName = lastSeenMismatchedLocalName {
            failureReason = "Post-OTA peripheral reappeared with name \(observedName) instead of expected \(expectedName)."
            log.step(source: "SILIOPTestReconnectManager",
                     action: "Reconnect scan found peripheral with unexpected post-OTA name",
                     detail: "expected=\(expectedName) | observed=\(observedName) | id=\(peripheral?.identifier.uuidString ?? "unknown")")
        } else {
            failureReason = "Post-OTA peripheral did not reappear with expected name \(nameToReconnect ?? "unknown")."
            log.step(source: "SILIOPTestReconnectManager",
                     action: "Reconnect scan timed out",
                     detail: "Target peripheral did not reappear within 5 seconds for expected name \(nameToReconnect ?? "unknown").")
        }
        self.reconnectStatus.value = .failure(reason: failureReason)
    }
    
    func stopScanning() {
        if let iopCentralManager = iopCentralManager {
            iopCentralManager.stopScanning()
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func observeDiscoveredPeripherals() {
        weak var weakSelf = self
        self.discoveredPeripheralSubscription = self.iopCentralManager.newPublishDiscoveredPeripherals().observe( { discoveredPeripherals in
            if let weakSelf = weakSelf,
               let sameUUIDPeripheral = discoveredPeripherals.first(where: { discoveredPeripheral in
                   discoveredPeripheral.peripheral?.identifier.uuidString == weakSelf.peripheral.identifier.uuidString
               }),
               let observedName = sameUUIDPeripheral.advertisedLocalName,
               let expectedName = weakSelf.nameToReconnect,
               weakSelf.reformatPeripheralName(name: observedName) != weakSelf.reformatPeripheralName(name: expectedName) {
                weakSelf.lastSeenMismatchedLocalName = observedName
            }

            let discoveredPeripheral = discoveredPeripherals.first(where: { peripheral in
                guard let weakSelf = weakSelf else { return false }
                return weakSelf.isPeripheralWithName(discoveredPeripheral: peripheral, name: self.nameToReconnect!, uuid: weakSelf.peripheral.identifier.uuidString)
            })
            
            if let discoveredPeripheral = discoveredPeripheral {
                self.discoveredPeripheral = discoveredPeripheral
                self.log.connection(source: "SILIOPTestReconnectManager",
                                    action: "Reconnect scan found target peripheral",
                                    peripheralName: discoveredPeripheral.advertisedLocalName,
                                    identifier: discoveredPeripheral.peripheral?.identifier)
                self.stopScanning()
                self.discoveredPeripheralSubscription?.invalidate()
                
                self.iopCentralManager.connect(to: discoveredPeripheral)
            }
        })
    }
    
    private func startConnectionTimeout() {
        self.connectionTimeout = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.connectionFailed), userInfo: nil, repeats: false)
    }
    
    private func stopConnectionTimeout() {
        self.connectionTimeout?.invalidate()
        self.connectionTimeout = nil
    }
    
    @objc private func connectionFailed() {
        stopConnectionTimeout()
        iopCentralManager.disconnect(peripheral: peripheral)
        log.connection(source: "SILIOPTestReconnectManager",
                       action: "Reconnect timed out",
                       peripheralName: nameToReconnect,
                       identifier: peripheral?.identifier)
        reconnectStatus.value = .failure(reason: "Post-OTA peripheral reappeared with expected name \(self.nameToReconnect ?? "unknown") but did not reconnect within 10 seconds.")
    }
        
    private func isPeripheralWithName(discoveredPeripheral: SILDiscoveredPeripheral, name: String, uuid: String) -> Bool {
        guard let localName = discoveredPeripheral.advertisedLocalName, let peripheral = discoveredPeripheral.peripheral else {
            return false
        }
            
        return reformatPeripheralName(name: localName) == reformatPeripheralName(name: name) && peripheral.identifier.uuidString == uuid
    }
    
    private func reformatPeripheralName(name: String) -> String {
        return name.uppercased()
    }
    
    func invalidateObservableTokens() {
        for token in observableTokens {
            token?.invalidate()
        }
        
        observableTokens = []
    }
}
