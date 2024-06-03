//
//  SILLEPrivacyBond.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 12/03/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit

class SILLEPrivacyBond: SILTestCase {
    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)
    var testID: String = "7.4"
    var testName: String = "Security and Encryption."

    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private var securityTestHelper: SILIOPSecurityTestHelper
    
    private var iopTestPhase3TestSecurityBonding = SILIOPPeripheral.SILIOPTestPhase3.IOPTest_Security_Bonding.cbUUID
    private let InitialValue = "0x000300"
    private let ExceptedValue = "0x55"
    
    init() {
        securityTestHelper = SILIOPSecurityTestHelper(testedCharacteristic: iopTestPhase3TestSecurityBonding,
                                                      initialValue: InitialValue,
                                                      exceptedValue: ExceptedValue)
    }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        securityTestHelper.injectParameters(parameters: parameters)
    }
    
    func performTestCase() {
        weak var weakSelf = self
        let securityTestHelperResultSubscription = securityTestHelper.testResult.observe( { testResult in
            guard let weakSelf = weakSelf else { return }
            guard let testResult = testResult else { return }
            weakSelf.securityTestHelper.invalidateObservableTokens()
            weakSelf.publishTestResult(passed: testResult.passed, description: testResult.description)
        })
        disposeBag.add(token: securityTestHelperResultSubscription)
        observableTokens.append(securityTestHelperResultSubscription)
        
        publishStartTestEvent()
        securityTestHelper.performTestCase()
    }
    
    func getTestArtifacts() -> Dictionary<String, Any> {
        return [:]
    }
    
    func stopTesting() {
        securityTestHelper.stopTesting()
        invalidateObservableTokens()
    }
}
