//
//  SILOTAAckTestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILOTAAckTestCase: SILTestCase {
    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)
    var testID: String = "6.1"
    var testName: String = "Update user application via OTA with Ack."

    private var browserCentralManager: SILCentralManager!
    private var peripheralLocalName: String!
    private var iopCentralManager: SILIOPTesterCentralManager!
    private var peripheral: CBPeripheral!
    private var firmwareInfo: SILIOPTestFirmwareInfo?
    private var discoveredPeripheral: SILDiscoveredPeripheral?
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    private var timer: Timer?
    
    private var otaUpdateManager: SILIopTestOTAUpdateManger!
    
    private let deviceNameAfterOtaUpdate = "IOP Test Update"
    
    init() { }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.browserCentralManager = parameters["browserCentralManager"] as? SILCentralManager
        self.peripheralLocalName = parameters["peripheralLocalName"] as? String
        self.peripheral = parameters["peripheral"] as? CBPeripheral
        self.iopCentralManager = parameters["iopCentralManager"] as? SILIOPTesterCentralManager
        self.firmwareInfo = parameters["firmwareInfo"] as? SILIOPTestFirmwareInfo
    }

    // Test
    func performTestCase() {
        guard iopCentralManager.bluetoothState else {
            self.publishTestResult(passed: false, description: "Bluetooth disabled!")
            return
        }
        
        guard let _ = firmwareInfo else {
            self.testResult.value = SILTestResult(testID: self.testID, testName: self.testName, testStatus: .uknown(reason: "Firmware Info is nil."))
            return
        }
        
        guard firmwareInfo!.firmware != .unknown else {
            self.testResult.value = SILTestResult(testID: self.testID, testName: self.testName, testStatus: .uknown(reason: "Board not supported."))
            return
        }
        
        guard let _ = peripheral else {
            self.publishTestResult(passed: false, description: "Peripheral is nil.")
            return
        }
        
        publishStartTestEvent()
        
        if peripheral.state == .disconnected {
            scanUsingBrowserBluetoothManager()
        } else {
            disconnectPeripheralFromIOPCentralManager()
        }
    }
    
    private func disconnectPeripheralFromIOPCentralManager() {
        weak var weakSelf = self
        let centralManagerSubscription = self.iopCentralManager.newPublishConnectionStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .disconnected(peripheral: peripheral, error: error):
                if peripheral === weakSelf.peripheral {
                    debugPrint("DISCONNECTED WITH \(String(describing: error?.localizedDescription))")
                    weakSelf.scanUsingBrowserBluetoothManager()
                }
                
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    debugPrint("Bluetooth disabled!")
                    weakSelf.otaUpdateManager = nil
                    weakSelf.publishTestResult(passed: false, description: "Bluetooth disabled.")
                }
                
            case .unknown:
                break
                
            default:
                weakSelf.publishTestResult(passed: false, description: "Unknown failure reason from IOP Central Manager.")
            }
        })
        self.disposeBag.add(token: centralManagerSubscription)
        observableTokens.append(centralManagerSubscription)
        
        self.iopCentralManager.disconnect(peripheral: self.peripheral)
    }
    
    private func scanUsingBrowserBluetoothManager() {
            self.browserCentralManager.addScan(forPeripheralsObserver: self, selector: #selector(self.didReceiveScanForPeripheralChange))
            self.timer = Timer.scheduledTimer(timeInterval: 5,
                                                  target: self,
                                                  selector: #selector(self.scanIntervalTimerFired),
                                                  userInfo: nil,
                                                  repeats: false)
    }
    
    @objc private func didReceiveScanForPeripheralChange() {
        debugPrint("DID RECEIVE")
        weak var weakSelf = self
        let discoveredPeripheral = browserCentralManager.discoveredPeripherals().first(where: { peripheral in
            guard let weakSelf = weakSelf else { return false }
            return weakSelf.isPeripheralWithName(discoveredPeripheral: peripheral, name: peripheralLocalName, uuid: weakSelf.peripheral.identifier.uuidString)
        })
        
        if let discoveredPeripheral = discoveredPeripheral {
            self.discoveredPeripheral = discoveredPeripheral
            self.stopScanning()
            self.invalidateObservableTokens()
            self.createAndStartOTAUpdate()
        }
    }
    
    private func createAndStartOTAUpdate() {
        self.otaUpdateManager = SILIopTestOTAUpdateManger(with: self.discoveredPeripheral!.peripheral,
                                                          centralManager: self.browserCentralManager,
                                                          otaMode: .reliability)
        
        weak var weakSelf = self
        let otaStatusSubscription = self.otaUpdateManager.otaTestStatus.observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case .success:
                weakSelf.otaUpdateManager = nil
                weakSelf.invalidateObservableTokens()
                
                weakSelf.reconnectToDevice()
                
            case let .failure(reason: reason):
                weakSelf.otaUpdateManager = nil
                weakSelf.publishTestResult(passed: false, description: reason)
                
            case .unknown:
                break
            }
        })
        self.disposeBag.add(token: otaStatusSubscription)
        observableTokens.append(otaStatusSubscription)
        
        var boardID: String = ""
        switch firmwareInfo!.firmware {
        case .BRD4104A:
            boardID = "BRD4104A"
            
        case .BRD4181A:
            boardID = "BRD4181A"
            
        case .BRD4181B:
            boardID = "BRD4181B"
        
        case .BRD4182A:
            boardID = "BRD4182A"
            
        case .BRD4186B:
            boardID = "BRD4186B"
            
        case .unknown:
            self.invalidateObservableTokens()
            self.testResult.value = SILTestResult(testID: self.testID, testName: self.testName, testStatus: .uknown(reason: "Unsupported board."))
        }
        
        self.otaUpdateManager.startTest(for: boardID, firmwareVersion: firmwareInfo!.version)
    }
    
    @objc private func scanIntervalTimerFired() {
        stopScanning()
        self.publishTestResult(passed: false, description: "Peripheral didn't found.")
    }
    
    func stopScanning() {
        if browserCentralManager != nil {
            browserCentralManager?.removeScan(forPeripheralsObserver: self)
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func reconnectToDevice() {
        weak var weakSelf = self
        let reconnectManager = SILIOPTestReconnectManager(with: peripheral, iopCentralManager: iopCentralManager)
        let reconnectManagerSubscription = reconnectManager.reconnectStatus.observe { reconnectStatus in
            guard let weakSelf = weakSelf else { return }
            switch reconnectStatus {
            case let .success(discoveredPeripheral: discoveredPeripheral):
                weakSelf.discoveredPeripheral = discoveredPeripheral
                weakSelf.peripheral = discoveredPeripheral?.peripheral
                weakSelf.invalidateObservableTokens()
                weakSelf.publishTestResult(passed: true)
                
            case let .failure(reason: reason):
                weakSelf.publishTestResult(passed: false, description: reason)
                
            case .unknown:
                break
            }
        }
        self.disposeBag.add(token: reconnectManagerSubscription)
        observableTokens.append(reconnectManagerSubscription)
        
        reconnectManager.reconnectToDevice(withName: deviceNameAfterOtaUpdate)
    }

    private func isPeripheralWithName(discoveredPeripheral: SILDiscoveredPeripheral, name: String, uuid: String) -> Bool {
        guard let localName = discoveredPeripheral.advertisedLocalName else {
            return false
        }
            
        return reformatPeripheralName(name: localName) == reformatPeripheralName(name: name) && discoveredPeripheral.peripheral.identifier.uuidString == uuid
    }
    
    private func reformatPeripheralName(name: String) -> String {
        return name.replacingOccurrences(of: " ", with: "").uppercased()
    }
    
    // Artifacts
    func getTestArtifacts() -> Dictionary<String, Any> {
        var parameters = ["browserCentralManager" : self.browserCentralManager!] as [String: Any]
        
        if let discoveredPeripheral = discoveredPeripheral {
            parameters["discoveredPeripheral"] = discoveredPeripheral
        }
        
        if let peripheral = discoveredPeripheral?.peripheral {
            parameters["peripheral"] = peripheral
        }
        
        return parameters
    }
    
    func stopTesting() {
        stopScanning()
        invalidateObservableTokens()
    }
}

