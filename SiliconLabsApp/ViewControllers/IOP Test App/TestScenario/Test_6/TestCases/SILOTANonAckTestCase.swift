//
//  SILOTANonAckTestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILOTANonAckTestCase: SILTestCase {
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
    }

    // Test
    func performTestCase() {
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
        
        IOPLog().iopLogSwiftFunction(message: "\(firmwareInfo?.name ?? "")")
        IOPLog().iopLogSwiftFunction(message: "\(firmwareInfo?.nameTag ?? "")")
                //IOPLog().iopLogSwiftFunction(message: "\(firmwareInfo!.firmware)")
        IOPLog().iopLogSwiftFunction(message: "\(String(describing: peripheral))")
        publishStartTestEvent()
        
        self.otaUpdateManager = SILIopTestOTAUpdateManger(with: self.peripheral,
                                                          centralManager: self.browserCentralManager,
                                                          otaMode: .speed)
        
        weak var weakSelf = self
        let otaStatusSubscription = self.otaUpdateManager.otaTestStatus.observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case .success:
                IOPLog().iopLogSwiftFunction(message: "Success OTA Non Ack TestCase\(status)")
                weakSelf.otaUpdateManager = nil
                weakSelf.invalidateObservableTokens()
                UserDefaults.standard.setValue("IOP_Test_1", forKey: "deviceNameAfterOtaUpdate")
                weakSelf.reconnectToDevice(passed: true)
                
               
   
            case let .failure(reason: reason):
                IOPLog().iopLogSwiftFunction(message: "Failure OTA Non Ack TestCase\(reason)")
                weakSelf.otaUpdateManager = nil
                weakSelf.invalidateObservableTokens()
               
                weakSelf.browserCentralManager.disconnectConnectedPeripheral()
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
        }
        
        self.otaUpdateManager.startTest(for: boardID, firmwareVersion: firmwareInfo!.originalVersion)
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
                IOPLog().iopLogSwiftFunction(message: "\(reconnectStatus)")
                IOPLog().iopLogSwiftFunction(message: "\(String(describing: discoveredPeripheral))")
                IOPLog().iopLogSwiftFunction(message: "\(String(describing: discoveredPeripheral?.peripheral))")
                IOPLog().iopLogSwiftFunction(message: "\(SILIOPFirmwareVersion(version: stackVersion))")
                
                
                
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
