//
//  SILGATT5_8TestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGATT5_8TestCase: SILTestCase {
    var testID: String = "5.8"
    var testName: String = "BLE Characteristics Types Test case"

    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)

    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()

    private lazy var lengthVariableTestHelper = SILIOPLengthVariableTestHelper(testCase: self,
                                                                               testedCharacteristicUUID: iopTestCharacteristicTypesRWUserLen4,
                                                                               exceptedValue_Subtest1: ExceptedValue_Subtest1,
                                                                               exceptedValue_Subtest2: ExpectedValue_Subtest2)
    
    private var iopTestCharacteristicTypesRWUserLen4 = SILIOPPeripheral.SILIOPTestCharacteristicTypes.IOPTestChar_RWUserLen4.cbUUID
    private let ExceptedValue_Subtest1 = "0x55"
    private let ExpectedValue_Subtest2 = "0x66666666"
    
    init() {  }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        lengthVariableTestHelper.injectParameters(parameters: parameters)
    }
    
    func performTestCase() {
        weak var weakSelf = self
        let lengthVariableTestHelperSubscription = lengthVariableTestHelper.testResult.observe( { testResult in
            guard let weakSelf = weakSelf else { return }
            guard let testResult = testResult else { return }
            weakSelf.lengthVariableTestHelper.invalidateObservableTokens()
            weakSelf.publishTestResult(passed: testResult.passed, description: testResult.description)
        })
        disposeBag.add(token: lengthVariableTestHelperSubscription)
        observableTokens.append(lengthVariableTestHelperSubscription)
        
        publishStartTestEvent()
        lengthVariableTestHelper.performTestCase()
    }
    
    func getTestArtifacts() -> Dictionary<String, Any> {
        return [:]
    }
    
    func stopTesting() {
        lengthVariableTestHelper.invalidateObservableTokens()
        invalidateObservableTokens()
    }
}
