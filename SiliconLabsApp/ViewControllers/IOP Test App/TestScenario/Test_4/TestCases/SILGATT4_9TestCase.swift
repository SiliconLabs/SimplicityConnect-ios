//
//  SILGATT4_9TestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGATT4_9TestCase: SILTestCase {
    var testID: String = "4.9"
    var testName: String = "BLE Properties Test case"
    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private lazy var notificationTestHelper = SILIOPGATTNotificationTestHelper(testCase: self,
                                                                               testedCharacteristicUUID: iopTestPropertiesIndicateLen1,
                                                                               exceptedValue: ExceptedValue,
                                                                               testedProperty: .indicate)
    
    private var iopTestPropertiesIndicateLen1 = SILIOPPeripheral.SILIOPTestProperties.IOPTest_IndicateLen1.cbUUID
    private let ExceptedValue = "0x55"
    
    init() { }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        notificationTestHelper.injectParameters(parameters: parameters)
    }
    
    func performTestCase() {
        weak var weakSelf = self
        let securityTestHelperResultSubscription = notificationTestHelper.testResult.observe( { testResult in
            guard let weakSelf = weakSelf else { return }
            guard let testResult = testResult else { return }
            weakSelf.notificationTestHelper.invalidateObservableTokens()
            weakSelf.publishTestResult(passed: testResult.passed, description: testResult.description)
        })
        disposeBag.add(token: securityTestHelperResultSubscription)
        observableTokens.append(securityTestHelperResultSubscription)
        
        publishStartTestEvent()
        notificationTestHelper.performTestCase()
    }
    
    func getTestArtifacts() -> Dictionary<String, Any> {
        return [:]
    }
    
    func stopTesting() {
        notificationTestHelper.stopTesting()
        invalidateObservableTokens()
    }
}
