//
//  SILOTANonAckTestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILOTANonAckTestCase: SILTestCase {
    private let log = IOPLog()
    private let postOTARestartDelay: TimeInterval = 15
    private let maxPostOTAReconnectAttempts = 3
    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)
    var testID: String = "6.2"
    var testName: String = "Update user application via OTA without Ack."

    private var browserCentralManager: SILCentralManager!
    private var peripheral: CBPeripheral!
    private var firmwareInfo: SILIOPTestFirmwareInfo?
    private var iopCentralManager: SILIOPTesterCentralManager!
    private var firmwareVersionAfterOtaAckUpdate: SILIOPFirmwareVersion?
    
    private var discoveredPeripheral: SILDiscoveredPeripheral?
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private var otaUpdateManager: SILIopTestOTAUpdateManger!
    private var otaBoardID: String?
    
    private var deviceNameAfterOtaUpdate: String {
        get {
            
            let deviceNameAfterOtaUpdate = UserDefaults.standard.value(forKey: "deviceNameAfterOtaUpdate")
           
            return firmwareInfo!.originalVersion.isLesserThan3_3_0() ? "IOP Test" : deviceNameAfterOtaUpdate as! String
        }
    }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.browserCentralManager = parameters["browserCentralManager"] as? SILCentralManager
        self.peripheral = parameters["peripheral"] as? CBPeripheral
        self.firmwareInfo = parameters["firmwareInfo"] as? SILIOPTestFirmwareInfo
        self.iopCentralManager = parameters["iopCentralManager"] as? SILIOPTesterCentralManager
        self.discoveredPeripheral = parameters["discoveredPeripheral"] as? SILDiscoveredPeripheral
    }

    // Test
    func performTestCase() {
        guard let _ = firmwareInfo else {
            self.testResult.value = SILTestResult(testID: self.testID, testName: self.testName, testStatus: .unknown(reason: "Firmware Info is nil."))
            log.step(source: "SILOTANonAckTestCase", testID: testID, action: "Cannot start OTA non-acknowledged test", detail: "Firmware info is nil.")
            return
        }
        
        guard firmwareInfo!.firmware != .unknown else {
            self.testResult.value = SILTestResult(testID: self.testID, testName: self.testName, testStatus: .unknown(reason: "Board not supported."))
            log.step(source: "SILOTANonAckTestCase", testID: testID, action: "Cannot start OTA non-acknowledged test", detail: "Board is not supported.")
            return
        }
        
        guard let _ = peripheral else {
            self.publishTestResult(passed: false, description: "Peripheral is nil.")
            log.step(source: "SILOTANonAckTestCase", testID: testID, action: "Cannot start OTA non-acknowledged test", detail: "Peripheral is nil.")
            return
        }
        
        log.step(source: "SILOTANonAckTestCase",
                 testID: testID,
                 action: "Start OTA non-acknowledged test",
                 detail: "Firmware name=\(firmwareInfo?.name ?? "unknown") | board=\(firmwareInfo?.firmware.rawValue ?? "unknown") | \(log.peripheralSummary(peripheral))")
        publishStartTestEvent()
        
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
            return
        }
        self.otaBoardID = boardID
        
        if peripheral.state == .connected {
            disconnectPeripheralFromIOPCentralManager()
        } else {
            startOTANonAckFlow()
        }
    }

    private func disconnectPeripheralFromIOPCentralManager() {
        weak var weakSelf = self
        let centralManagerSubscription = self.iopCentralManager.newPublishConnectionStatus().observe({ status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .disconnected(peripheral: peripheral, error: error):
                if peripheral === weakSelf.peripheral {
                    weakSelf.log.step(source: "SILOTANonAckTestCase",
                                      testID: weakSelf.testID,
                                      action: "Disconnected from application mode peripheral before OTA non-acknowledged update",
                                      detail: "error=\(weakSelf.log.formattedError(error))")
                    weakSelf.startOTANonAckFlow()
                }
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    weakSelf.log.step(source: "SILOTANonAckTestCase",
                                      testID: weakSelf.testID,
                                      action: "OTA non-acknowledged flow interrupted",
                                      detail: "Bluetooth was disabled.")
                    weakSelf.otaUpdateManager = nil
                    weakSelf.publishTestResult(passed: false, description: "Bluetooth disabled.")
                }
            case .unknown:
                break
            default:
                weakSelf.log.step(source: "SILOTANonAckTestCase",
                                  testID: weakSelf.testID,
                                  action: "OTA non-acknowledged flow failed",
                                  detail: "Received an unexpected central manager status before OTA start.")
                weakSelf.publishTestResult(passed: false, description: "Unknown failure reason from IOP Central Manager.")
            }
        })
        self.disposeBag.add(token: centralManagerSubscription)
        observableTokens.append(centralManagerSubscription)
        self.iopCentralManager.disconnect(peripheral: self.peripheral)
    }

    private func startOTANonAckFlow() {
        guard let boardID = otaBoardID else {
            publishTestResult(passed: false, description: "OTA board identifier is missing.")
            log.step(source: "SILOTANonAckTestCase",
                     testID: testID,
                     action: "Cannot start OTA non-acknowledged flow",
                     detail: "Board identifier is missing before creating the OTA manager.")
            return
        }
        
        self.otaUpdateManager = SILIopTestOTAUpdateManger(with: self.peripheral,
                                                          centralManager: self.browserCentralManager,
                                                          otaMode: .speed)
        self.otaUpdateManager.startTest(for: boardID, firmwareVersion: self.firmwareInfo!.originalVersion)
        
        weak var weakSelf = self
        let otaStatusSubscription = self.otaUpdateManager.otaTestStatus.observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case .success:
                weakSelf.log.step(source: "SILOTANonAckTestCase",
                                  testID: weakSelf.testID,
                                  action: "OTA non-acknowledged update completed",
                                  detail: "Firmware upload completed successfully.")
                weakSelf.otaUpdateManager = nil
                weakSelf.invalidateObservableTokens()
                UserDefaults.standard.setValue("IOP_Test_1", forKey: "deviceNameAfterOtaUpdate")
                weakSelf.log.step(source: "SILOTANonAckTestCase",
                                  testID: weakSelf.testID,
                                  action: "Waiting for device to reappear after OTA non-acknowledged update",
                                  detail: "Delaying reconnect by \(Int(weakSelf.postOTARestartDelay)) seconds and expecting device name \(weakSelf.deviceNameAfterOtaUpdate).")
                DispatchQueue.main.asyncAfter(deadline: .now() + weakSelf.postOTARestartDelay) { [weak weakSelf] in
                    weakSelf?.reconnectToDevice(passed: true, attempt: 1, maxAttempts: weakSelf?.maxPostOTAReconnectAttempts ?? 3)
                }
   
            case let .failure(reason: reason):
                weakSelf.log.step(source: "SILOTANonAckTestCase", testID: weakSelf.testID, action: "OTA non-acknowledged update failed", detail: reason)
                weakSelf.otaUpdateManager = nil
                weakSelf.invalidateObservableTokens()
               
                weakSelf.browserCentralManager.disconnectConnectedPeripheral()
                weakSelf.publishTestResult(passed: false, description: reason)
                
            case .unknown:
                break
            }
        })
        self.disposeBag.add(token: otaStatusSubscription)
        observableTokens.append(otaStatusSubscription)
    }
    
    private func reconnectToDevice(passed: Bool, description: String? = nil, attempt: Int = 1, maxAttempts: Int = 1) {
        log.retry(source: "SILOTANonAckTestCase",
                  testID: testID,
                  attempt: attempt,
                  maxAttempts: maxAttempts,
                  action: passed ? "Reconnect after OTA non-acknowledged update" : "Reconnect after OTA non-acknowledged update failure",
                  timeoutDescription: "scan 5 s / connect 10 s")
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
                weakSelf.log.step(source: "SILOTANonAckTestCase",
                                  testID: weakSelf.testID,
                                  action: "Reconnected after OTA non-acknowledged update",
                                  detail: "Firmware version=\(stackVersion) | peripheral=\(discoveredPeripheral?.advertisedLocalName ?? "unknown")")
                
                
                
                if passed{
                    weakSelf.publishTestResult(passed: true)
                }else{
                    weakSelf.publishTestResult(passed: passed, description: description)
                }
            case let .failure(reason: reason):
                weakSelf.invalidateObservableTokens()
                if passed, attempt < maxAttempts {
                    weakSelf.log.step(source: "SILOTANonAckTestCase",
                                      testID: weakSelf.testID,
                                      action: "Post-OTA reconnect attempt failed",
                                      detail: "\(reason) Retrying with attempt \(attempt + 1) of \(maxAttempts).")
                    weakSelf.reconnectToDevice(passed: true, attempt: attempt + 1, maxAttempts: maxAttempts)
                } else {
                    weakSelf.publishTestResult(passed: false, description: reason)
                }
                
            case .unknown:
                break
            }
        }
        self.disposeBag.add(token: reconnectManagerSubscription)
        observableTokens.append(reconnectManagerSubscription)
        
        
        reconnectManager.reconnectToDevice(withName: deviceNameAfterOtaUpdate)
    }
    
    // Artifacts
    
    func getTestArtifacts() -> Dictionary<String, Any> {
        var parameters = ["browserCentralManager" : self.browserCentralManager!] as [String: Any]
        
        if let discoveredPeripheral = discoveredPeripheral {
            parameters["discoveredPeripheral"] = discoveredPeripheral
        }
        
        if let peripheral = peripheral {
            parameters["peripheral"] = peripheral
        }
        
        if let firmwareVersion = self.firmwareVersionAfterOtaAckUpdate, let firmwareInfo = self.firmwareInfo {
            let updatedFirmwareInfo = SILIOPTestFirmwareInfo(originalVersion: firmwareInfo.originalVersion,
                                                             otaAckVersion: firmwareInfo.otaAckVersion,
                                                             otaNonAckVersion: firmwareVersion,
                                                             name: firmwareInfo.name,
                                                             firmware: firmwareInfo.firmware)
            parameters["firmwareInfo"] = updatedFirmwareInfo
        }
        
        
        return parameters
    }

}
