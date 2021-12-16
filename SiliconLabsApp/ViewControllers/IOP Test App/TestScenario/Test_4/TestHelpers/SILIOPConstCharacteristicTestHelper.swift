//
//  SILIOPConstCharacteristicTestHelper.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 28.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILIOPConstCharacteristicTestHelper {
    struct TestResult {
        var passed: Bool
        var description: String?
    }
    
    private var testCase: SILTestCase!
    private var peripheral: CBPeripheral!
    private var peripheralDelegate: SILPeripheralDelegate!
    private var iopCentralManager: SILIOPTesterCentralManager!
    
    private var gattOperationsTestHelper: SILIOPGATTOperationsTestHelper
    
    private var observableTokens = [SILObservableToken]()
    private var disposeBag = SILObservableTokenBag()
    
    private var iopTestCharacteristicTypesRWConstLen1 = SILIOPPeripheral.SILIOPTestCharacteristicTypes.IOPTestChar_RWConstLen1.cbUUID
    private var iopTestCharacteristicTypes = SILIOPPeripheral.SILIOPTestCharacteristicTypes.cbUUID
    private var ExceptedValue_Subtest1 = "0x55"
    private var ValueToWrite_Subtest2 = "0x00"
    private var isFirstSubtest = true
    
    var testResult: SILObservable<TestResult?> = SILObservable(initialValue: nil)
    
    init(testCase: SILTestCase,
         testedCharacteristicUUID: CBUUID,
         exceptedValue_Subtest1: String,
         valueToWrite_Subtest2: String) {
        self.testCase = testCase
        self.iopTestCharacteristicTypesRWConstLen1 = testedCharacteristicUUID
        self.ExceptedValue_Subtest1 = exceptedValue_Subtest1
        self.ValueToWrite_Subtest2 = valueToWrite_Subtest2
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
        
        peripheralDelegate.discoverCharacteristics(characteristics: [iopTestCharacteristicTypesRWConstLen1], for: iopTestCharacteristicTypes)
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
                
                guard let iopTestCharacteristicTypesRWConstLen1 = weakSelf.peripheralDelegate.findCharacteristic(with: weakSelf.iopTestCharacteristicTypesRWConstLen1, in: characteristics) else {
                    weakSelf.testResult.value = TestResult(passed: false, description: "Characteristic Types RW Const Len 1 wasn't discovered.")
                    return
                }
                
                weakSelf.peripheralDelegate.readCharacteristic(characteristic: iopTestCharacteristicTypesRWConstLen1)
                
            case let .successGetValue(value: data, characteristic: characteristic):
                if characteristic.uuid == weakSelf.iopTestCharacteristicTypesRWConstLen1 {
                    debugPrint("DATA \(String(describing: data?.hexa()))")
                    if weakSelf.isFirstSubtest, data?.hexa() == weakSelf.ExceptedValue_Subtest1 {
                        weakSelf.isFirstSubtest = false
                        if let dataToWrite = weakSelf.ValueToWrite_Subtest2.data(withCount: 1) {
                            weakSelf.peripheralDelegate.writeToCharacteristic(data: dataToWrite, characteristic: characteristic, writeType: .withResponse)
                        } else {
                            weakSelf.testResult.value = TestResult(passed: false, description: "Wrong data to write to characteristic.")
                        }
                    } else {
                        weakSelf.testResult.value = TestResult(passed: false, description: "Wrong value in a characteristic.")
                    }
                    
                    return
                }
                
                weakSelf.testResult.value = TestResult(passed: false, description: "Not found a characteristic.")
                
            case let .failure(error: error):
                if !weakSelf.isFirstSubtest, let attError = error as? CBATTError {
                    if attError.code == .writeNotPermitted {
                        weakSelf.testResult.value = TestResult(passed: true)
                    } else {
                        weakSelf.testResult.value = TestResult(passed: false, description: "No ATT Error encountered.")
                    }
                }
               
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
