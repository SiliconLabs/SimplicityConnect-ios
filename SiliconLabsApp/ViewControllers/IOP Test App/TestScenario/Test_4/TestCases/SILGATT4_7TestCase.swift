//
//  SILGATT4_7TestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGATT4_7TestCase: SILTestCase {
    var testID: String = "4.7"
    var testName: String = "BLE Properties Test case"
    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    private var centralManagerSubscription: SILObservableToken?

    private lazy var notificationTestHelper = SILIOPGATTNotificationTestHelper(testCase: self,
                                                                               testedCharacteristicUUID: iopTestPropertiesNotifyLen1,
                                                                               exceptedValue: ExceptedValue,
                                                                               testedProperty: .notify)
    
    private var iopTestPropertiesNotifyLen1 = SILIOPPeripheral.SILIOPTestProperties.IOPTest_NotifyLen1.cbUUID
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
