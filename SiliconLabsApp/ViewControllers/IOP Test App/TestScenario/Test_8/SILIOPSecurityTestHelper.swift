//
//  SILIOPSecurityTestHelper.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 26.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth

class SILIOPSecurityTestHelper: SILTestCaseWithRetries {
    struct SecurityTestResult {
        var passed: Bool
        var description: String
    }
    
    private enum ConnectionFlow {
        case idle
        case preparingToStart
        case waitingForSecurityReconnect
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
    private var remainingReconnectAttempts = 0
    private var connectionFlow: ConnectionFlow = .idle
    
    private var iopTestPhase3TestedCharacteristicUUID: CBUUID!
    private var initialValue: String!
    private var exceptedValue: String!
    
    private var iopTestPhase3Control = SILIOPPeripheral.SILIOPTestPhase3.IOPTest_Phase3_Control.cbUUID
    private var iopTestPhase3TestedCharacteristic: CBCharacteristic!
    private var iopTestPhase3Service = SILIOPPeripheral.SILIOPTestPhase3.cbUUID
    
    private let NotifyTest = "0x000400" //Added
    private let log = IOPLog()

    var testResult: SILObservable<SecurityTestResult?> = SILObservable(initialValue: nil)
    /// True while the system pairing / passkey UI may be shown; drives scenario row spinner via test case observer.
    var awaitingBluetoothPairing: SILObservable<Bool> = SILObservable(initialValue: false)
    
    init(testedCharacteristic: CBUUID, initialValue: String, exceptedValue: String) {
        self.iopTestPhase3TestedCharacteristicUUID = testedCharacteristic
        self.initialValue = initialValue
        self.exceptedValue = exceptedValue
    }
    
    private var currentTestID: String {
        switch initialValue {
        case "0x000100": return "7.2"
        case "0x000200": return "7.3"
        case "0x000300": return "7.4"
        case "0x000400": return "7.5"
        default: return "7.x"
        }
    }
    
    private var currentTestLabel: String {
        switch currentTestID {
        case "7.2": return "Security pairing"
        case "7.3": return "Security authentication"
        case "7.4": return "Security bonding"
        case "7.5": return "Security bonding reconnect"
        default: return "Security flow"
        }
    }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.iopCentralManager = parameters["iopCentralManager"] as? SILIOPTesterCentralManager
        self.discoveredPeripheral = parameters["discoveredPeripheral"] as? SILDiscoveredPeripheral
        self.peripheral = parameters["peripheral"] as? CBPeripheral
        self.peripheralDelegate = parameters["peripheralDelegate"] as? SILPeripheralDelegate
    }
    
    func performTestCase() {
        awaitingBluetoothPairing.value = false
        retryCount = 3
        remainingReconnectAttempts = maxReconnectAttempts
        connectionFlow = .idle
        pairingTimer?.invalidate()
        pairingTimer = nil
        connectionTimeout?.invalidate()
        connectionTimeout = nil
        
        guard let iopCentralManager = iopCentralManager else {
            self.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "IOP central manager is nil."))
            log.step(source: "SILIOPSecurityTestHelper", testID: currentTestID, action: "Cannot start \(currentTestLabel)", detail: "IOP central manager is nil.")
            return
        }
        
        guard iopCentralManager.bluetoothState else {
            self.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Bluetooth disabled!"))
            log.step(source: "SILIOPSecurityTestHelper", testID: currentTestID, action: "Cannot start \(currentTestLabel)", detail: "Bluetooth is disabled.")
            return
        }
        
        guard let _ = discoveredPeripheral else {
            self.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Discovered peripheral is nil."))
            log.step(source: "SILIOPSecurityTestHelper", testID: currentTestID, action: "Cannot start \(currentTestLabel)", detail: "Discovered peripheral is nil.")
            return
        }
        
        guard let _ = peripheral else {
            self.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Peripheral is nil."))
            log.step(source: "SILIOPSecurityTestHelper", testID: currentTestID, action: "Cannot start \(currentTestLabel)", detail: "Peripheral is nil.")
            return
        }
        
        guard let _ = peripheralDelegate else {
            self.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Peripheral delegate is nil."))
            log.step(source: "SILIOPSecurityTestHelper", testID: currentTestID, action: "Cannot start \(currentTestLabel)", detail: "Peripheral delegate is nil.")
            return
        }
        
        guard peripheral.state == .connected else {
            log.connection(source: "SILIOPSecurityTestHelper",
                           testID: currentTestID,
                           action: "Peripheral is not connected at security test start; reconnecting",
                           peripheralName: discoveredPeripheral?.advertisedLocalName ?? peripheral?.name,
                           identifier: peripheral?.identifier)
            startReconnectFlow(.preparingToStart)
            return
        }
        
        startSecurityValidation()
    }
    
    private func startSecurityValidation() {
        setupCentralManagerObserverForUnexceptedEvents()
        setupPeripheralDelegateSubscription()
        
        log.step(source: "SILIOPSecurityTestHelper",
                 testID: currentTestID,
                 action: "Start \(currentTestLabel)",
                 detail: "controlValue=\(initialValue ?? "nil") | expected=\(exceptedValue ?? "nil") | testedChar=\(iopTestPhase3TestedCharacteristicUUID.uuidString) | timeout=\(Int(timeout)) s | maxRetry=\(retryCount)")
        
        if let iopTestPhase3Service = self.peripheral.services?.first(where: { service in service.uuid == iopTestPhase3Service }) {
            peripheralDelegate.discoverCharacteristics(characteristics: [iopTestPhase3TestedCharacteristicUUID, iopTestPhase3Control], for: iopTestPhase3Service)
        } else {
            log.gatt(source: "SILIOPSecurityTestHelper",
                     testID: currentTestID,
                     operation: "Discover Phase 3 service before security validation",
                     serviceUUID: iopTestPhase3Service,
                     outcome: "Service cache missing; rediscovering services before running security flow")
            peripheralDelegate.discoverServices(services: [iopTestPhase3Service])
        }
    }
    
    private func publishSecurityTestOutcome(_ result: SecurityTestResult) {
        awaitingBluetoothPairing.value = false
        pairingTimer?.invalidate()
        pairingTimer = nil
        connectionTimeout?.invalidate()
        connectionTimeout = nil
        connectionFlow = .idle
        testResult.value = result
    }
    
    private func startReconnectFlow(_ flow: ConnectionFlow) {
        pairingTimer?.invalidate()
        pairingTimer = nil
        connectionTimeout?.invalidate()
        connectionTimeout = nil
        connectionFlow = flow
        remainingReconnectAttempts = maxReconnectAttempts
        invalidateObservableTokens()
        setupCentralManagerSubscription()
        attemptReconnectForCurrentFlow()
    }
    
    private func attemptReconnectForCurrentFlow() {
        guard let iopCentralManager = iopCentralManager else {
            publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "IOP central manager is nil."))
            return
        }
        guard let discoveredPeripheral = discoveredPeripheral else {
            publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Discovered peripheral is nil."))
            return
        }
        guard remainingReconnectAttempts > 0 else {
            publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Exceeded an allowed number of attempts."))
            log.step(source: "SILIOPSecurityTestHelper",
                     testID: currentTestID,
                     action: "Security flow failed",
                     detail: "Exceeded the allowed number of reconnect attempts.")
            return
        }
        
        let attempt = maxReconnectAttempts - remainingReconnectAttempts + 1
        remainingReconnectAttempts -= 1
        let action = reconnectActionDescription()
        log.retry(source: "SILIOPSecurityTestHelper",
                  testID: currentTestID,
                  attempt: attempt,
                  maxAttempts: maxReconnectAttempts,
                  action: action,
                  timeoutDescription: "\(Int(reconnectTimeout)) s")
        log.connection(source: "SILIOPSecurityTestHelper",
                       testID: currentTestID,
                       action: action,
                       peripheralName: discoveredPeripheral.advertisedLocalName ?? peripheral?.name,
                       identifier: peripheral?.identifier)
        connectionTimeout?.invalidate()
        connectionTimeout = Timer.scheduledTimer(timeInterval: reconnectTimeout,
                                                 target: self,
                                                 selector: #selector(connectionFailed),
                                                 userInfo: nil,
                                                 repeats: false)
        iopCentralManager.connect(to: discoveredPeripheral)
    }
    
    private func reconnectActionDescription() -> String {
        switch connectionFlow {
        case .preparingToStart:
            return "Reconnect same peripheral before starting security flow"
        case .waitingForSecurityReconnect:
            return "Reconnect same peripheral after security mode switch"
        case .idle:
            return "Reconnect same peripheral"
        }
    }
    
    private func signalBluetoothPairingInProgress() {
        DispatchQueue.main.async { [weak self] in
            self?.awaitingBluetoothPairing.value = true
        }
        log.step(source: "SILIOPSecurityTestHelper",
                 testID: currentTestID,
                 action: "Awaiting pairing or user security action",
                 detail: "System pairing sheet or encryption upgrade is in progress.")
    }
    
    /// Errors that commonly occur until the user completes Pair / passkey on the system sheet.
    private func isLikelyAwaitingUserPairingError(_ error: Error) -> Bool {
        let ns = error as NSError
        if ns.domain == CBATTErrorDomain {
            if ns.code == CBATTError.insufficientAuthentication.rawValue
                || ns.code == CBATTError.insufficientEncryption.rawValue {
                return true
            }
        }
        if ns.domain == CBErrorDomain, let code = CBError.Code(rawValue: ns.code) {
            switch code {
            case .encryptionTimedOut:
                return true
            default:
                break
            }
        }
        return false
    }
    
    private func setupCentralManagerObserverForUnexceptedEvents() {
        weak var weakSelf = self
        let centralManagerSubscription = iopCentralManager.newPublishConnectionStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .disconnected(peripheral: _, error: error):
                weakSelf.log.connection(source: "SILIOPSecurityTestHelper",
                                        testID: weakSelf.currentTestID,
                                        action: "Unexpected disconnect during security flow",
                                        peripheralName: weakSelf.peripheral?.name,
                                        identifier: weakSelf.peripheral?.identifier,
                                        error: error)
                weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Not allowed disconnection."))
                
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    weakSelf.log.step(source: "SILIOPSecurityTestHelper", testID: weakSelf.currentTestID, action: "Security flow interrupted", detail: "Bluetooth was disabled.")
                    weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Bluetooth disabled."))
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
            case let .successForServices(services):
                guard let iopTestPhase3Service = services.first(where: { service in service.uuid == weakSelf.iopTestPhase3Service }) else {
                    weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Service Test Phase 3 didn't found."))
                    weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                      testID: weakSelf.currentTestID,
                                      operation: "Resolve Phase 3 service",
                                      serviceUUID: weakSelf.iopTestPhase3Service,
                                      outcome: "Phase 3 service not found on peripheral")
                    return
                }
                weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                  testID: weakSelf.currentTestID,
                                  operation: "Discover security characteristics",
                                  serviceUUID: iopTestPhase3Service.uuid,
                                  outcome: "Phase 3 service found for security validation")
                weakSelf.peripheralDelegate.discoverCharacteristics(characteristics: [weakSelf.iopTestPhase3TestedCharacteristicUUID, weakSelf.iopTestPhase3Control], for: iopTestPhase3Service)
                
            case let .successForCharacteristics(characteristics):
                guard let pairingCharacteristic = characteristics.first(where: { characteristic in
                    characteristic.uuid == weakSelf.iopTestPhase3TestedCharacteristicUUID
                }) else {
                    weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Tested characteristic didn't found."))
                    weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                      testID: weakSelf.currentTestID,
                                      operation: "Resolve security characteristic",
                                      uuid: weakSelf.iopTestPhase3TestedCharacteristicUUID,
                                      serviceUUID: weakSelf.iopTestPhase3Service,
                                      outcome: "Test characteristic not found")
                    return
                }
                
                weakSelf.iopTestPhase3TestedCharacteristic = pairingCharacteristic
                //ADDED NEW...
                if weakSelf.initialValue == weakSelf.NotifyTest {
                    guard pairingCharacteristic.properties.contains(.notify) else {
                        weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Characteristic doesn't have notify property."))
                        weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                          testID: weakSelf.currentTestID,
                                          operation: "Validate notify property",
                                          uuid: pairingCharacteristic.uuid,
                                          outcome: "Characteristic does not support notify")
                        return
                    }
                    weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                      testID: weakSelf.currentTestID,
                                      operation: "Enable bonding notifications",
                                      uuid: pairingCharacteristic.uuid,
                                      outcome: "Notify path required for bonding reconnect validation")
                    weakSelf.peripheralDelegate.notifyCharacteristic(characteristic: pairingCharacteristic, enabled: true)
                }
                //END
                for characteristic in characteristics {
                    if characteristic.uuid == weakSelf.iopTestPhase3Control, let dataToWrite = weakSelf.initialValue.data(withCount: 1) {
                        weakSelf.invalidateObservableTokens()
                        weakSelf.connectionFlow = .waitingForSecurityReconnect
                        weakSelf.remainingReconnectAttempts = weakSelf.maxReconnectAttempts
                        weakSelf.setupCentralManagerSubscription()
                        if self.initialValue == "0x000400"{
                            weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                              testID: weakSelf.currentTestID,
                                              operation: "Write bonding reconnect control value",
                                              uuid: characteristic.uuid,
                                              serviceUUID: weakSelf.iopTestPhase3Service,
                                              writeType: .withResponse,
                                              value: weakSelf.initialValue,
                                              outcome: "Firmware will disconnect to validate bonded reconnect")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                weakSelf.iopCentralManager.disconnect(peripheral: weakSelf.peripheral)
                            }

                        }else{
                            weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                              testID: weakSelf.currentTestID,
                                              operation: "Write security mode control value",
                                              uuid: characteristic.uuid,
                                              serviceUUID: weakSelf.iopTestPhase3Service,
                                              writeType: .withResponse,
                                              value: weakSelf.initialValue,
                                              outcome: "Request firmware to switch security mode and disconnect")
                            weakSelf.peripheralDelegate.writeToCharacteristic(data: dataToWrite, characteristic: characteristic, writeType: .withResponse)
                        }
                            
                        return
                    }
                }
                
                weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Failure when writing to a characteristic."))
                weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                  testID: weakSelf.currentTestID,
                                  operation: "Write security control value",
                                  uuid: weakSelf.iopTestPhase3Control,
                                  serviceUUID: weakSelf.iopTestPhase3Service,
                                  value: weakSelf.initialValue,
                                  outcome: "Control characteristic unavailable for write")

                //ADDED NEW...
            case let .updateNotificationState(characteristic, _):
                if(characteristic.uuid == weakSelf.iopTestPhase3TestedCharacteristicUUID){
                    weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                      testID: weakSelf.currentTestID,
                                      operation: "Update CCCD state",
                                      uuid: characteristic.uuid,
                                      outcome: "CCCD write acknowledged on bonded characteristic")
                    return
                }
                
                weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Failure when writing to CCCD of characteristic."))
                weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                  testID: weakSelf.currentTestID,
                                  operation: "Update CCCD state",
                                  uuid: characteristic.uuid,
                                  outcome: "Unexpected characteristic returned CCCD state")
                //END
            case let .successWrite(characteristic: characteristic):
                if characteristic.uuid == weakSelf.iopTestPhase3Control {
                    weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                      testID: weakSelf.currentTestID,
                                      operation: "Control write acknowledged",
                                      uuid: characteristic.uuid,
                                      value: weakSelf.initialValue,
                                      outcome: "Waiting for disconnect / reconnect security flow")

                    return
                }
                
                weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Failure when writing to a characteristic."))
                weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                  testID: weakSelf.currentTestID,
                                  operation: "Write characteristic",
                                  uuid: characteristic.uuid,
                                  outcome: "Unexpected characteristic acknowledged instead of control")
                
            case .servicesModified:
                // Bonding / encryption often invalidates GATT; show spinner until read/write completes.
                weakSelf.signalBluetoothPairingInProgress()
                
            case let .failure(error):
                if weakSelf.isLikelyAwaitingUserPairingError(error) {
                    weakSelf.signalBluetoothPairingInProgress()
                } else {
                    weakSelf.log.step(source: "SILIOPSecurityTestHelper",
                                      testID: weakSelf.currentTestID,
                                      action: "Peripheral delegate returned failure",
                                      detail: weakSelf.log.formattedError(error))
                    weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Peripheral delegate error: \(error.localizedDescription)"))
                }
                
            case .successForDescriptors, .successGetValue, .successGetValueDescriptor, .successWriteDescriptor:
                break
                
            case .unknown:
                break
            }
        })
        disposeBag.add(token: peripheralDelegateSubscription)
        observableTokens.append(peripheralDelegateSubscription)
    }
    
    
    
    private func setupCentralManagerSubscription() {
        weak var weakSelf = self
        let centralManagerSubscription = iopCentralManager.newPublishConnectionStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .connected(peripheral: peripheral):
                weakSelf.peripheral = peripheral
                weakSelf.connectionTimeout?.invalidate()
                weakSelf.connectionTimeout = nil
                weakSelf.peripheralDelegate.updatePeripheral(peripheral: peripheral)
                
                switch weakSelf.connectionFlow {
                case .preparingToStart:
                    weakSelf.log.connection(source: "SILIOPSecurityTestHelper",
                                            testID: weakSelf.currentTestID,
                                            action: "Peripheral reconnected before security flow",
                                            peripheralName: peripheral.name,
                                            identifier: peripheral.identifier)
                    weakSelf.connectionFlow = .idle
                    weakSelf.invalidateObservableTokens()
                    weakSelf.startSecurityValidation()
                    
                case .waitingForSecurityReconnect:
                    weakSelf.log.connection(source: "SILIOPSecurityTestHelper",
                                            testID: weakSelf.currentTestID,
                                            action: "Peripheral reconnected after security mode switch",
                                            peripheralName: peripheral.name,
                                            identifier: peripheral.identifier)
                    weakSelf.reconnectedPeripheralDelegateSubscription()
                    
                case .idle:
                    break
                }
            
            case let .disconnected(peripheral: _, error: error):
                weakSelf.pairingTimer?.invalidate()
                if weakSelf.connectionFlow != .idle {
                    weakSelf.log.connection(source: "SILIOPSecurityTestHelper",
                                            testID: weakSelf.currentTestID,
                                            action: "\(weakSelf.reconnectActionDescription()); previous attempt disconnected",
                                            peripheralName: weakSelf.discoveredPeripheral?.advertisedLocalName,
                                            identifier: weakSelf.peripheral?.identifier,
                                            error: error)
                    weakSelf.connectionTimeout?.invalidate()
                    weakSelf.connectionTimeout = nil
                    weakSelf.attemptReconnectForCurrentFlow()
                } else {
                    weakSelf.log.connection(source: "SILIOPSecurityTestHelper",
                                            testID: weakSelf.currentTestID,
                                            action: "Unexpected disconnect during security flow",
                                            peripheralName: weakSelf.peripheral?.name,
                                            identifier: weakSelf.peripheral?.identifier,
                                            error: error)
                    weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Not allowed disconnection."))
                }
                
            case let .failToConnect(peripheral: _, error: error):
                weakSelf.pairingTimer?.invalidate()
                weakSelf.connectionTimeout?.invalidate()
                weakSelf.connectionTimeout = nil
                if weakSelf.connectionFlow != .idle {
                    weakSelf.log.connection(source: "SILIOPSecurityTestHelper",
                                            testID: weakSelf.currentTestID,
                                            action: "\(weakSelf.reconnectActionDescription()) failed",
                                            peripheralName: weakSelf.discoveredPeripheral?.advertisedLocalName,
                                            identifier: weakSelf.peripheral?.identifier,
                                            error: error)
                    weakSelf.attemptReconnectForCurrentFlow()
                } else {
                    weakSelf.log.connection(source: "SILIOPSecurityTestHelper",
                                            testID: weakSelf.currentTestID,
                                            action: "Reconnect failed",
                                            peripheralName: weakSelf.discoveredPeripheral?.advertisedLocalName,
                                            identifier: weakSelf.peripheral?.identifier,
                                            error: error)
                    weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Fail to connect to peripheral with error \(String(describing: error?.localizedDescription))"))
                }
                
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    weakSelf.log.step(source: "SILIOPSecurityTestHelper", testID: weakSelf.currentTestID, action: "Reconnect interrupted", detail: "Bluetooth was disabled.")
                    weakSelf.connectionTimeout?.invalidate()
                    weakSelf.pairingTimer?.invalidate()
                    weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Bluetooth disabled."))
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
        if connectionFlow != .idle && remainingReconnectAttempts > 0 {
            log.step(source: "SILIOPSecurityTestHelper",
                     testID: currentTestID,
                     action: "Reconnect timed out; retrying",
                     detail: "Peripheral was not reconnected within \(Int(reconnectTimeout)) seconds.")
            attemptReconnectForCurrentFlow()
        } else {
            publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Peripheral wasn't reconnected in 10 seconds."))
            log.step(source: "SILIOPSecurityTestHelper",
                     testID: currentTestID,
                     action: "Reconnect timed out",
                     detail: "Peripheral was not reconnected within \(Int(reconnectTimeout)) seconds.")
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
                
                weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Service Test Phase 3 didn't found."))
                weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                  testID: weakSelf.currentTestID,
                                  operation: "Resolve Phase 3 service after reconnect",
                                  serviceUUID: weakSelf.iopTestPhase3Service,
                                  outcome: "Phase 3 service not found after reconnect")

                
            case let .successForCharacteristics(characteristics):
                guard let pairingCharacteristic = characteristics.first(where: { characteristic in
                    characteristic.uuid == weakSelf.iopTestPhase3TestedCharacteristicUUID
                }) else {
                    weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Tested characteristic didn't found."))
                    weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                      testID: weakSelf.currentTestID,
                                      operation: "Resolve security characteristic after reconnect",
                                      uuid: weakSelf.iopTestPhase3TestedCharacteristicUUID,
                                      outcome: "Characteristic not found after reconnect")

                    return
                }
                
                weakSelf.iopTestPhase3TestedCharacteristic = pairingCharacteristic
                //Comented
                //weakSelf.peripheralDelegate.readCharacteristic(characteristic: pairingCharacteristic)
                //weakSelf.pairingTimer = Timer.scheduledTimer(timeInterval: weakSelf.timeout, target: self, selector: #selector(weakSelf.disconnectPeripheral), userInfo: nil, repeats: false)
                //ADDED NEW
                if weakSelf.initialValue == weakSelf.NotifyTest {
                    weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                      testID: weakSelf.currentTestID,
                                      operation: "Discover CCCD for bonded characteristic",
                                      uuid: pairingCharacteristic.uuid,
                                      outcome: "Reading CCCD persistence after bonded reconnect")
                    weakSelf.peripheralDelegate.discoverDescriptors(for: pairingCharacteristic)
                    return
                }else{
                    weakSelf.iopTestPhase3TestedCharacteristic = pairingCharacteristic
                    weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                      testID: weakSelf.currentTestID,
                                      operation: "Read security characteristic after reconnect",
                                      uuid: pairingCharacteristic.uuid,
                                      expected: weakSelf.exceptedValue,
                                      outcome: "Verify security level after reconnect")
                    weakSelf.peripheralDelegate.readCharacteristic(characteristic: pairingCharacteristic)
                    weakSelf.pairingTimer = Timer.scheduledTimer(timeInterval: weakSelf.timeout, target: self, selector: #selector(weakSelf.disconnectPeripheral), userInfo: nil, repeats: false)
                }
                
            case let .successForDescriptors(descriptors):
                guard let pairingDescriptor = descriptors.first(where: { descriptor in
                    descriptor.uuid.uuidString == CBUUIDClientCharacteristicConfigurationString
                }) else {
                    weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Tested descriptor didn't found."))
                    weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                      testID: weakSelf.currentTestID,
                                      operation: "Resolve CCCD descriptor",
                                      uuid: weakSelf.iopTestPhase3TestedCharacteristicUUID,
                                      outcome: "CCCD descriptor not found")

                    return
                }
                weakSelf.peripheralDelegate.readDescriptor(descriptor: pairingDescriptor)
                
            case let .successGetValueDescriptor(value: data, descriptor: descriptor):
                guard descriptor.uuid.uuidString == CBUUIDClientCharacteristicConfigurationString else {
                    weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Tested descriptor didn't found."))
                    weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                      testID: weakSelf.currentTestID,
                                      operation: "Read CCCD descriptor",
                                      outcome: "Unexpected descriptor returned")

                    return
                }
                let valueDescriptor = (data as? NSNumber)?.stringValue
                if valueDescriptor != weakSelf.exceptedValue {
                    weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Wrong value in Client Characteristic Configuration Descriptor."))
                    weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                      testID: weakSelf.currentTestID,
                                      operation: "Read CCCD descriptor",
                                      expected: weakSelf.exceptedValue,
                                      actual: valueDescriptor,
                                      outcome: "CCCD value did not persist across reconnect")

                    return
                }
                weakSelf.peripheralDelegate.notifyCharacteristic(characteristic: descriptor.characteristic!, enabled: false)
                //END
            case let .successGetValue(value: data, characteristic: characteristic):
                guard characteristic.uuid == weakSelf.iopTestPhase3TestedCharacteristicUUID else {
                    weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Tested characteristic didn't found."))
                    weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                      testID: weakSelf.currentTestID,
                                      operation: "Read security characteristic",
                                      uuid: characteristic.uuid,
                                      outcome: "Unexpected characteristic returned")

                    return
                }
                
                weakSelf.pairingTimer?.invalidate()
                
                if data?.hexa()  == weakSelf.exceptedValue {
                    let actualValue = data?.hexa() ?? "nil"
                    weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: true, description: "Read \(actualValue) from \(characteristic.uuid.uuidString) after \(weakSelf.currentTestLabel.lowercased()) flow, matching expected value \(weakSelf.exceptedValue ?? "nil")."))
                } else if weakSelf.retryCount == 0 {
                    weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Wrong value in a characteristic."))
                    weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                      testID: weakSelf.currentTestID,
                                      operation: "Read security characteristic",
                                      uuid: characteristic.uuid,
                                      expected: weakSelf.exceptedValue,
                                      actual: data?.hexa(),
                                      outcome: "Characteristic value did not match expected security state")
                }
                //ADDED NEW
            case let .updateNotificationState(characteristic, _):
                if(characteristic.uuid == weakSelf.iopTestPhase3TestedCharacteristicUUID){
                    weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                      testID: weakSelf.currentTestID,
                                      operation: "Disable bonded notification after CCCD validation",
                                      uuid: characteristic.uuid,
                                      expected: weakSelf.exceptedValue,
                                      outcome: "CCCD state was preserved across bonded reconnect")
                    weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: true, description: "CCCD value \(weakSelf.exceptedValue ?? "nil") was preserved on \(characteristic.uuid.uuidString) after bonded reconnect."))
                    return
                }
                
                weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Failure when writing to CCCD of characteristic."))
                weakSelf.log.gatt(source: "SILIOPSecurityTestHelper",
                                  testID: weakSelf.currentTestID,
                                  operation: "Disable bonded notification after CCCD validation",
                                  uuid: characteristic.uuid,
                                  outcome: "Unexpected characteristic returned CCCD state")

                //END
            case let .failure(error):
                weakSelf.pairingTimer?.invalidate()
                
                if weakSelf.retryCount > 0, weakSelf.isLikelyAwaitingUserPairingError(error) {
                    weakSelf.signalBluetoothPairingInProgress()
                    return
                }
                
                if weakSelf.retryCount == 0 {
                    weakSelf.publishSecurityTestOutcome(SecurityTestResult(passed: false, description: "Exceeded an allowed number of attempts."))
                    weakSelf.log.step(source: "SILIOPSecurityTestHelper", testID: weakSelf.currentTestID, action: "Security flow failed", detail: "Exceeded allowed reconnect/read attempts.")

                }
                
            case .servicesModified:
                weakSelf.signalBluetoothPairingInProgress()
                
            case .successWrite(characteristic: let characteristic):
                if characteristic.uuid == weakSelf.iopTestPhase3Control {
                    return
                }
                break
                
            case .successWriteDescriptor:
                break
                
            case .unknown:
                break
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
        pairingTimer = nil
        connectionTimeout = nil
        connectionFlow = .idle
        remainingReconnectAttempts = 0
        invalidateObservableTokens()
    }
    
    func invalidateObservableTokens() {
        for token in observableTokens {
            token.invalidate()
        }
        
        observableTokens = []
    }
}
