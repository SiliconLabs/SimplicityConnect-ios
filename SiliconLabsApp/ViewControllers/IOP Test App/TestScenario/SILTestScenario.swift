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
        IOPLog.setActiveTestID(self.testID)
        SILIOPExpertLogPublisher.publishTestStart(for: self)
        self.testResult.value = SILTestResult(testID: self.testID, testName: self.testName, testStatus: .inProgress)
    }
    
    /// Keeps the scenario row in an in-progress (spinner) state while the user completes Bluetooth pairing / passkey entry.
    func publishTestInProgressEvent() {
        IOPLog.setActiveTestID(self.testID)
        SILIOPExpertLogPublisher.publishTestAwaitingUserAction(for: self)
        self.testResult.value = SILTestResult(testID: self.testID, testName: self.testName, testStatus: .inProgress)
    }
    
    func publishTestResult(passed: Bool, description: String? = nil, error: Error? = nil) {
        IOPLog.setActiveTestID(self.testID)
        SILIOPExpertLogPublisher.publishTestResult(for: self, passed: passed, description: description)
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

struct SILIOPExpertLogEntry {
    var timestamp: String
    let category: String
    let title: String
    let detail: String?
    let tone: String
    var repeatCount: Int = 1
    
    var isMilestone: Bool {
        tone == "session" || tone == "test" || category == "SCENARIO"
    }
    
    func canCollapse(with other: SILIOPExpertLogEntry) -> Bool {
        !isMilestone &&
        !other.isMilestone &&
        category == other.category &&
        title == other.title &&
        detail == other.detail &&
        tone == other.tone
    }
}

enum SILIOPExpertLogKeys {
    static let timestamp = "timestamp"
    static let category = "category"
    static let title = "title"
    static let detail = "detail"
    static let tone = "tone"
}

extension Notification.Name {
    static let SILIOPExpertLogDidAppend = Notification.Name("SILIOPExpertLogDidAppend")
}

enum SILIOPExpertLogPublisher {
    static func publishSessionEvent(title: String, detail: String? = nil, tone: String = "session") {
        post(category: "RUN", title: title, detail: detail, tone: tone)
    }
    
    static func publishScenarioEvent(index: Int, name: String, description: String) {
        post(category: "SCENARIO",
             title: "Starting scenario \(index + 1): \(name)",
             detail: description,
             tone: "discovery")
    }
    
    static func publishTestStart(for testCase: SILTestCase) {
        let detail = buildLifecycleDetail(for: testCase, extra: nil)
        post(category: "TEST",
             title: "Starting test \(testCase.testID)",
             detail: detail,
             tone: "test")
    }
    
    static func publishTestAwaitingUserAction(for testCase: SILTestCase) {
        let detail = buildLifecycleDetail(for: testCase, extra: "Awaiting user action such as pairing confirmation.")
        post(category: "WAIT",
             title: "Test \(testCase.testID) is waiting",
             detail: detail,
             tone: "warning")
    }
    
    static func publishTestResult(for testCase: SILTestCase, passed: Bool, description: String?) {
        let status = passed ? "passed" : "failed"
        let detail = buildLifecycleDetail(for: testCase, extra: description)
        post(category: passed ? "PASS" : "FAIL",
             title: "Test \(testCase.testID) \(status)",
             detail: detail,
             tone: passed ? "success" : "failure")
    }
    
    static func publishRawLog(source: String, message: String) {
        post(category: "", title: message, detail: nil, tone: inferredTone(source: source, message: message))
    }
    
    private static func post(category: String, title: String, detail: String?, tone: String) {
        NotificationCenter.default.post(name: .SILIOPExpertLogDidAppend,
                                        object: nil,
                                        userInfo: [
                                            SILIOPExpertLogKeys.timestamp: Date().toString(),
                                            SILIOPExpertLogKeys.category: category,
                                            SILIOPExpertLogKeys.title: title,
                                            SILIOPExpertLogKeys.detail: detail ?? "",
                                            SILIOPExpertLogKeys.tone: tone
                                        ])
    }
    
    private static func buildLifecycleDetail(for testCase: SILTestCase, extra: String?) -> String {
        var parts: [String] = ["Name: \(testCase.testName)"]
        
        if let specTitle = specTitle(for: testCase.testID) {
            parts.append("Spec: \(specTitle)")
        }
        
        if let timeoutMS: Int64 = recursiveValue(named: "timeoutMS", in: testCase) {
            parts.append("Timeout: \(timeoutMS) ms")
        } else if let timeout: TimeInterval = recursiveValue(named: "timeout", in: testCase) {
            parts.append("Timeout: \(Int(timeout)) s")
        }
        
        if let retryCount: Int = recursiveValue(named: "retryCount", in: testCase) {
            parts.append("Max retry: \(retryCount)")
        }
        
        if let extra = extra, !extra.isEmpty {
            parts.append(extra)
        }
        
        return parts.joined(separator: " • ")
    }
    
    private static func inferredTone(source: String, message: String) -> String {
        let haystack = "\(source) \(message)".lowercased()
        
        if haystack.contains("pass") || haystack.contains("completed successfully") || haystack.contains("matched expected") {
            return "success"
        }
        if haystack.contains("fail") || haystack.contains("error") || haystack.contains("disconnected") || haystack.contains("timed out") {
            return "failure"
        }
        if haystack.contains("retry") || haystack.contains("attempt ") {
            return "retry"
        }
        if haystack.contains("gatt") || haystack.contains("char=") || haystack.contains("service=") || haystack.contains("cccd") || haystack.contains("notification") {
            return "gatt"
        }
        if haystack.contains("connect") || haystack.contains("peripheral=") || haystack.contains("bluetooth central state") {
            return "connection"
        }
        if haystack.contains("firmware") || haystack.contains("discover") || haystack.contains("mtu=") || haystack.contains("pdu=") || haystack.contains("stack version") {
            return "discovery"
        }
        if haystack.contains("ota") || haystack.contains("file") || haystack.contains("document picker") || haystack.contains("flash") {
            return "ota"
        }
        return "info"
    }
    
    private static func specTitle(for testID: String) -> String? {
        let titles: [String: String] = [
            "1": "IOP Test BLE Scanning",
            "2": "IOP Test BLE Connect",
            "3": "IOP Test BLE Discover services",
            "4.1": "IOP Test Read Only Length 1",
            "4.2": "IOP Test Read Only Length 255",
            "4.3": "IOP Test Write Only Length 1",
            "4.4": "IOP Test Write Only Length 255",
            "4.5": "IOP Test Write Without Response Length 1",
            "4.6": "IOP Test Write Without Response Length 255",
            "4.7": "IOP Test Notify Length 1",
            "4.8": "IOP Test Notify Length MTU - 3",
            "4.9": "IOP Test Indicate Length 1",
            "4.10": "IOP Test Indicate Length MTU - 3",
            "5.1": "IOP Test Length 1",
            "5.2": "IOP Test Length 255",
            "5.3": "IOP Test Length Variable 4",
            "5.4": "IOP Test Const Length 1",
            "5.5": "IOP Test Const Length 255",
            "5.6": "IOP Test User Len 1",
            "5.7": "IOP Test User Len 255",
            "5.8": "IOP Test User Len Variable 4",
            "6.1": "IOP Test OTA update - Acknowledged write",
            "6.2": "IOP Test OTA update - Unacknowledged write",
            "7.1": "IOP Test Throughput - GATT Notification",
            "7.2": "IOP Test Security - Pairing",
            "7.3": "IOP Test Security - Authentication",
            "7.4": "IOP Test Security - Bonding",
            "7.5": "IOP Test Security - Bonding Reconnect",
            "7.6": "LE Privacy / Bonding Reconnect"
        ]
        
        return titles[testID]
    }
    
    private static func recursiveValue<T>(named name: String, in object: Any, depth: Int = 0) -> T? {
        guard depth <= 3 else { return nil }
        
        let mirror = Mirror(reflecting: object)
        for child in mirror.children {
            if child.label == name, let typedValue = child.value as? T {
                return typedValue
            }
            
            let childMirror = Mirror(reflecting: child.value)
            if childMirror.displayStyle == .class || childMirror.displayStyle == .struct {
                if let nestedValue: T = recursiveValue(named: name, in: child.value, depth: depth + 1) {
                    return nestedValue
                }
            }
        }
        
        if let superclassMirror = mirror.superclassMirror {
            for child in superclassMirror.children {
                if child.label == name, let typedValue = child.value as? T {
                    return typedValue
                }
            }
        }
        
        return nil
    }
}
