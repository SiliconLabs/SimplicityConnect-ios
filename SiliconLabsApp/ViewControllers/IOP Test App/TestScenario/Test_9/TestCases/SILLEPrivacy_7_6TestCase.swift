//
//  SILLEPrivacy_7_6TestCase.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 01/03/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit

class SILLEPrivacy_7_6TestCase: SILTestCase {
    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)
    var testID: String = "7.6"
    var testName: String = "LE Privacy."

    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private var leprivacyTestHelper: SILIOPLEPrivacyHealper
    
    private var iopTestPhase3TestSecurityBonding = SILIOPPeripheral.SILIOPTestPhase3.IOPTest_Security_Bonding.cbUUID
    private let InitialValue = "0x000400"
    private let ExceptedValue = "1"
    
    init() {
        leprivacyTestHelper = SILIOPLEPrivacyHealper(testedCharacteristic: iopTestPhase3TestSecurityBonding,
                                                      initialValue: InitialValue,
                                                      exceptedValue: ExceptedValue)
    }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        leprivacyTestHelper.injectParameters(parameters: parameters)
    }
    
    func performTestCase() {
        weak var weakSelf = self
        let securityTestHelperResultSubscription = leprivacyTestHelper.testResult.observe( { testResult in
            guard let weakSelf = weakSelf else { return }
            guard let testResult = testResult else { return }
            weakSelf.leprivacyTestHelper.invalidateObservableTokens()
            //FOR disconnect device
            weakSelf.publishTestResult(passed: testResult.passed, description: testResult.description)
        })
        disposeBag.add(token: securityTestHelperResultSubscription)
        observableTokens.append(securityTestHelperResultSubscription)
        
        publishStartTestEvent()
        leprivacyTestHelper.performTestCase()
    }
    
    func getTestArtifacts() -> Dictionary<String, Any> {
        return [:]
    }
    
    func stopTesting() {
        leprivacyTestHelper.stopTesting()
        invalidateObservableTokens()
    }
}
