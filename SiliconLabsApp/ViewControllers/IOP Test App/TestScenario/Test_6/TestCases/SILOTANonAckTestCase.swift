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
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private var otaUpdateManager: SILIopTestOTAUpdateManger!
    private var completion: (() -> ())!
    
    init() { }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.browserCentralManager = parameters["browserCentralManager"] as? SILCentralManager
        self.peripheral = parameters["peripheral"] as? CBPeripheral
        self.firmwareInfo = parameters["firmwareInfo"] as? SILIOPTestFirmwareInfo
    }

    // Test
    func performTestCase() {
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
        
        self.otaUpdateManager = SILIopTestOTAUpdateManger(with: self.peripheral,
                                                          centralManager: self.browserCentralManager,
                                                          otaMode: .speed)
        
        weak var weakSelf = self
        let otaStatusSubscription = self.otaUpdateManager.otaTestStatus.observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case .success:
                weakSelf.otaUpdateManager = nil
                weakSelf.invalidateObservableTokens()
                weakSelf.disconnect {
                    weakSelf.publishTestResult(passed: true)
                }
   
            case let .failure(reason: reason):
                weakSelf.otaUpdateManager = nil
                weakSelf.invalidateObservableTokens()
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
    
    private func disconnect(completion: @escaping () -> ()) {
        self.completion = completion
        registerNotifications()
        self.browserCentralManager.disconnect(from: peripheral)
    }
 
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didConnectPeripheral(notification:)), name: .SILCentralManagerDidConnectPeripheral, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDisconnectPeripheral(notification:)), name: .SILCentralManagerDidDisconnectPeripheral, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didFailToConnectPeripheral(notification:)), name: .SILCentralManagerDidFailToConnectPeripheral, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bluetoothDisabled), name: .SILCentralManagerBluetoothDisabled, object: nil)
    }
    
    private func unregisterNotifications() {
        browserCentralManager.removeScan(forPeripheralsObserver: self)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerDidConnectPeripheral, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerDidDisconnectPeripheral, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerDidFailToConnectPeripheral, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerBluetoothDisabled, object: nil)
    }

    @objc private func didConnectPeripheral(notification: Notification) {
        debugPrint("didConnectPeripheral**********")
        unregisterNotifications()
        self.publishTestResult(passed: false, description: "Unknown error.")
    }
    
    @objc private func didDisconnectPeripheral(notification: Notification) {
        debugPrint("didDisconnectPeripheral**********")
        unregisterNotifications()
        self.completion()
    }
    
    @objc private func didFailToConnectPeripheral(notification: Notification) {
        debugPrint("didFailToConnectPeripheral**********")
        unregisterNotifications()
        self.publishTestResult(passed: false, description: "Unknown error.")
    }

    @objc private func bluetoothDisabled() {
        debugPrint("bluetoothDisabled**********")
        unregisterNotifications()
        self.publishTestResult(passed: false, description: "Bluetooth disabled.")
    }
    
    // Artifacts
    func getTestArtifacts() -> Dictionary<String, Any> {
        return [:]
    }
}
