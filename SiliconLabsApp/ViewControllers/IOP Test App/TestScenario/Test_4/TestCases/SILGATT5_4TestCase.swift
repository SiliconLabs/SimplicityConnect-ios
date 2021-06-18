//
//  SILGATT5_4TestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGATT5_4TestCase: SILTestCase {
    var testID: String = "5.4"
    var testName: String = "BLE Characteristics Types Test case"

    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)

    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
        
    private lazy var constCharacteristicTestHelper = SILIOPConstCharacteristicTestHelper(testCase: self,
                                                                                         testedCharacteristicUUID: iopTestCharacteristicTypesRWConstLen1,
                                                                                         exceptedValue_Subtest1: ExceptedValue_Subtest1,
                                                                                         valueToWrite_Subtest2: ValueToWrite_Subtest2)
    
    private var iopTestCharacteristicTypesRWConstLen1 = SILIOPPeripheral.SILIOPTestCharacteristicTypes.IOPTestChar_RWConstLen1.cbUUID
    private let ExceptedValue_Subtest1 = "0x55"
    private let ValueToWrite_Subtest2 = "0x00"
    
    init() { }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        constCharacteristicTestHelper.injectParameters(parameters: parameters)
    }
    
    func performTestCase() {
        weak var weakSelf = self
        let constCharacteristiTestHelperSubscription = constCharacteristicTestHelper.testResult.observe( { testResult in
            guard let weakSelf = weakSelf else { return }
            guard let testResult = testResult else { return }
            weakSelf.constCharacteristicTestHelper.invalidateObservableTokens()
            weakSelf.publishTestResult(passed: testResult.passed, description: testResult.description)
        })
        disposeBag.add(token: constCharacteristiTestHelperSubscription)
        observableTokens.append(constCharacteristiTestHelperSubscription)
        
        publishStartTestEvent()
        constCharacteristicTestHelper.performTestCase()
    }
    
    func getTestArtifacts() -> Dictionary<String, Any> {
        return [:]
    }
    
    func stopTesting() {
        constCharacteristicTestHelper.invalidateObservableTokens()
        invalidateObservableTokens()
    }
}
