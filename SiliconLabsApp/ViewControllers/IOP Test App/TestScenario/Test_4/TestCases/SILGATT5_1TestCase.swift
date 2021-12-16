//
//  SILGATT5_1TestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGATT5_1TestCase: SILTestCase {
    var testID: String = "5.1"
    var testName: String = "BLE Characteristics Types Test case"

    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)

    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private var peripheral: CBPeripheral!
    private var peripheralDelegate: SILPeripheralDelegate!
    private var iopCentralManager: SILIOPTesterCentralManager!
    
    private var gattOperationsTestHelper: SILIOPGATTOperationsTestHelper!
    
    private var iopTestCharacteristicTypesRWLen1 = SILIOPPeripheral.SILIOPTestCharacteristicTypes.IOPTestChar_RWLen1.cbUUID
    private var iopTestCharacteristicTypes = SILIOPPeripheral.SILIOPTestCharacteristicTypes.cbUUID
    private let ExceptedValue = "0x55"
    
    init() {
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
            self.publishTestResult(passed: false, description: result.reason)
            return
        }
        
        publishStartTestEvent()
        subscribeToPeripheralDelegate()
        subscribeToCentralManager()
        
        guard let iopTestCharacteristicTypes = peripheralDelegate.findService(with: iopTestCharacteristicTypes, in: peripheral) else {
            self.publishTestResult(passed: false, description: "Service IOP Characteristic Types not found.")
            return
        }
        
        peripheralDelegate.discoverCharacteristics(characteristics: [iopTestCharacteristicTypesRWLen1], for: iopTestCharacteristicTypes)
    }
    
    private func subscribeToCentralManager() {
        let centralManagerSubscription = gattOperationsTestHelper.getCentralManagerSubscription(iopCentralManager: iopCentralManager, testCase: self)
        disposeBag.add(token: centralManagerSubscription)
        observableTokens.append(centralManagerSubscription)
    }
    
    private func subscribeToPeripheralDelegate() {
        let peripheralDelegateSubscription = gattOperationsTestHelper.getTypesRWLenTestSubscription(for: iopTestCharacteristicTypesRWLen1,
                                                                                                    valueToWrite: ExceptedValue,
                                                                                                    count: 1,
                                                                                                    exceptedValue: ExceptedValue,
                                                                                                    peripheralDelegate: peripheralDelegate,
                                                                                                    testCase: self)
        disposeBag.add(token: peripheralDelegateSubscription)
        observableTokens.append(peripheralDelegateSubscription)
    }
    
    func getTestArtifacts() -> Dictionary<String, Any> {
        return ["peripheral": self.peripheral,
                "peripheralDelegate": self.peripheralDelegate]
    }
}
