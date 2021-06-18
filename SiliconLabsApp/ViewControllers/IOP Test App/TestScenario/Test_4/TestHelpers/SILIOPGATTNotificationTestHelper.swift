//
//  SILIOPGATTNotificationTestHelper.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 28.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILIOPGATTNotificationTestHelper: SILTestCaseTimeout, SILTestCaseWithRetries {
    struct NotificationTestResult {
        var passed: Bool
        var description: String
    }
    
    var timeoutMS: Int64 = 300
    var startTime: Int64?
    var stopTime: Int64?
    private var testTime: Int64!
    private var testTimeoutTimer: Timer?
    
    var retryCount: Int = 5
    
    private var testCase: SILTestCase!
    private var peripheral: CBPeripheral!
    private var peripheralDelegate: SILIOPTesterPeripheralDelegate!
    private var iopCentralManager: SILIOPTesterCentralManager!
    
    private var gattOperationsTestHelper: SILIOPGATTOperationsTestHelper!
    
    var observableTokens: [SILObservableToken?] = []
    private var centralManagerSubscription: SILObservableToken?
    private var disposeBag = SILObservableTokenBag()
    
    private var testedCharacteristicUUID: CBUUID
    private var iopTestProperitesCharacteristic: CBCharacteristic!
    private var iopTestProperties = SILIOPPeripheral.SILIOPTestProperties.cbUUID
    private var exceptedValue: String
    private var testedProperty: CBCharacteristicProperties
    
    var testResult: SILObservable<NotificationTestResult?> = SILObservable(initialValue: nil)
    
    init(testCase: SILTestCase, testedCharacteristicUUID: CBUUID, exceptedValue: String, testedProperty: CBCharacteristicProperties) {
        self.testCase = testCase
        self.testedCharacteristicUUID = testedCharacteristicUUID
        self.exceptedValue = exceptedValue
        self.testedProperty = testedProperty
        gattOperationsTestHelper = SILIOPGATTOperationsTestHelper()
    }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.peripheral = parameters["peripheral"] as? CBPeripheral
        self.peripheralDelegate = parameters["peripheralDelegate"] as? SILIOPTesterPeripheralDelegate
        self.iopCentralManager = parameters["iopCentralManager"] as? SILIOPTesterCentralManager
    }
    
    func performTestCase() {
        let result = gattOperationsTestHelper.checkInjectedParameters(iopCentralManager: iopCentralManager,
                                                                      peripheral: peripheral,
                                                                      peripheralDelegate: peripheralDelegate)
        
        guard result.areValid else {
            self.testResult.value = NotificationTestResult(passed: false, description: result.reason)
            return
        }
        
        discoverTestedCharacteristic()
    }
    
    private func subscribeToCentralManager() {
        centralManagerSubscription = gattOperationsTestHelper.getCentralManagerSubscription(iopCentralManager: iopCentralManager, testCase: testCase)
        disposeBag.add(token: centralManagerSubscription!)
    }
    
    private func discoverTestedCharacteristic() {
        weak var weakSelf = self
        let peripheralDelegateSubscription = peripheralDelegate.newStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .successForCharacteristics(characteristics):
                guard let iopTestPropertiesCharacteristic = weakSelf.gattOperationsTestHelper.findCharacteristic(with: weakSelf.testedCharacteristicUUID, in: characteristics) else {
                    weakSelf.notifyError(description: "Characteristic wasn't discovered.")
                    return
                }

                guard iopTestPropertiesCharacteristic.properties.contains(weakSelf.testedProperty) else {
                    weakSelf.notifyError(description: "Characteristic doesn't have notify property.")
                    return
                }
                
                weakSelf.iopTestProperitesCharacteristic = iopTestPropertiesCharacteristic
                weakSelf.invalidateOldSubscriptions()
                weakSelf.test()
                
            case .unknown:
                break
                
            default:
                weakSelf.notifyError(description: "Unknown failure when discovering characteristic.")
            }
        })
        disposeBag.add(token: peripheralDelegateSubscription)
        observableTokens.append(peripheralDelegateSubscription)
        
        subscribeToCentralManager()
        
        guard let iopTestProperties = gattOperationsTestHelper.findService(with: iopTestProperties, in: peripheral) else {
            self.notifyError(description: "Peripheral doesn't contain a service IOP Test Properties.")
            return
        }
        
        peripheralDelegate.discoverCharacteristics(characteristics: [testedCharacteristicUUID], for: iopTestProperties)
    }
    
    private func test() {
        weak var weakSelf = self
        let peripheralDelegateSubscription = peripheralDelegate.newStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .successGetValue(value: data, characteristic: characteristic):
                if characteristic.uuid == weakSelf.testedCharacteristicUUID {
                    debugPrint("DATA \(String(describing: data?.hexa()))")
                    weakSelf.testTimeoutTimer?.invalidate()
                    if let data = data?.hexa(), weakSelf.exceptedValue.contains(data) {
                        weakSelf.observableTokens.append(weakSelf.centralManagerSubscription)
                        weakSelf.testResult.value = NotificationTestResult(passed: true, description: "(Testing time: \(weakSelf.testTime!)ms, Acceptable Time: \(weakSelf.timeoutMS)ms).")
                    } else {
                        weakSelf.stopWaiting()
                    }
                    return
                }
                
                weakSelf.stopWaiting()
            
            case let .updateNotificationState(characteristic: characteristic, state: state):
                debugPrint("Notification \(state) on characteristic \(characteristic)")
                if characteristic.uuid == weakSelf.testedCharacteristicUUID, state == true {
                    weakSelf.testTimeoutTimer?.invalidate()
                    let testTime = weakSelf.stopTestTimerWithResult()
                    if testTime < weakSelf.timeoutMS {
                        weakSelf.testTime = testTime
                        // time to get value from notifying characteristic - iOS sends also didUpdateValue on notifying characteristic but it's a slow process
                        weakSelf.testTimeoutTimer = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(weakSelf.stopWaiting), userInfo: nil, repeats: false)
                        return
                    }
                    
                    weakSelf.stopWaiting()
                    return
                }
                
                weakSelf.stopWaiting()
                
            case .unknown:
                break
                
            default:
                weakSelf.stopWaiting()
            }
        })
        disposeBag.add(token: peripheralDelegateSubscription)
        observableTokens.append(peripheralDelegateSubscription)
                
        peripheralDelegate.notifyCharacteristic(characteristic: iopTestProperitesCharacteristic)
        
        // timeout for notifying - 300 ms is too little value to build timer and run test :(
        testTimeoutTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(stopWaiting), userInfo: nil, repeats: false)
        startTestTimer()
        subscribeToCentralManager()
    }
    
    @objc func stopWaiting() {
        testTimeoutTimer?.invalidate()
        testTimeoutTimer = nil
        
        retryCount = retryCount - 1
        if retryCount > 0 {
            invalidateOldSubscriptions()
            
            weak var weakSelf = self
            let peripheralDelegateSubscription = peripheralDelegate.newStatus().observe( { status in
                guard let weakSelf = weakSelf else { return }
                switch status {
                case let .updateNotificationState(characteristic: characteristic, state: state):
                    debugPrint("Notification \(state) on characteristic \(characteristic)")
                    if characteristic.uuid == weakSelf.testedCharacteristicUUID, state == false {
                        weakSelf.invalidateOldSubscriptions()
                        weakSelf.test()
                    }
                    
                case .unknown:
                    break
                    
                default:
                    weakSelf.stopWaiting()
                }
            })
            disposeBag.add(token: peripheralDelegateSubscription)
            observableTokens.append(peripheralDelegateSubscription)
            
            peripheralDelegate.notifyCharacteristic(characteristic: iopTestProperitesCharacteristic, enabled: false)
        } else {
            notifyError(description: "Error getting notification from characteristic in 5 attempts.")
        }
    }
    
    private func notifyError(description: String) {
        self.testTimeoutTimer?.invalidate()
        self.testTimeoutTimer = nil
        self.observableTokens.append(centralManagerSubscription)
        self.testResult.value = NotificationTestResult(passed: false, description: description)
    }
    
    private func invalidateOldSubscriptions() {
        invalidateObservableTokens()
        observableTokens = []
    }
    
    func invalidateObservableTokens() {
        for token in observableTokens {
            token?.invalidate()
        }
        
        observableTokens = []
    }
    
    func stopTesting() {
        testTimeoutTimer?.invalidate()
        invalidateObservableTokens()
    }
}
