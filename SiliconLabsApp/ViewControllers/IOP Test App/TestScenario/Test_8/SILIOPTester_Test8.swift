//
//  SILIOPTester_Test8.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILIOPTester_Test8: SILTestScenario {
    var scenarioName: String = "Security and Encryption"
    var scenarioDescription: String = "Security and Encryption."

    var testResults: SILObservable<[SILTestResult]> = SILObservable(initialValue: [])
    var tests: [SILTestCase] = [SILTestCase]()
    var privTestResults: [SILTestResult] = [SILTestResult]()
    var isMandatory: Bool = false
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    init() {
        appendTestCase(testCase: SILSecurity_7_2TestCase())
        appendTestCase(testCase: SILSecurity_7_3TestCase())
        appendTestCase(testCase: SILSecurity_7_4TestCase())
        appendTestCase(testCase: SILSecurity_7_5TestCase())
        testResults.value = privTestResults
    }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        for test in tests {
            test.injectParameters(parameters: parameters)
        }
    }
    
    func performTestScenario() {
        for i in 0..<tests.count {
            weak var weakSelf = self
            observableTokens.append(self.tests[i].testResult.observe( { testResult in
                guard let testResult = testResult else { return }
                guard let weakSelf = weakSelf else { return }
                weakSelf.privTestResults[i] = testResult
                weakSelf.testResults.value = weakSelf.privTestResults
                if i + 1 < weakSelf.tests.count {
                    switch testResult.testStatus {
                    case .passed(_):
                        weakSelf.tests[i + 1].performTestCase()

                    case .failed(reason: _):
                        if i + 1 == 1 {
                            weakSelf.privTestResults[1] = SILTestResult(testID: weakSelf.tests[1].testID,
                                                                        testName: weakSelf.tests[1].testName,
                                                                        testStatus: .failed(reason: SILTestFailureReason(description: "Mandatory test 7.2 failed.")))
                            weakSelf.privTestResults[2] = SILTestResult(testID: weakSelf.tests[2].testID,
                                                                        testName: weakSelf.tests[2].testName,
                                                                        testStatus: .failed(reason: SILTestFailureReason(description: "Mandatory test 7.2 failed.")))
                        } else {
                            weakSelf.privTestResults[2] = SILTestResult(testID: weakSelf.tests[2].testID,
                                                                        testName: weakSelf.tests[2].testName,
                                                                        testStatus: .failed(reason: SILTestFailureReason(description: "Mandatory test 7.3 failed.")))
                        }
                        weakSelf.testResults.value = weakSelf.privTestResults
                        
                    default:
                        break
                    }
                }
            }))
            disposeBag.add(token: observableTokens.last!!)
        }
        
        self.tests[0].performTestCase()
    }
    
    func getTestsArtifacts() -> Dictionary<String, Any> {
        return tests[0].getTestArtifacts()
    }
}
