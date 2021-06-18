//
//  SILIOPTester_Test7.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILIOPTester_Test7 : SILTestScenario {
    var scenarioName: String = "Throughput"
    var scenarioDescription: String = "Throughput-GATT Notification."

    var testResults: SILObservable<[SILTestResult]> = SILObservable(initialValue: [])
    var tests: [SILTestCase] = [SILTestCase]()
    var privTestResults: [SILTestResult] = [SILTestResult]()
    var isMandatory: Bool = false
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    init() {
        appendTestCase(testCase: SILThroughputTestCase())
        testResults.value = privTestResults
    }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        tests[0].injectParameters(parameters: parameters)
    }
    
    func performTestScenario() {
        weak var weakSelf = self
        
        let throughputTestToken = self.tests[0].testResult.observe({ testResult in
            guard let testResult = testResult else { return }
            guard let weakSelf = weakSelf else { return }
            weakSelf.privTestResults[0] = testResult
            weakSelf.testResults.value = self.privTestResults
        })
        disposeBag.add(token: throughputTestToken)
        observableTokens.append(throughputTestToken)
        
        self.tests[0].performTestCase()
    }
    
    func getTestsArtifacts() -> Dictionary<String, Any> {
        return tests[0].getTestArtifacts()
    }
}

