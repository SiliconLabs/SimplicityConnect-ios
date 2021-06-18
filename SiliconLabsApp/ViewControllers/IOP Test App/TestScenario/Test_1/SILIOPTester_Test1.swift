//
//  SILIOPTester_Test1.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILIOPTester_Test1: SILTestScenario {
    var scenarioName: String = "Scan device"
    var scenarioDescription: String = "Central starts scanning and looking for \"IOP Test\" device."
    var testResults: SILObservable<[SILTestResult]> = SILObservable(initialValue: [])
    var privTestResults: [SILTestResult] = [SILTestResult]()
    var tests: [SILTestCase] = [SILTestCase]()
    var isMandatory: Bool = true
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    init() {
        appendTestCase(testCase: SILScanTestCase())
        testResults.value = privTestResults
    }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.tests[0].injectParameters(parameters: parameters)
    }
    
    func performTestScenario() {
        weak var weakSelf = self
        
        let scanTestObserver = self.tests[0].testResult.observe({ testResult in
            guard let testResult = testResult else { return }
            guard let weakSelf = weakSelf else { return }
            weakSelf.privTestResults[0] = testResult
            weakSelf.testResults.value = self.privTestResults
        })
        disposeBag.add(token: scanTestObserver)
        observableTokens.append(scanTestObserver)
        
        self.tests[0].performTestCase()
    }
    
    func getTestsArtifacts() -> Dictionary<String, Any> {
        return self.tests[0].getTestArtifacts()
    }
}
