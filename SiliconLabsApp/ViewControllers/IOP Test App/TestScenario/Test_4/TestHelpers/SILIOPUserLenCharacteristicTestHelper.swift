//
//  SILIOPUserLenCharacteristicTestHelper.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 28.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILIOPUserLenCharacteristicTestHelper {
    struct TestResult {
        var passed: Bool
        var description: String
    }
    
    private var testCase: SILTestCase
    private var peripheral: CBPeripheral!
    private var peripheralDelegate: SILPeripheralDelegate!
    private var iopCentralManager: SILIOPTesterCentralManager!
    
    private var gattOperationsTestHelper: SILIOPGATTOperationsTestHelper
    
    private var observableTokens = [SILObservableToken]()
    private var disposeBag = SILObservableTokenBag()
    
    private var testedCharacteristicUUID: CBUUID
    private var iopTestCharacteristicTypes = SILIOPPeripheral.SILIOPTestCharacteristicTypes.cbUUID
    private let exceptedValue: String
    private var count: Int
    
    var testResult: SILObservable<TestResult?> = SILObservable(initialValue: nil)
    
    init(testCase: SILTestCase, testedCharacteristicUUID: CBUUID, exceptedValue: String, count: Int) {
        self.testCase = testCase
        self.testedCharacteristicUUID = testedCharacteristicUUID
        self.exceptedValue = exceptedValue
        self.count = count
        gattOperationsTestHelper = SILIOPGATTOperationsTestHelper()
    }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.peripheral = parameters["peripheral"] as? CBPeripheral
        self.peripheralDelegate = parameters["peripheralDelegate"] as? SILPeripheralDelegate
        self.iopCentralManager = parameters["iopCentralManager"] as? SILIOPTesterCentralManager
    }
    
    func performTestCase() {
        let result = gattOperationsTestHelper.checkInjectedParameters(iopCentralManager: iopCentralManager,
                                                                  peripheral: peripheral,
                                                                  peripheralDelegate: peripheralDelegate)
        
        guard result.areValid else {
            self.testResult.value = TestResult(passed: false, description: result.reason)
            return
        }
        
        subscribeToPeripheralDelegate()
        subscribeToCentralManager()
        
        guard let iopTestCharacteristicTypes = peripheralDelegate.findService(with: iopTestCharacteristicTypes, in: peripheral) else {
            self.testResult.value = TestResult(passed: false, description: "Service IOP Characteristic Types not found.")
            return
        }
        
        peripheralDelegate.discoverCharacteristics(characteristics: [testedCharacteristicUUID], for: iopTestCharacteristicTypes)
    }
    
    private func subscribeToCentralManager() {
        let centralManagerSubscription = gattOperationsTestHelper.getCentralManagerSubscription(iopCentralManager: iopCentralManager, testCase: testCase)
        disposeBag.add(token: centralManagerSubscription)
        observableTokens.append(centralManagerSubscription)
    }
    
    private func subscribeToPeripheralDelegate() {
        weak var weakSelf = self
        let peripheralDelegateSubscription = peripheralDelegate.newStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .successForCharacteristics(characteristics):
                guard let iopTestCharacteristicTypesRWUserLen1 = weakSelf.peripheralDelegate.findCharacteristic(with: weakSelf.testedCharacteristicUUID, in: characteristics) else {
                    weakSelf.testResult.value = TestResult(passed: false, description: "Characteristic Types RW User Len wasn't discovered.")
                    return
                }
                
                guard let dataToWrite = weakSelf.exceptedValue.data(withCount: weakSelf.count) else {
                    weakSelf.testResult.value = TestResult(passed: false, description: "Invalid data to write.")
                    return
                }
                
                weakSelf.peripheralDelegate.writeToCharacteristic(data: dataToWrite, characteristic: iopTestCharacteristicTypesRWUserLen1, writeType: .withResponse)
                
            case let .successWrite(characteristic: characteristic):
                if characteristic.uuid == weakSelf.testedCharacteristicUUID {
                    debugPrint("DATA \(String(describing: characteristic.value?.hexa()))")
                    IOPLog().iopLogSwiftFunction(message: "DATA \(String(describing: characteristic.value?.hexa()))")
                    weakSelf.peripheralDelegate.readCharacteristic(characteristic: characteristic)
                    return
                }
                
                weakSelf.testResult.value = TestResult(passed: false, description: "Failure when read from characteristic.")
                
            case let .successGetValue(value: data, characteristic: characteristic):
                if characteristic.uuid == weakSelf.testedCharacteristicUUID {
                    debugPrint("DATA \(String(describing: data?.hexa()))")
                    IOPLog().iopLogSwiftFunction(message: "DATA \(String(describing: data?.hexa()))")
                    if data?.hexa()  == weakSelf.exceptedValue {
                        weakSelf.testResult.value = TestResult(passed: true, description: "")
                    } else {
                        weakSelf.testResult.value = TestResult(passed: false, description: "Wrong value in a characteristic.")
                    }
                    return
                }

                weakSelf.testResult.value = TestResult(passed: false, description: "Characteristic not found.")
              
            case .unknown:
                break
                
            default:
                weakSelf.testResult.value = TestResult(passed: false, description: "Unknown failure from peripheral delegate.")
            }
        })
        disposeBag.add(token: peripheralDelegateSubscription)
        observableTokens.append(peripheralDelegateSubscription)
    }
    
    func invalidateObservableTokens() {
        for token in observableTokens {
            token.invalidate()
        }
        
        observableTokens = []
    }
    
    func stopTesting() {
        invalidateObservableTokens()
    }
}
 
