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
    
    private var iopCentralManager: SILIOPTesterCentralManager!
    private var peripheral: CBPeripheral!
    private var discoveredPeripheral: SILDiscoveredPeripheral?
    private var peripheralDelegate: SILPeripheralDelegate!
    private var discoverFirmwareInfo: SILDiscoverFirmwareInfo!
    
    var nameToReconnect: String?
    var reconnectStatus: SILObservable<SILIOPTestReconnectStatus> = SILObservable(initialValue: .unknown)
    
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
                debugPrint("didConnectPeripheral**********RECONNECT")
                if let name = self.nameToReconnect {
                    debugPrint("Connected peripheral name: \(name)")
                }
                weakSelf.peripheral = peripheral
                weakSelf.discoveredPeripheral?.peripheral = peripheral
                weakSelf.stopConnectionTimeout()
                weakSelf.peripheralDelegate = SILPeripheralDelegate(peripheral: peripheral)
                
                weakSelf.discoverServices()
            
                
            case let .disconnected(peripheral: _, error: error):
                debugPrint("didDisconnectPeripheral**********RECONNECT")
                weakSelf.connectionTimeout?.invalidate()
                weakSelf.reconnectStatus.value = .failure(reason: "Disconnected peripheral with error \(String(describing: error?.localizedDescription))")
                
            case let .failToConnect(peripheral: _, error: error):
                debugPrint("didFailToConnectPeripheralRec**********RECONNECT")
                weakSelf.connectionTimeout?.invalidate()
                weakSelf.reconnectStatus.value = .failure(reason: "Did fail to connect to peripheral with error \(String(describing: error?.localizedDescription))")
                
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    debugPrint("Bluetooth disabled!")
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
                    weakSelf.reconnectStatus.value = .failure(reason: "Discovered GATT Services don't match with expected.")
                    return
                }
                weakSelf.stopConnectionTimeout()
                weakSelf.discoverFirmwareVersion()
                
            case .unknown:
                break

            default:
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
                weakSelf.reconnectStatus.value = .failure(reason: "Discover firmware version failed")
                break
                
            case let .completed(stackVersion: stackVersion):
                weakSelf.invalidateObservableTokens()
                weakSelf.stopConnectionTimeout()
                
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
        self.reconnectStatus.value = .failure(reason: "Peripheral didn't found.")
    }
    
    func stopScanning() {
        if let iopCentralManager = iopCentralManager {
            iopCentralManager.stopScanning()
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func observeDiscoveredPeripherals() {
        debugPrint("DID RECEIVE RECONNECT")
        weak var weakSelf = self
        self.discoveredPeripheralSubscription = self.iopCentralManager.newPublishDiscoveredPeripherals().observe( { discoveredPeripherals in
            let discoveredPeripheral = discoveredPeripherals.first(where: { peripheral in
                guard let weakSelf = weakSelf else { return false }
                return weakSelf.isPeripheralWithName(discoveredPeripheral: peripheral, name: self.nameToReconnect!, uuid: weakSelf.peripheral.identifier.uuidString)
            })
            
            if let discoveredPeripheral = discoveredPeripheral {
                self.discoveredPeripheral = discoveredPeripheral
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
        reconnectStatus.value = .failure(reason: "Peripheral with name \(self.nameToReconnect ?? "") wasn't reconnected in 10 seconds.")
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
