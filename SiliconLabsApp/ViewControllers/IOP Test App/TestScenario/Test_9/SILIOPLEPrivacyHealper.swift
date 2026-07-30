//
//  SILIOPLEPrivacyHealper.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 01/03/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit

class SILIOPLEPrivacyHealper: SILTestCaseWithRetries {
    struct SecurityTestResult {
        var passed: Bool
        var description: String
    }
    
    private var iopCentralManager: SILIOPTesterCentralManager!
    private var discoveredPeripheral: SILDiscoveredPeripheral!
    private var peripheral: CBPeripheral!
    private var peripheralDelegate: SILPeripheralDelegate!
    
    private var disposeBag = SILObservableTokenBag()
    private var observableTokens = [SILObservableToken]()
    
    private var connectionTimeout: Timer?
    private var pairingTimer: Timer?
    var retryCount: Int = 3
    private var timeout: TimeInterval = 15
    private let maxReconnectAttempts = 5
    private let reconnectTimeout: TimeInterval = 10
    
    private var iopTestPhase3TestedCharacteristicUUID: CBUUID!
    private var initialValue: String!
    private var exceptedValue: String!
    
    private var iopTestPhase3Control = SILIOPPeripheral.SILIOPTestPhase3.IOPTest_Phase3_Control.cbUUID
    private var iopTestPhase3TestedCharacteristic: CBCharacteristic!
    private var iopTestPhase3Service = SILIOPPeripheral.SILIOPTestPhase3.cbUUID
    private let log = IOPLog()
    
    var testResult: SILObservable<SecurityTestResult?> = SILObservable(initialValue: nil)
    private let NotifyTest = "0x000400"
    private let currentTestID = "7.6"
    
    init(testedCharacteristic: CBUUID, initialValue: String, exceptedValue: String) {
        self.iopTestPhase3TestedCharacteristicUUID = testedCharacteristic
        self.initialValue = initialValue
        self.exceptedValue = exceptedValue
    }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.iopCentralManager = parameters["iopCentralManager"] as? SILIOPTesterCentralManager
        self.discoveredPeripheral = parameters["discoveredPeripheral"] as? SILDiscoveredPeripheral
        self.peripheral = parameters["peripheral"] as? CBPeripheral
        self.peripheralDelegate = parameters["peripheralDelegate"] as? SILPeripheralDelegate
    }
    
    func performTestCase() {
        retryCount = maxReconnectAttempts
        pairingTimer?.invalidate()
        pairingTimer = nil
        connectionTimeout?.invalidate()
        connectionTimeout = nil

        guard let iopCentralManager = iopCentralManager else {
            self.testResult.value = SecurityTestResult(passed: false, description: "IOP central manager is nil.")
            log.step(source: "SILIOPLEPrivacyHealper", testID: currentTestID, action: "Cannot start LE Privacy test", detail: "IOP central manager is nil.")
            return
        }
        
        guard iopCentralManager.bluetoothState else {
            self.testResult.value = SecurityTestResult(passed: false, description: "Bluetooth disabled!")
            log.step(source: "SILIOPLEPrivacyHealper", testID: currentTestID, action: "Cannot start LE Privacy test", detail: "Bluetooth is disabled.")
            return
        }
        
        guard let _ = discoveredPeripheral else {
            self.testResult.value = SecurityTestResult(passed: false, description: "Discovered peripheral is nil.")
            log.step(source: "SILIOPLEPrivacyHealper", testID: currentTestID, action: "Cannot start LE Privacy test", detail: "Discovered peripheral is nil.")
            return
        }
        
        guard let _ = peripheral else {
            self.testResult.value = SecurityTestResult(passed: false, description: "Peripheral is nil.")
            log.step(source: "SILIOPLEPrivacyHealper", testID: currentTestID, action: "Cannot start LE Privacy test", detail: "Peripheral is nil.")
            return
        }
        
        guard let _ = peripheralDelegate else {
            self.testResult.value = SecurityTestResult(passed: false, description: "Peripheral delegate is nil.")
            log.step(source: "SILIOPLEPrivacyHealper", testID: currentTestID, action: "Cannot start LE Privacy test", detail: "Peripheral delegate is nil.")
            return
        }

        guard peripheral.state == .connected else {
            log.connection(source: "SILIOPLEPrivacyHealper",
                           testID: currentTestID,
                           action: "Peripheral is not connected at LE Privacy test start; reconnecting",
                           peripheralName: discoveredPeripheral?.advertisedLocalName ?? peripheral?.name,
                           identifier: peripheral?.identifier)
            setupCentralManagerSubscription()
            connectToDevice()
            return
        }
        
        setupCentralManagerObserverForUnexceptedEvents()
        setupPeripheralDelegateSubscription()
                
        guard let iopTestPhase3Service = self.peripheral.services?.first(where: { service in service.uuid == iopTestPhase3Service }) else {
            self.testResult.value = SecurityTestResult(passed: false, description: "Service Test Phase 3 didn't found.")
            log.gatt(source: "SILIOPLEPrivacyHealper", testID: currentTestID, operation: "Resolve Phase 3 service", serviceUUID: iopTestPhase3Service, outcome: "Phase 3 service not found on peripheral")
            return
        }
        
        log.step(source: "SILIOPLEPrivacyHealper",
                 testID: currentTestID,
                 action: "Start LE Privacy test",
                 detail: "controlValue=\(initialValue ?? "nil") | expectedCCCD=\(exceptedValue ?? "nil") | testedChar=\(iopTestPhase3TestedCharacteristicUUID.uuidString) | timeout=\(Int(timeout)) s | maxRetry=\(retryCount)")
        
        peripheralDelegate.discoverCharacteristics(characteristics: [iopTestPhase3TestedCharacteristicUUID, iopTestPhase3Control], for: iopTestPhase3Service)
    }
    
    private func setupCentralManagerObserverForUnexceptedEvents() {
        weak var weakSelf = self
        let centralManagerSubscription = iopCentralManager.newPublishConnectionStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .disconnected(peripheral: _, error: error):
                weakSelf.log.connection(source: "SILIOPLEPrivacyHealper",
                                        testID: weakSelf.currentTestID,
                                        action: "Unexpected disconnect during LE Privacy flow",
                                        peripheralName: weakSelf.peripheral?.name,
                                        identifier: weakSelf.peripheral?.identifier,
                                        error: error)
                weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Not allowed disconnection.")

                
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    weakSelf.log.step(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, action: "LE Privacy flow interrupted", detail: "Bluetooth was disabled.")
                    weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Bluetooth disabled.")
                }
                
            case .unknown:
                break
                
            default:
                break
            }
        })
        disposeBag.add(token: centralManagerSubscription)
        observableTokens.append(centralManagerSubscription)
    }
    
    private func setupPeripheralDelegateSubscription() {
        weak var weakSelf = self
        let peripheralDelegateSubscription = peripheralDelegate.newStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .successForCharacteristics(characteristics):
                guard let pairingCharacteristic = characteristics.first(where: { characteristic in
                    characteristic.uuid == weakSelf.iopTestPhase3TestedCharacteristicUUID
                }) else {
                    weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Tested characteristic didn't found.")
                    weakSelf.log.gatt(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, operation: "Resolve bonding characteristic", uuid: weakSelf.iopTestPhase3TestedCharacteristicUUID, serviceUUID: weakSelf.iopTestPhase3Service, outcome: "Characteristic not found")

                    return
                }
                
                weakSelf.iopTestPhase3TestedCharacteristic = pairingCharacteristic
//                if weakSelf.initialValue == weakSelf.NotifyTest {
//                    guard pairingCharacteristic.properties.contains(.notify) else {
//                        weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Characteristic doesn't have notify property.")
//                        return
//                    }
//                    weakSelf.peripheralDelegate.notifyCharacteristic(characteristic: pairingCharacteristic, enabled: true)
//                }
                for characteristic in characteristics {
                    if characteristic.uuid == weakSelf.iopTestPhase3Control, let dataToWrite = weakSelf.initialValue.data(withCount: 1) {
                        weakSelf.invalidateObservableTokens()
                        weakSelf.setupCentralManagerSubscription()
                        weakSelf.log.gatt(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, operation: "Write privacy control value", uuid: characteristic.uuid, serviceUUID: weakSelf.iopTestPhase3Service, writeType: .withResponse, value: weakSelf.initialValue, outcome: "Trigger disconnect and bonded reconnect validation")
                        weakSelf.peripheralDelegate.writeToCharacteristic(data: dataToWrite, characteristic: characteristic, writeType: .withResponse)
                        return
                    }
                }
                
                weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Failure when writing to a characteristic.")
                weakSelf.log.gatt(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, operation: "Write privacy control value", uuid: weakSelf.iopTestPhase3Control, serviceUUID: weakSelf.iopTestPhase3Service, value: weakSelf.initialValue, outcome: "Control characteristic unavailable for write")

                
            case let .successWrite(characteristic: characteristic):
                if characteristic.uuid == weakSelf.iopTestPhase3Control {
                    weakSelf.log.gatt(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, operation: "Privacy control write acknowledged", uuid: characteristic.uuid, value: weakSelf.initialValue, outcome: "Waiting for disconnect / reconnect")

                    return
                }
                
                weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Failure when writing to a characteristic.")
                weakSelf.log.gatt(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, operation: "Write characteristic", uuid: characteristic.uuid, outcome: "Unexpected characteristic acknowledged instead of control")

   
            case .unknown:
                break
                
            default:
                weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Uknown failure from peripheral delegate.")
                weakSelf.log.step(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, action: "LE Privacy peripheral delegate failure", detail: "Received an unexpected peripheral delegate status.")

            }
        })
        disposeBag.add(token: peripheralDelegateSubscription)
        observableTokens.append(peripheralDelegateSubscription)
    }
    
    private func connectToDevice(){
        guard let discoveredPeripheral = discoveredPeripheral else {
            self.testResult.value = SecurityTestResult(passed: false, description: "Discovered peripheral is nil.")
            return
        }
        
        if self.retryCount > 0 {
            let attempt = maxReconnectAttempts - self.retryCount + 1
            log.retry(source: "SILIOPLEPrivacyHealper",
                      testID: currentTestID,
                      attempt: attempt,
                      maxAttempts: maxReconnectAttempts,
                      action: "Reconnect same peripheral for LE Privacy validation",
                      timeoutDescription: "\(Int(reconnectTimeout)) s")
            self.retryCount = self.retryCount - 1
            self.connectionTimeout?.invalidate()
            self.connectionTimeout = Timer.scheduledTimer(timeInterval: reconnectTimeout, target: self, selector: #selector(self.connectionFailed), userInfo: nil, repeats: false)
            self.iopCentralManager.connect(to: discoveredPeripheral)
        } else {
            self.testResult.value = SecurityTestResult(passed: false, description: "Exceeded an allowed number of attempts.")
            log.step(source: "SILIOPLEPrivacyHealper",
                     testID: currentTestID,
                     action: "LE Privacy flow failed",
                     detail: "Exceeded the allowed number of reconnect attempts.")

        }
    }
    
    private func setupCentralManagerSubscription() {
        weak var weakSelf = self
        let centralManagerSubscription = iopCentralManager.newPublishConnectionStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .connected(peripheral: peripheral):
                weakSelf.log.connection(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, action: "Peripheral reconnected for LE Privacy validation", peripheralName: peripheral.name, identifier: peripheral.identifier)

                weakSelf.peripheral = peripheral
                weakSelf.connectionTimeout?.invalidate()
                weakSelf.peripheralDelegate.updatePeripheral(peripheral: peripheral)
                weakSelf.testResult.value = SecurityTestResult(passed: true, description: "")
                weakSelf.reconnectedPeripheralDelegateSubscription()
            case let .disconnected(peripheral: _, error: error):
                weakSelf.pairingTimer?.invalidate()
                if weakSelf.retryCount > 0 {
                    weakSelf.log.connection(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, action: "LE Privacy reconnect disconnected; retrying", peripheralName: weakSelf.discoveredPeripheral?.advertisedLocalName, identifier: weakSelf.peripheral?.identifier, error: error)
                    weakSelf.connectToDevice()
                } else {
                    weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Exceeded an allowed number of attempts.")
                    weakSelf.log.step(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, action: "LE Privacy flow failed", detail: "Exceeded allowed reconnect attempts.")

                }
                
            case let .failToConnect(peripheral: _, error: error):
                weakSelf.pairingTimer?.invalidate()
                weakSelf.connectionTimeout?.invalidate()
                weakSelf.log.connection(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, action: "LE Privacy reconnect failed", peripheralName: weakSelf.discoveredPeripheral?.advertisedLocalName, identifier: weakSelf.peripheral?.identifier, error: error)
                if weakSelf.retryCount > 0 {
                    weakSelf.connectToDevice()
                } else {
                    weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Fail to connect to peripheral with error \(String(describing: error?.localizedDescription))")
                }

                
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    weakSelf.log.step(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, action: "LE Privacy reconnect interrupted", detail: "Bluetooth was disabled.")
                    weakSelf.connectionTimeout?.invalidate()
                    weakSelf.pairingTimer?.invalidate()
                    weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Bluetooth disabled.")
                }
                
            case .unknown:
                break
            }
        })
        disposeBag.add(token: centralManagerSubscription)
        observableTokens.append(centralManagerSubscription)
    }
    
    @objc private func connectionFailed() {
        connectionTimeout?.invalidate()
        connectionTimeout = nil
        iopCentralManager.disconnect(peripheral: peripheral)
        if retryCount > 0 {
            log.step(source: "SILIOPLEPrivacyHealper", testID: currentTestID, action: "LE Privacy reconnect timed out", detail: "Peripheral was not reconnected within \(Int(reconnectTimeout)) seconds; retrying.")
            connectToDevice()
        } else {
            testResult.value = SecurityTestResult(passed: false, description: "Peripheral wasn't reconnected in 10 seconds.")
            log.step(source: "SILIOPLEPrivacyHealper", testID: currentTestID, action: "LE Privacy reconnect timed out", detail: "Peripheral was not reconnected within 10 seconds.")
        }

    }
    
    private func reconnectedPeripheralDelegateSubscription() {
        weak var weakSelf = self
        let peripheralDelegateSubscription = peripheralDelegate.newStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .successForServices(services):
                for service in services {
                    if service.uuid == weakSelf.iopTestPhase3Service {
                        weakSelf.peripheralDelegate.discoverCharacteristics(characteristics: [weakSelf.iopTestPhase3TestedCharacteristicUUID, weakSelf.iopTestPhase3Control], for: service)
                        return
                    }
                }
            
                weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Service Test Phase 3 didn't found.")
                weakSelf.log.gatt(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, operation: "Resolve Phase 3 service after reconnect", serviceUUID: weakSelf.iopTestPhase3Service, outcome: "Phase 3 service not found after reconnect")

                
            case let .successForCharacteristics(characteristics):
                guard let pairingCharacteristic = characteristics.first(where: { characteristic in
                    characteristic.uuid == weakSelf.iopTestPhase3TestedCharacteristicUUID
                }) else {
                    weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Tested characteristic didn't found.")
                    weakSelf.log.gatt(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, operation: "Resolve bonding characteristic after reconnect", uuid: weakSelf.iopTestPhase3TestedCharacteristicUUID, outcome: "Characteristic not found after reconnect")

                    return
                }
                
                weakSelf.iopTestPhase3TestedCharacteristic = pairingCharacteristic
                weakSelf.log.gatt(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, operation: "Read bonded characteristic after reconnect", uuid: pairingCharacteristic.uuid, expected: weakSelf.exceptedValue, outcome: "Verify privacy flow keeps bonded state")
                weakSelf.peripheralDelegate.readCharacteristic(characteristic: pairingCharacteristic)
                weakSelf.pairingTimer = Timer.scheduledTimer(timeInterval: weakSelf.timeout, target: self, selector: #selector(weakSelf.disconnectPeripheral), userInfo: nil, repeats: false)
                
            case let .successGetValue(value: data, characteristic: characteristic):
                guard characteristic.uuid == weakSelf.iopTestPhase3TestedCharacteristicUUID else {
                    weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Tested characteristic didn't found.")
                    weakSelf.log.gatt(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, operation: "Read bonded characteristic", uuid: characteristic.uuid, outcome: "Unexpected characteristic returned")

                    return
                }
                
                weakSelf.pairingTimer?.invalidate()
                
                if data?.hexa()  == weakSelf.exceptedValue {
                    let actualValue = data?.hexa() ?? "nil"
                    weakSelf.testResult.value = SecurityTestResult(passed: true, description: "Read \(actualValue) from \(characteristic.uuid.uuidString) after bonded reconnect, matching expected value \(weakSelf.exceptedValue ?? "nil").")
                } else if weakSelf.retryCount == 0 {
                    weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Wrong value in a characteristic.")
                    weakSelf.log.gatt(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, operation: "Read bonded characteristic", uuid: characteristic.uuid, expected: weakSelf.exceptedValue, actual: data?.hexa(), outcome: "Characteristic value did not match expected bonded state")

                }
                
            case .failure(error: _):
                weakSelf.pairingTimer?.invalidate()
                
                if weakSelf.retryCount == 0 {
                    weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Exceeded an allowed number of attempts.")
                    weakSelf.log.step(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, action: "LE Privacy flow failed", detail: "Exceeded allowed read attempts after reconnect.")

                }
                
            case .unknown:
                break
                
            default:
                weakSelf.pairingTimer?.invalidate()
                weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Unknown failure from peripheral delegate.")
                weakSelf.log.step(source: "SILIOPLEPrivacyHealper", testID: weakSelf.currentTestID, action: "LE Privacy peripheral delegate failure after reconnect", detail: "Received an unexpected peripheral delegate status.")

            }
        })
        disposeBag.add(token: peripheralDelegateSubscription)
        observableTokens.append(peripheralDelegateSubscription)
        
        peripheralDelegate.discoverServices(services: [iopTestPhase3Service])
    }
    
    @objc func disconnectPeripheral() {
        self.pairingTimer?.invalidate()
        self.pairingTimer = nil
        self.iopCentralManager.disconnect(peripheral: peripheral)
    }
    
    func stopTesting() {
        pairingTimer?.invalidate()
        connectionTimeout?.invalidate()
        invalidateObservableTokens()
    }
    
    func invalidateObservableTokens() {
        for token in observableTokens {
            token.invalidate()
        }
        
        observableTokens = []
    }
}
