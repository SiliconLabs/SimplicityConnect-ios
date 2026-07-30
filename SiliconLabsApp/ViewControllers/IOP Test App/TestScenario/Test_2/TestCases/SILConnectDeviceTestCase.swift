//
//  SILConnectDeviceTestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILConnectDeviceTestCase: SILTestCase, SILTestCaseTimeout, SILTestCaseWithRetries {
    private let log = IOPLog()
    var testID: String = "2"
    var testName: String = "IOP BLE Connect"
    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)
    
    var timeoutMS: Int64 = 1000
    var startTime: Int64?
    var stopTime: Int64?
    private var connectTimer: Timer?
    
    var retryCount: Int = 5
    
    private var iopCentralManager: SILIOPTesterCentralManager!
    private var discoveredPeripheral: SILDiscoveredPeripheral!
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private var cbPeripheral: CBPeripheral?
    
    init() { }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.iopCentralManager = parameters["iopCentralManager"] as? SILIOPTesterCentralManager
        self.discoveredPeripheral = parameters["discoveredPeripheral"] as? SILDiscoveredPeripheral
    }
    
    func performTestCase() {
        guard iopCentralManager.bluetoothState else {
            self.publishTestResult(passed: false, description: "Bluetooth disabled!")
            return
        }
        
        guard let _ = discoveredPeripheral else {
            self.publishTestResult(passed: false, description: "Diiscovered peripheral is nil.")
            return
        }

        publishStartTestEvent()
        log.step(source: "SILConnectDeviceTestCase",
                 testID: testID,
                 action: "Start BLE connect test",
                 detail: "timeout=\(timeoutMS) ms | maxRetry=\(retryCount) | peripheral=\(discoveredPeripheral?.advertisedLocalName ?? "unknown")")
        connectToPeripheral()
    }
    
    @objc func stopConnecting() {
        self.connectTimer?.invalidate()
        self.connectTimer = nil
        
        invalidateObservableTokens()
        
        retryCount = retryCount - 1
        if retryCount > 0 {
            let attemptNumber = 6 - retryCount
            log.retry(source: "SILConnectDeviceTestCase",
                      testID: testID,
                      attempt: attemptNumber,
                      maxAttempts: 5,
                      action: "Retry BLE connect test",
                      timeoutDescription: "\(timeoutMS) ms")
            connectToPeripheral()
        } else {
            notifyError()
        }
    }
        
    private func connectToPeripheral() {
        weak var weakSelf = self
        let centralManagerSubscription = iopCentralManager.newPublishConnectionStatus().observe( { connectionStatus in
            guard let weakSelf = weakSelf else { return }
            switch connectionStatus {
            case let .connected(peripheral: peripheral):
                weakSelf.cbPeripheral = peripheral
                weakSelf.connectTimer?.invalidate()
                let testTime = weakSelf.stopTestTimerWithResult()
                if testTime < weakSelf.timeoutMS {
                    weakSelf.log.connection(source: "SILConnectDeviceTestCase",
                                            testID: weakSelf.testID,
                                            action: "BLE connection established within target time",
                                            peripheralName: peripheral.name,
                                            identifier: peripheral.identifier)
                    weakSelf.publishTestResult(passed: true,
                                               description: "(Testing time: \(testTime)ms, Acceptable Time: \(weakSelf.timeoutMS)ms).")
                } else {
                    weakSelf.notifyErrorInAttempt(reason: "Peripheral was connected but not in \(weakSelf.timeoutMS)ms")

                }

                break
                
            case let .disconnected(peripheral: peripheral, error: error):
                weakSelf.notifyErrorInAttempt(reason: "didDisconnectPeripheral \(peripheral) with error \(String(describing: error?.localizedDescription))")
                break
                
            case let .failToConnect(peripheral: peripheral, error: error):
                weakSelf.notifyErrorInAttempt(reason: "didFailToConnectPeripheral \(peripheral) with error \(String(describing: error?.localizedDescription))")
                break
                
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    weakSelf.log.step(source: "SILConnectDeviceTestCase",
                                      testID: weakSelf.testID,
                                      action: "BLE connect test interrupted",
                                      detail: "Bluetooth was disabled.")
                    weakSelf.invalidateTestTimer()
                    weakSelf.connectTimer?.invalidate()
                    weakSelf.publishTestResult(passed: false, description: "Bluetooth disabled!")
                }
                
            case .unknown:
                break
            }
        })
        disposeBag.add(token: centralManagerSubscription)
        observableTokens.append(centralManagerSubscription)
        
        connectTimer = Timer.scheduledTimer(timeInterval: timeIntervalFromTimeout, target: self, selector: #selector(stopConnecting), userInfo: nil, repeats: false)
        startTestTimer()
        
        if discoveredPeripheral.isConnectable {
            log.connection(source: "SILConnectDeviceTestCase",
                           testID: testID,
                           action: "Attempt BLE connection",
                           peripheralName: discoveredPeripheral.advertisedLocalName,
                           identifier: discoveredPeripheral.peripheral?.identifier)
            iopCentralManager.connect(to: discoveredPeripheral)
        } else {
            invalidateObservableTokens()
            invalidateTestTimer()
            connectTimer?.invalidate()
            log.step(source: "SILConnectDeviceTestCase",
                     testID: testID,
                     action: "BLE connect test failed before connect attempt",
                     detail: "Discovered peripheral is not connectable.")
            publishTestResult(passed: false, description: "Peripheral isn't connectable.")
        }
    }
    
    private func notifyErrorInAttempt(reason: String) {
        log.step(source: "SILConnectDeviceTestCase",
                 testID: testID,
                 action: "BLE connect attempt failed",
                 detail: reason)
        invalidateTestTimer()
        stopConnecting()
    }
    
    private func notifyError() {
        guard let peripheral = discoveredPeripheral.peripheral else { return }
        self.iopCentralManager.disconnect(peripheral: peripheral)
        self.publishTestResult(passed: false,
                               description: "Peripheral \(String(describing: self.cbPeripheral)) wasn't connected in any of 5 attempts of connecting for \(self.timeoutMS) ms")
        log.step(source: "SILConnectDeviceTestCase",
                 testID: testID,
                 action: "BLE connect test failed",
                 detail: "Peripheral was not connected in 5 attempts within \(timeoutMS) ms per attempt.")
    }
        
    func getTestArtifacts() -> Dictionary<String, Any> {
        if let peripheral = cbPeripheral {
            return ["peripheral": peripheral]
        }
        
        return [:]
    }
    
    func stopTesting() {
        connectTimer?.invalidate()
        invalidateObservableTokens()
    }
}
