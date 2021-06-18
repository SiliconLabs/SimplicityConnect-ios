//
//  SILGATT5_6TestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGATT5_6TestCase: SILTestCase {
    var testID: String = "5.6"
    var testName: String = "BLE Characteristics Types Test case"

    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)

    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private lazy var userLenCharacteristicTestHelper = SILIOPUserLenCharacteristicTestHelper(testCase: self,
                                                                                             testedCharacteristicUUID: iopTestCharacteristicTypesRWUserLen1,
                                                                                             exceptedValue: ExceptedValue,
                                                                                             count: 1)
  
    private var iopTestCharacteristicTypesRWUserLen1 = SILIOPPeripheral.SILIOPTestCharacteristicTypes.IOPTestChar_RWUserLen1.cbUUID
    private let ExceptedValue = "0x55"
    
    init() { }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        userLenCharacteristicTestHelper.injectParameters(parameters: parameters)
    }
    
    func performTestCase() {
        weak var weakSelf = self
        let userLenCharacteristicTestHelperSubscription = userLenCharacteristicTestHelper.testResult.observe( { testResult in
            guard let weakSelf = weakSelf else { return }
            guard let testResult = testResult else { return }
            weakSelf.userLenCharacteristicTestHelper.invalidateObservableTokens()
            weakSelf.publishTestResult(passed: testResult.passed, description: testResult.description)
        })
        disposeBag.add(token: userLenCharacteristicTestHelperSubscription)
        observableTokens.append(userLenCharacteristicTestHelperSubscription)
        
        publishStartTestEvent()
        userLenCharacteristicTestHelper.performTestCase()
    }
    
    func getTestArtifacts() -> Dictionary<String, Any> {
        return [:]
    }
    
    func stopTesting() {
        userLenCharacteristicTestHelper.invalidateObservableTokens()
        invalidateObservableTokens()
    }
}
