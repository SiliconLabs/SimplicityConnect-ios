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
    private var firmwareVersionAfterOtaAckUpdate: SILIOPFirmwareVersion?
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    private var timer: Timer?
    
    private var otaUpdateManager: SILIopTestOTAUpdateManger!
    
    private var deviceNameAfterOtaUpdate: String {
        get {
            return firmwareInfo!.originalVersion.isLesserThan3_3_0() ? "IOP Test Update" : "IOP_Test_2"
        }
    }
    
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
            IOPLog().iopLogSwiftFunction(message: "Bluetooth disabled!")
            return
        }
        
        guard let _ = firmwareInfo else {
            self.testResult.value = SILTestResult(testID: self.testID, testName: self.testName, testStatus: .unknown(reason: "Firmware Info is nil."))
            IOPLog().iopLogSwiftFunction(message: "Firmware Info is nil.")
            return
        }
        
        guard firmwareInfo!.firmware != .unknown else {
            self.testResult.value = SILTestResult(testID: self.testID, testName: self.testName, testStatus: .unknown(reason: "Board not supported."))
            IOPLog().iopLogSwiftFunction(message: "Board not supported.")
            return
        }
        
        guard let _ = peripheral else {
            self.publishTestResult(passed: false, description: "Peripheral is nil.")
            IOPLog().iopLogSwiftFunction(message: "Peripheral is nil.")
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
                    IOPLog().iopLogSwiftFunction(message: "DISCONNECTED WITH \(String(describing: error?.localizedDescription))")
                    weakSelf.scanUsingBrowserBluetoothManager()
                }
                
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    debugPrint("Bluetooth disabled!")
                    IOPLog().iopLogSwiftFunction(message: "Bluetooth disabled!")
                    weakSelf.otaUpdateManager = nil
                    weakSelf.publishTestResult(passed: false, description: "Bluetooth disabled.")
                }
                
            case .unknown:
                break
                
            default:
                IOPLog().iopLogSwiftFunction(message: "Unknown failure reason from IOP Central Manager.")
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
        IOPLog().iopLogSwiftFunction(message: "DID RECEIVE")
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
        guard let discoveredPeripheral = discoveredPeripheral, let peripheral = discoveredPeripheral.peripheral else {
            return
        }

        self.otaUpdateManager = SILIopTestOTAUpdateManger(with: peripheral,
                                                          centralManager: self.browserCentralManager,
                                                          otaMode: .reliability)
        
        weak var weakSelf = self
        let otaStatusSubscription = self.otaUpdateManager.otaTestStatus.observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case .success:
                weakSelf.otaUpdateManager = nil
                weakSelf.invalidateObservableTokens()
                UserDefaults.standard.setValue("IOP_Test_2", forKey: "deviceNameAfterOtaUpdate")
               // weakSelf.reconnectToDevice(passed: true)
                weakSelf.publishTestResult(passed: true)
            case let .failure(reason: reason):
                weakSelf.otaUpdateManager = nil
            
                UserDefaults.standard.setValue("IOP_Test_1", forKey: "deviceNameAfterOtaUpdate")
                weakSelf.browserCentralManager.disconnect(from: self.peripheral )
                weakSelf.reconnectToDevice(passed: false,description: reason)
                
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
        
        case .readName(let name):
            boardID = name
            
        case .unknown:
            self.invalidateObservableTokens()
            self.testResult.value = SILTestResult(testID: self.testID, testName: self.testName, testStatus: .unknown(reason: "Unsupported board."))
            IOPLog().iopLogSwiftFunction(message: "Unsupported board.")
        }
        
        self.otaUpdateManager.startTest(for: boardID, firmwareVersion: firmwareInfo!.originalVersion)
    }
    
    @objc private func scanIntervalTimerFired() {
        stopScanning()
        self.publishTestResult(passed: false, description: "Peripheral didn't found.")
        IOPLog().iopLogSwiftFunction(message: "Peripheral didn't found.")
    }
    
    func stopScanning() {
        if browserCentralManager != nil {
            browserCentralManager?.removeScan(forPeripheralsObserver: self)
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func reconnectToDevice(passed: Bool, description: String? = nil) {
        weak var weakSelf = self
        let reconnectManager = SILIOPTestReconnectManager(with: peripheral, iopCentralManager: iopCentralManager)
        let reconnectManagerSubscription = reconnectManager.reconnectStatus.observe { reconnectStatus in
            guard let weakSelf = weakSelf else { return }
            switch reconnectStatus {
            case let .success(discoveredPeripheral: discoveredPeripheral, stackVersion: stackVersion):
                weakSelf.discoveredPeripheral = discoveredPeripheral
                weakSelf.peripheral = discoveredPeripheral?.peripheral
                weakSelf.firmwareVersionAfterOtaAckUpdate = SILIOPFirmwareVersion(version: stackVersion)
                weakSelf.invalidateObservableTokens()
                
                if passed{
                    weakSelf.publishTestResult(passed: true)
                }else{
                    weakSelf.publishTestResult(passed: passed, description: description)
                }
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
        guard let localName = discoveredPeripheral.advertisedLocalName, let peripheral = discoveredPeripheral.peripheral else {
            return false
        }
            
        return reformatPeripheralName(name: localName) == reformatPeripheralName(name: name) && peripheral.identifier.uuidString == uuid
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
        
        if let firmwareVersion = self.firmwareVersionAfterOtaAckUpdate, let firmwareInfo = firmwareInfo {
            let updatedFirmwareInfo = SILIOPTestFirmwareInfo(originalVersion: firmwareInfo.originalVersion,
                                                             otaAckVersion: firmwareVersion,
                                                             name: firmwareInfo.name,
                                                             firmware: firmwareInfo.firmware)
            parameters["firmwareInfo"] = updatedFirmwareInfo
        }
        
        return parameters
    }
    
    func stopTesting() {
        stopScanning()
        invalidateObservableTokens()
    }
}

