//
//  SILIOPLengthVariableTestHelper.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 28.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILIOPLengthVariableTestHelper {
    struct TestResult {
        var passed: Bool
        var description: String?
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
    private let exceptedValue_Subtest1: String
    private let expectedValue_Subtest2: String
    private var isFirstSubtest = true
    
    var testResult: SILObservable<TestResult?> = SILObservable(initialValue: nil)
    
    init(testCase: SILTestCase,
         testedCharacteristicUUID: CBUUID,
         exceptedValue_Subtest1: String,
         exceptedValue_Subtest2: String) {
        self.testCase = testCase
        self.testedCharacteristicUUID = testedCharacteristicUUID
        self.exceptedValue_Subtest1 = exceptedValue_Subtest1
        self.expectedValue_Subtest2 = exceptedValue_Subtest2
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
                guard weakSelf.isFirstSubtest else {
                    weakSelf.testResult.value = TestResult(passed: false, description: "Wrong invocation.")
                    return
                }
                
                guard let iopTestCharacteristicTypesRWVariableLen4 = weakSelf.peripheralDelegate.findCharacteristic(with: weakSelf.testedCharacteristicUUID, in: characteristics) else {
                    weakSelf.testResult.value = TestResult(passed: false, description: "Characteristic Types Variable Len wasn't discovered.")
                    return
                }
                
                guard let dataToWrite = weakSelf.exceptedValue_Subtest1.data(withCount: 1) else {
                    weakSelf.testResult.value = TestResult(passed: false, description: "Invalid data to write.")
                    return
                }
                
                weakSelf.peripheralDelegate.writeToCharacteristic(data: dataToWrite, characteristic: iopTestCharacteristicTypesRWVariableLen4, writeType: .withResponse)
                
            case let .successWrite(characteristic: characteristic):
                if characteristic.uuid == weakSelf.testedCharacteristicUUID {
                    debugPrint("DATA \(String(describing: characteristic.value?.hexa()))")
                    IOPLog().iopLogSwiftFunction(message: "DATA \(String(describing: characteristic.value?.hexa()))")
                    weakSelf.peripheralDelegate.readCharacteristic(characteristic: characteristic)
                    return
                }
                
                weakSelf.testResult.value = TestResult(passed: false, description: "Characteristic not found.")
                
            case let .successGetValue(value: data, characteristic: characteristic):
                if characteristic.uuid == weakSelf.testedCharacteristicUUID {
                    debugPrint("DATA \(String(describing: data?.hexa()))")
                    IOPLog().iopLogSwiftFunction(message: "DATA \(String(describing: data?.hexa()))")
                    if weakSelf.isFirstSubtest, data?.hexa() == weakSelf.exceptedValue_Subtest1 {
                        weakSelf.isFirstSubtest = false
                        if let dataToWrite = weakSelf.expectedValue_Subtest2.data(withCount: 4) {
                            weakSelf.peripheralDelegate.writeToCharacteristic(data: dataToWrite, characteristic: characteristic, writeType: .withResponse)
                        } else {
                            weakSelf.testResult.value = TestResult(passed: false, description: "Wrong data to write to characteristic.")
                        }
                    } else if !weakSelf.isFirstSubtest, data?.hexa() == weakSelf.expectedValue_Subtest2 {
                        weakSelf.testResult.value = TestResult(passed: true)
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
