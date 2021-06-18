//
//  SILGATT_4_5TestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGATT4_5TestCase: SILTestCase {
    var testID: String = "4.5"
    var testName: String = "BLE Properties Test case"
    
    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)

    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private var peripheral: CBPeripheral!
    private var peripheralDelegate: SILIOPTesterPeripheralDelegate!
    private var iopCentralManager: SILIOPTesterCentralManager!
    
    private var gattOperationsTestHelper: SILIOPGATTOperationsTestHelper!
    
    private var iopTestPropertiesWRNoResLen1 = SILIOPPeripheral.SILIOPTestProperties.IOPTest_WRNoResLen1.cbUUID
    private var iopTestProperties = SILIOPPeripheral.SILIOPTestProperties.cbUUID
    private let ValueToWrite = "0x00"
    private let ExceptedValue = "0x00"
    
    init() {
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
            self.publishTestResult(passed: false, description: result.reason)
            return
        }
        
        publishStartTestEvent()
        subscribeToPeripheralDelegate()
        subscribeToCentralManager()
        
        guard let iopTestProperties = gattOperationsTestHelper.findService(with: iopTestProperties, in: peripheral) else {
            self.publishTestResult(passed: false, description: "Service IOP Test Properties not found.")
            return
        }
        
        peripheralDelegate.discoverCharacteristics(characteristics: [iopTestPropertiesWRNoResLen1], for: iopTestProperties)
    }
    
    private func subscribeToCentralManager() {
        let centralManagerSubscription = gattOperationsTestHelper.getCentralManagerSubscription(iopCentralManager: iopCentralManager, testCase: self)
        disposeBag.add(token: centralManagerSubscription)
        observableTokens.append(centralManagerSubscription)
    }
    
    private func subscribeToPeripheralDelegate() {
        let peripheralDelegateSubscription = gattOperationsTestHelper.getWRNoResLenTestSubscription(for: iopTestPropertiesWRNoResLen1,
                                                                                                    valueToWrite: ValueToWrite,
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
