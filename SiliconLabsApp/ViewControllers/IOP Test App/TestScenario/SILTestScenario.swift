//
//  SILTestScenario.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

struct SILTestFailureReason {
    var description: String
    var error: Error?
}

enum SILTestStatus: RawRepresentable {
    typealias RawValue = String
    
    case waiting
    case inProgress
    case passed(details: String?)
    case failed(reason: SILTestFailureReason?)
    case unknown(reason: String?)
    case none
    
    var rawValue: String {
        switch self {
        case .waiting:
            return "Waiting"
        case .inProgress:
            return "InProgress"
        case .passed(details: _):
            return "Pass"
        case .failed(reason: _):
            return "Fail"
        case .unknown:
            return "N/A"
        case .none:
            return ""
        }
    }
    
    init?(rawValue: String) {
        if rawValue == "Waiting" {
            self = .waiting
        } else if rawValue == "InProgress" {
            self = .inProgress
        } else if rawValue == "Pass" {
            self = .passed(details: nil)
        } else  if rawValue == "Failed" {
            self = .failed(reason: nil)
        } else if rawValue == "N/A" {
            self = .unknown(reason: nil)
        } else {
            self = .none
        }
    }
}

struct SILTestResult: Comparable {
    var testID: String
    var testName: String
    var testStatus: SILTestStatus
    
    static func < (lhs: SILTestResult, rhs: SILTestResult) -> Bool {
        if let firstLHS = lhs.testID.first?.asciiValue, let firstRHS = rhs.testID.first?.asciiValue {
            if firstLHS < firstRHS {
                return true
            } else if firstLHS > firstRHS {
                return false
            }
        }
        
        if let dotIndexLHS = lhs.testID.firstIndex(of: ".") , let dotIndexRHS = rhs.testID.firstIndex(of: ".") {
            let numberLHS = lhs.testID.suffix(from: lhs.testID.index(after: dotIndexLHS))
            let numberRHS = rhs.testID.suffix(from: rhs.testID.index(after: dotIndexRHS))
            if let intValueLHS = Int(numberLHS), let intValueRHS = Int(numberRHS) {
                if intValueLHS < intValueRHS {
                    return true
                } else if intValueLHS > intValueRHS {
                    return false
                }
            }
        }
        
        return false
    }
    
    static func == (lhs: SILTestResult, rhs: SILTestResult) -> Bool {
        if let firstLHS = lhs.testID.first?.asciiValue, let firstRHS = rhs.testID.first?.asciiValue {
            if firstLHS != firstRHS {
                return false
            }
        }
        
        if let dotIndexLHS = lhs.testID.firstIndex(of: "."), let dotIndexRHS = rhs.testID.firstIndex(of: ".") {
            let numberLHS = lhs.testID.suffix(from: lhs.testID.index(after: dotIndexLHS))
            let numberRHS = rhs.testID.suffix(from: rhs.testID.index(after: dotIndexRHS))
            if let intValueLHS = Int(numberLHS), let intValueRHS = Int(numberRHS) {
                if intValueLHS != intValueRHS {
                    return false
                } else {
                    return true
                }
            }
        }
        
        return true
    }
}

// Build itself internally
protocol SILTestScenario: class {
    var scenarioName: String { get set }
    var scenarioDescription: String { get set }
    var testResults: SILObservable<[SILTestResult]> { get set }
    var tests: [SILTestCase] { get set }
    var privTestResults : [SILTestResult] { get set }
    var observableTokens: [SILObservableToken?] { get set }
    var isMandatory: Bool { get set }
        
    func injectParameters(parameters: Dictionary<String, Any>)
    func performTestScenario()
    func getTestsArtifacts() -> Dictionary<String, Any>
}

protocol SILTestCase: class {
    var testID: String { get set }
    var testName: String { get set }
    var testResult: SILObservable<SILTestResult?> { get set }
    var observableTokens: [SILObservableToken?] { get set }
    
    func injectParameters(parameters: Dictionary<String, Any>)
    func performTestCase()
    func getTestArtifacts() -> Dictionary<String, Any>
}

protocol SILTestCaseTimeout: class {
    var timeoutMS: Int64 { get set }
    var startTime: Int64? { get set }
    var stopTime: Int64? { get set }
    
    func startTestTimer()
    func stopTestTimerWithResult() -> Int64
}

extension SILTestCaseTimeout {
    func startTestTimer() {
        self.startTime = Date().currentTimeMillis()
    }
    
    func stopTestTimerWithResult() -> Int64 {
        self.stopTime = Date().currentTimeMillis()
        
        guard let startTime = self.startTime, let stopTime =  self.stopTime else { return 0 }
        return stopTime - startTime
    }
    
    func invalidateTestTimer() {
        self.startTime = nil
        self.stopTime = nil
    }
    
    var timeIntervalFromTimeout: TimeInterval {
        get {
            return TimeInterval(self.timeoutMS / 1000)
        }
    }
}

protocol SILTestCaseWithRetries: class {
    var retryCount: Int { get set }
}

extension SILTestScenario {
    func appendTestCase(testCase: SILTestCase) {
        tests.append(testCase)
        privTestResults.append(SILTestResult(testID: testCase.testID, testName: testCase.testName, testStatus: .waiting))
    }
    
    func invalidateObservableTokens() {
        for token in observableTokens {
            token?.invalidate()
        }
        
        observableTokens = []
    }
    
    func stopTesting() {
        for test in tests {
            test.stopTesting()
        }
        
        invalidateObservableTokens()
    }
}

extension SILTestCase {
    func publishStartTestEvent() {
        self.testResult.value = SILTestResult(testID: self.testID, testName: self.testName, testStatus: .inProgress)
    }
    
    func publishTestResult(passed: Bool, description: String? = nil, error: Error? = nil) {
        invalidateObservableTokens()
        
        var testStatus: SILTestStatus
        
        if passed {
            testStatus = .passed(details: description)
        } else {
            testStatus = .failed(reason: SILTestFailureReason(description: description ?? "", error: error))
        }
        
        self.testResult.value = SILTestResult(testID: self.testID, testName: self.testName, testStatus: testStatus)
    }
    
    func invalidateObservableTokens() {
        for token in observableTokens {
            token?.invalidate()
        }
        
        observableTokens = []
    }
    
    func stopTesting() {
        invalidateObservableTokens()
    }
}
