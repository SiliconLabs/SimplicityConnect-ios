//
//  SILGATT4_10TestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGATT4_10TestCase: SILTestCase {
    var testID: String = "4.10"
    var testName: String = "BLE Properties Test case"
    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private lazy var notificationTestHelper = SILIOPGATTNotificationTestHelper(testCase: self,
                                                                               testedCharacteristicUUID: iopTestPropertiesIndicateLen255,
                                                                               exceptedValue: ExceptedValue,
                                                                               testedProperty: .indicate)
    
    private var iopTestPropertiesIndicateLen255 = SILIOPPeripheral.SILIOPTestProperties.IOPTest_IndicateLen255.cbUUID
    private let ExceptedValue = "0x000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFE"
    
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
