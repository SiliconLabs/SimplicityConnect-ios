//
//  SILDiscoverGATTTestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth

class SILDiscoverGATTTestCase: SILTestCase, SILTestCaseTimeout {
    var testID: String = "3"
    var testName: String = "BLE Service Discovery"
    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)

    var timeoutMS: Int64 = 1200
    var startTime: Int64?
    var stopTime: Int64?
    private var discoverTimer: Timer?
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private var peripheral: CBPeripheral!
    private var peripheralDelegate: SILPeripheralDelegate!
    private var iopCentralManager: SILIOPTesterCentralManager!
    
    init() { }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.peripheral = parameters["peripheral"] as? CBPeripheral
        self.peripheralDelegate = parameters["peripheralDelegate"] as? SILPeripheralDelegate
        self.iopCentralManager = parameters["iopCentralManager"] as? SILIOPTesterCentralManager
    }
    
    func performTestCase() {
        guard iopCentralManager.bluetoothState else {
            self.publishTestResult(passed: false, description: "Bluetooth disabled!")
            return
        }
        
        guard let _ = peripheral else {
            self.publishTestResult(passed: false, description: "Peripheral is nil.")
            return
        }
        
        guard let _ = peripheralDelegate else {
            self.publishTestResult(passed: false, description: "Peripheral delegate is nil.")
            return
        }
        
        publishStartTestEvent()
        discoverGattServices()
    }
    
    @objc func stopDiscovering() {
        notifyError(reason: "The GATT Services weren't found in \(self.timeoutMS) ms")
    }
    
    func discoverGattServices() {
        subscribeToPeripheralDelegate()
        
        discoverTimer = Timer.scheduledTimer(timeInterval: timeIntervalFromTimeout, target: self, selector: #selector(stopDiscovering), userInfo: nil, repeats: false)
        subscribeToCentralManager()
        startTestTimer()
        
        peripheralDelegate.discoverServices(services: [SILIOPPeripheral.SILIOPTest.cbUUID,
                                     SILIOPPeripheral.SILIOPTestProperties.cbUUID,
                                     SILIOPPeripheral.SILIOPTestCharacteristicTypes.cbUUID,
                                     SILIOPPeripheral.DeviceInformationService.cbUUID])
    }
    
    private func subscribeToCentralManager() {
        weak var weakSelf = self
        let centralManagerSubscription = iopCentralManager.newPublishConnectionStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .disconnected(peripheral: _, error: error):
                debugPrint("Peripheral disconnected with \(String(describing: error?.localizedDescription))")
                IOPLog().iopLogSwiftFunction(message: "Peripheral disconnected with \(String(describing: error?.localizedDescription))")
                weakSelf.notifyError(reason: "Peripheral was disconnected with \(String(describing: error?.localizedDescription)).")
            
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    debugPrint("Bluetooth disabled!")
                    IOPLog().iopLogSwiftFunction(message: "Bluetooth disabled!")
                    weakSelf.notifyError(reason: "Bluetooth disabled.")
                }
                
            case .unknown:
                break
            
            default:
                weakSelf.notifyError(reason: "Unknown failure from central manager.")
            }
        })
        disposeBag.add(token: centralManagerSubscription)
        observableTokens.append(centralManagerSubscription)
    }
    
    private func subscribeToPeripheralDelegate() {
        weak var weakSelf = self
        let peripheralDelegateSubscription = peripheralDelegate.newStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .successForServices(discoveredServices):
                if weakSelf.areValidServices(services: discoveredServices) {
                    weakSelf.discoverTimer?.invalidate()
                    let testTime = weakSelf.stopTestTimerWithResult()
                    if testTime < weakSelf.timeoutMS {
                        weakSelf.publishTestResult(passed: true,
                                                   description: "(Testing time: \(testTime)ms, Acceptable Time: \(weakSelf.timeoutMS)ms).")
                    } else {
                        weakSelf.notifyError(reason: "The GATT Services were found but not in \(self.timeoutMS) ms.")
                    }

                } else {
                    weakSelf.notifyError(reason: "Discovered GATT Services don't match with expected.")
                }
                
            case .unknown:
                break

            default:
                weakSelf.notifyError(reason: "Unknown failure from peripheral delegate.")
            }
        })
        disposeBag.add(token: peripheralDelegateSubscription)
        observableTokens.append(peripheralDelegateSubscription)
    }
    
    private func areValidServices(services: [CBService]) -> Bool {
        if services.count != 4 {
            return false
        }
        
        guard let _ = services.first(where: { service in service.uuid == SILIOPPeripheral.SILIOPTest.cbUUID }) else {
            return false
        }
        
        guard let _ = services.first(where: { service in service.uuid == SILIOPPeripheral.SILIOPTestProperties.cbUUID }) else {
            return false
        }
        
        guard let _ = services.first(where: { service in service.uuid == SILIOPPeripheral.SILIOPTestCharacteristicTypes.cbUUID }) else {
            return false
        }
        
        guard let _ = services.first(where: { service in service.uuid == SILIOPPeripheral.DeviceInformationService.cbUUID }) else {
            return false
        }
        
        return true
    }
    
    private func notifyError(reason: String) {
        self.discoverTimer?.invalidate()
        self.discoverTimer = nil
        self.invalidateTestTimer()
        
        self.publishTestResult(passed: false, description: reason)
    }
    
    func getTestArtifacts() -> Dictionary<String, Any> {
        return ["peripheral": self.peripheral,
                "peripheralDelegate": self.peripheralDelegate]
    }
    
    func stopTesting() {
        discoverTimer?.invalidate()
        invalidateObservableTokens()
    }
}
