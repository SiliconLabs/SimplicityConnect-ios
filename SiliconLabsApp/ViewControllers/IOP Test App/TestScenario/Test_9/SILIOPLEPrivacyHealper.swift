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
    
    private var iopTestPhase3TestedCharacteristicUUID: CBUUID!
    private var initialValue: String!
    private var exceptedValue: String!
    
    private var iopTestPhase3Control = SILIOPPeripheral.SILIOPTestPhase3.IOPTest_Phase3_Control.cbUUID
    private var iopTestPhase3TestedCharacteristic: CBCharacteristic!
    private var iopTestPhase3Service = SILIOPPeripheral.SILIOPTestPhase3.cbUUID
    
    var testResult: SILObservable<SecurityTestResult?> = SILObservable(initialValue: nil)
    private let NotifyTest = "0x000400"
    
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
        guard iopCentralManager.bluetoothState else {
            self.testResult.value = SecurityTestResult(passed: false, description: "Bluetooth disabled!")
            IOPLog().iopLogSwiftFunction(message: "Bluetooth disabled!")
            return
        }
        
        guard let _ = discoveredPeripheral else {
            self.testResult.value = SecurityTestResult(passed: false, description: "Discovered peripheral is nil.")
            IOPLog().iopLogSwiftFunction(message: "Discovered peripheral is nil.")
            return
        }
        
        guard let _ = peripheral else {
            self.testResult.value = SecurityTestResult(passed: false, description: "Peripheral is nil.")
            IOPLog().iopLogSwiftFunction(message: "Peripheral is nil.")
            return
        }
        
        guard let _ = peripheralDelegate else {
            self.testResult.value = SecurityTestResult(passed: false, description: "Peripheral delegate is nil.")
            IOPLog().iopLogSwiftFunction(message: "Peripheral delegate is nil.")
            return
        }
        
        setupCentralManagerObserverForUnexceptedEvents()
        setupPeripheralDelegateSubscription()
                
        guard let iopTestPhase3Service = self.peripheral.services?.first(where: { service in service.uuid == iopTestPhase3Service }) else {
            self.testResult.value = SecurityTestResult(passed: false, description: "Service Test Phase 3 didn't found.")
            IOPLog().iopLogSwiftFunction(message: "Service Test Phase 3 didn't found.")

            return
        }
        
        peripheralDelegate.discoverCharacteristics(characteristics: [iopTestPhase3TestedCharacteristicUUID, iopTestPhase3Control], for: iopTestPhase3Service)
    }
    
    private func setupCentralManagerObserverForUnexceptedEvents() {
        weak var weakSelf = self
        let centralManagerSubscription = iopCentralManager.newPublishConnectionStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .disconnected(peripheral: _, error: error):
                debugPrint("PERIPHERAL DISCONNECTED WITH ERROR \(String(describing: error?.localizedDescription))")
                IOPLog().iopLogSwiftFunction(message: "PERIPHERAL DISCONNECTED WITH ERROR \(String(describing: error?.localizedDescription))")

                weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Not allowed disconnection.")
                IOPLog().iopLogSwiftFunction(message: "Not allowed disconnection.")

                
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    debugPrint("Bluetooth disabled!")
                    IOPLog().iopLogSwiftFunction(message: "Bluetooth disabled!")

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
                    IOPLog().iopLogSwiftFunction(message: "Tested characteristic didn't found.")

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
                        weakSelf.peripheralDelegate.writeToCharacteristic(data: dataToWrite, characteristic: characteristic, writeType: .withResponse)
                        return
                    }
                }
                
                weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Failure when writing to a characteristic.")
                IOPLog().iopLogSwiftFunction(message: "Failure when writing to a characteristic.")

                
            case let .successWrite(characteristic: characteristic):
                if characteristic.uuid == weakSelf.iopTestPhase3Control {
                    debugPrint("DID WRITE VALUE TO \(characteristic)")
                    IOPLog().iopLogSwiftFunction(message: "DID WRITE VALUE TO \(characteristic)")

                    return
                }
                
                weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Failure when writing to a characteristic.")
                IOPLog().iopLogSwiftFunction(message: "Failure when writing to a characteristic.")

   
            case .unknown:
                break
                
            default:
                weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Uknown failure from peripheral delegate.")
                IOPLog().iopLogSwiftFunction(message: "Uknown failure from peripheral delegate.")

            }
        })
        disposeBag.add(token: peripheralDelegateSubscription)
        observableTokens.append(peripheralDelegateSubscription)
    }
    
    private func connectToDevice(){
        if self.retryCount > 0 {
            
            self.retryCount = self.retryCount - 1
            self.connectionTimeout = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.connectionFailed), userInfo: nil, repeats: false)
            self.iopCentralManager.connect(to: self.discoveredPeripheral)
        } else {
            self.testResult.value = SecurityTestResult(passed: false, description: "Exceeded an allowed number of attempts.")
            IOPLog().iopLogSwiftFunction(message: "Exceeded an allowed number of attempts.")

        }
    }
    
    private func setupCentralManagerSubscription() {
        weak var weakSelf = self
        let centralManagerSubscription = iopCentralManager.newPublishConnectionStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .connected(peripheral: peripheral):
                debugPrint("PERIPHERAL CONNECTED")
                IOPLog().iopLogSwiftFunction(message: "PERIPHERAL CONNECTED")

                weakSelf.peripheral = peripheral
                weakSelf.connectionTimeout?.invalidate()
                weakSelf.peripheralDelegate.updatePeripheral(peripheral: peripheral)
                weakSelf.testResult.value = SecurityTestResult(passed: true, description: "")
                weakSelf.reconnectedPeripheralDelegateSubscription()
            case let .disconnected(peripheral: _, error: error):
                debugPrint("PERIPHERAL DISCONNECTED WITH ERROR \(String(describing: error?.localizedDescription))")
                IOPLog().iopLogSwiftFunction(message: "PERIPHERAL DISCONNECTED WITH ERROR \(String(describing: error?.localizedDescription))")

                weakSelf.pairingTimer?.invalidate()
                if weakSelf.retryCount > 0 {
                    weakSelf.retryCount = weakSelf.retryCount - 1
                    weakSelf.connectionTimeout = Timer.scheduledTimer(timeInterval: 10, target: weakSelf, selector: #selector(weakSelf.connectionFailed), userInfo: nil, repeats: false)
                    weakSelf.iopCentralManager.connect(to: weakSelf.discoveredPeripheral)
                } else {
                    weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Exceeded an allowed number of attempts.")
                    IOPLog().iopLogSwiftFunction(message: "Exceeded an allowed number of attempts.")

                }
                
            case let .failToConnect(peripheral: _, error: error):
                weakSelf.pairingTimer?.invalidate()
                weakSelf.connectionTimeout?.invalidate()
                weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Fail to connect to peripheral with error \(String(describing: error?.localizedDescription))")
                IOPLog().iopLogSwiftFunction(message: "Fail to connect to peripheral with error \(String(describing: error?.localizedDescription))")

                
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    debugPrint("Bluetooth disabled!")
                    IOPLog().iopLogSwiftFunction(message: "Bluetooth disabled!")

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
        testResult.value = SecurityTestResult(passed: false, description: "Peripheral wasn't reconnected in 10 seconds.")
        IOPLog().iopLogSwiftFunction(message: "Peripheral wasn't reconnected in 10 seconds")

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
                IOPLog().iopLogSwiftFunction(message: "Service Test Phase 3 didn't found.")

                
            case let .successForCharacteristics(characteristics):
                guard let pairingCharacteristic = characteristics.first(where: { characteristic in
                    characteristic.uuid == weakSelf.iopTestPhase3TestedCharacteristicUUID
                }) else {
                    weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Tested characteristic didn't found.")
                    IOPLog().iopLogSwiftFunction(message: "Tested characteristic didn't found.")

                    return
                }
                
                weakSelf.iopTestPhase3TestedCharacteristic = pairingCharacteristic
                weakSelf.peripheralDelegate.readCharacteristic(characteristic: pairingCharacteristic)
                weakSelf.pairingTimer = Timer.scheduledTimer(timeInterval: weakSelf.timeout, target: self, selector: #selector(weakSelf.disconnectPeripheral), userInfo: nil, repeats: false)
                
            case let .successGetValue(value: data, characteristic: characteristic):
                guard characteristic.uuid == weakSelf.iopTestPhase3TestedCharacteristicUUID else {
                    weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Tested characteristic didn't found.")
                    IOPLog().iopLogSwiftFunction(message: "Tested characteristic didn't found.")

                    return
                }
                
                weakSelf.pairingTimer?.invalidate()
                
                if data?.hexa()  == weakSelf.exceptedValue {
                    weakSelf.testResult.value = SecurityTestResult(passed: true, description: "")
                } else if weakSelf.retryCount == 0 {
                    weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Wrong value in a characteristic.")
                    IOPLog().iopLogSwiftFunction(message: "Wrong value in a characteristic.")

                }
                
            case .failure(error: _):
                weakSelf.pairingTimer?.invalidate()
                
                if weakSelf.retryCount == 0 {
                    weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Exceeded an allowed number of attempts.")
                    IOPLog().iopLogSwiftFunction(message: "Exceeded an allowed number of attempts.")

                }
                
            case .unknown:
                break
                
            default:
                weakSelf.pairingTimer?.invalidate()
                weakSelf.testResult.value = SecurityTestResult(passed: false, description: "Unknown failure from peripheral delegate.")
                IOPLog().iopLogSwiftFunction(message: "Unknown failure from peripheral delegate.")

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
