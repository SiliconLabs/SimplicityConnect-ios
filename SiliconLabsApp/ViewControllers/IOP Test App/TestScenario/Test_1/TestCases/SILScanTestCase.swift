//
//  SILScanTestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILScanTestCase: SILTestCase, SILTestCaseTimeout, SILTestCaseWithRetries {
    var testID: String = "1"
    var testName: String = "IOP BLE Scan"
    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)
    
    var timeoutMS: Int64 = 1000
    var startTime: Int64?
    var stopTime: Int64?
    private var scanTimer: Timer?
    
    var retryCount: Int = 5
    
    private var iopCentralManager: SILIOPTesterCentralManager!
    private var peripheralLocalName: String!
    
    private var discoveredPeripheral: SILDiscoveredPeripheral?
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    init() { }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.iopCentralManager = parameters["iopCentralManager"] as? SILIOPTesterCentralManager
        self.peripheralLocalName = parameters["peripheralLocalName"] as? String
    }
    
    // Test
    func performTestCase() {
        guard iopCentralManager.bluetoothState else {
            self.publishTestResult(passed: false, description: "Bluetooth disabled!")
            return
        }
        
        publishStartTestEvent()
        scanForPeripheral()
    }
    
    @objc func disableScan() {
        self.scanTimer?.invalidate()
        self.scanTimer = nil
        self.iopCentralManager.stopScanning()
        
        invalidateObservableTokens()
        
        retryCount = retryCount - 1
        if retryCount > 0 {
            scanForPeripheral()
        } else {
            notifyError()
        }
    }
    
    private func subscribeToBluetoothState() {
        weak var weakSelf = self
        let centralManagerBluetoothStateSubscription = iopCentralManager.newPublishConnectionStatus().observe( { connectionStatus in
            guard let weakSelf = weakSelf else { return }
            switch connectionStatus {
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    debugPrint("Bluetooth disabled!")
                    IOPLog().iopLogSwiftFunction(message: "Bluetooth disabled!")
                    weakSelf.invalidateTestTimer()
                    weakSelf.scanTimer?.invalidate()
                    weakSelf.iopCentralManager.stopScanning()
                    weakSelf.publishTestResult(passed: false, description: "Bluetooth disabled!")
                }
                
            case .unknown:
                break
            
            default:
                weakSelf.publishTestResult(passed: false, description: "Unknown failure from central manager")
                IOPLog().iopLogSwiftFunction(message: "Unknown failure from central manager")
            }
        })
        disposeBag.add(token: centralManagerBluetoothStateSubscription)
        observableTokens.append(centralManagerBluetoothStateSubscription)
    }
    
    private func scanForPeripheral() {
        subscribeToCentralManagerScan()
        
        scanTimer = Timer.scheduledTimer(timeInterval: timeIntervalFromTimeout, target: self, selector: #selector(disableScan), userInfo: nil, repeats: false)
        subscribeToBluetoothState()
        startTestTimer()
        self.iopCentralManager.startScanning()
    }
    
    private func subscribeToCentralManagerScan() {
        weak var weakSelf = self
        let centralManagerSubscription = iopCentralManager.newPublishDiscoveredPeripherals().observe({ discoveredPeripherals in
            guard let weakSelf = weakSelf else { return }
            if let desiredPeripheral = discoveredPeripherals.first(where: { discoveredPeripheral in weakSelf.isPeripheralWithLocalName(discoveredPeripheral: discoveredPeripheral) }) {
                weakSelf.discoveredPeripheral = desiredPeripheral
                weakSelf.iopCentralManager.stopScanning()
                weakSelf.scanTimer?.invalidate()
                let testTime = weakSelf.stopTestTimerWithResult()
                if testTime < weakSelf.timeoutMS {
                    weakSelf.publishTestResult(passed: true, description: "(Testing time: \(testTime)ms, Acceptable Time: \(weakSelf.timeoutMS)ms).")
                    IOPLog().iopLogSwiftFunction(message: "(Testing time: \(testTime)ms, Acceptable Time: \(weakSelf.timeoutMS)ms).")
                } else {
                    weakSelf.publishTestResult(passed: false, description: "Peripheral was discovered but not in \(weakSelf.timeoutMS)ms")
                    IOPLog().iopLogSwiftFunction(message: "Peripheral was discovered but not in \(weakSelf.timeoutMS)ms")
                }
            }
        })
        disposeBag.add(token: centralManagerSubscription)
        observableTokens.append(centralManagerSubscription)
    }
        
    private func isPeripheralWithLocalName(discoveredPeripheral: SILDiscoveredPeripheral) -> Bool {
        guard let localName = discoveredPeripheral.advertisedLocalName else {
            return false
        }
            
        return reformatPeripheralName(name: localName) == reformatPeripheralName(name: peripheralLocalName)
    }
    
    private func reformatPeripheralName(name: String) -> String {
        return name.replacingOccurrences(of: " ", with: "").uppercased()
    }
    
    private func notifyError() {
        self.iopCentralManager.stopScanning()
        self.publishTestResult(passed: false,
                               description: "Peripheral with name \(String(describing: self.peripheralLocalName)) wasn't found in any of 5 attempts of scanning for \(self.timeoutMS) ms")
        IOPLog().iopLogSwiftFunction(message: "Peripheral with name \(String(describing: self.peripheralLocalName)) wasn't found in any of 5 attempts of scanning for \(self.timeoutMS) ms")
    }
    
    // Artifacts
    func getTestArtifacts() -> Dictionary<String, Any> {
        return ["discoveredPeripheral": self.discoveredPeripheral!]
    }
    
    func stopTesting() {
        scanTimer?.invalidate()
        iopCentralManager.stopScanning()
        invalidateObservableTokens()
    }
}
