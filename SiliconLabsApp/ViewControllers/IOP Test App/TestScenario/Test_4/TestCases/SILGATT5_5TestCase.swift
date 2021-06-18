//
//  SILGATT5_5TestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGATT5_5TestCase: SILTestCase {
    var testID: String = "5.5"
    var testName: String = "BLE Characteristics Types Test case"

    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)

    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private lazy var constCharacteristicTestHelper = SILIOPConstCharacteristicTestHelper(testCase: self,
                                                                                         testedCharacteristicUUID: iopTestCharacteristicTypesRWConstLen255,
                                                                                         exceptedValue_Subtest1: ExceptedValue_Subtest1,
                                                                                         valueToWrite_Subtest2: ValueToWrite_Subtest2)
    
    private var iopTestCharacteristicTypesRWConstLen255 = SILIOPPeripheral.SILIOPTestCharacteristicTypes.IOPTestChar_RWConstLen255.cbUUID
    private var iopTestCharacteristicTypes = SILIOPPeripheral.SILIOPTestCharacteristicTypes.cbUUID
    private let ExceptedValue_Subtest1 = "0x000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFE"
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
