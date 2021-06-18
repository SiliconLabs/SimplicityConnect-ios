//
//  SILIOPTester_Test4.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILIOPTester_Test4 : SILTestScenario {
    var scenarioName: String = "Central performs all the GATT"
    var scenarioDescription: String = "Central performs all the GATT operations supported by the target."
    
    var testResults: SILObservable<[SILTestResult]> = SILObservable(initialValue: [])
    var tests: [SILTestCase] = [SILTestCase]()
    var privTestResults: [SILTestResult] = [SILTestResult]()
    var isMandatory: Bool = false
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private var discoverFirmwareInfo: SILDiscoverFirmwareInfo!
    private var discoverRFUFeatures: SILDiscoverRFUFeatures!
    
    private var parameters: Dictionary<String, Any>!
    private var deviceName: String!
    private var firmwareInfo: SILIOPTestFirmwareInfo?
    private var connectionParameters: SILIOPTestConnectionParameters?
    
    init() {
        discoverFirmwareInfo = SILDiscoverFirmwareInfo()
        discoverRFUFeatures = SILDiscoverRFUFeatures()
        
        appendTestCase(testCase: SILGATT4_1TestCase())
        appendTestCase(testCase: SILGATT4_2TestCase())
        appendTestCase(testCase: SILGATT4_3TestCase())
        appendTestCase(testCase: SILGATT4_4TestCase())
        appendTestCase(testCase: SILGATT4_5TestCase())
        appendTestCase(testCase: SILGATT4_6TestCase())
        appendTestCase(testCase: SILGATT4_7TestCase())
        appendTestCase(testCase: SILGATT4_8TestCase())
        appendTestCase(testCase: SILGATT4_9TestCase())
        appendTestCase(testCase: SILGATT4_10TestCase())
        appendTestCase(testCase: SILGATT5_1TestCase())
        appendTestCase(testCase: SILGATT5_2TestCase())
        appendTestCase(testCase: SILGATT5_3TestCase())
        appendTestCase(testCase: SILGATT5_4TestCase())
        appendTestCase(testCase: SILGATT5_5TestCase())
        appendTestCase(testCase: SILGATT5_6TestCase())
        appendTestCase(testCase: SILGATT5_7TestCase())
        appendTestCase(testCase: SILGATT5_8TestCase())
        testResults.value = privTestResults
    }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.parameters = parameters
        discoverFirmwareInfo.injectParameters(parameters: parameters)
        
        for test in tests {
            test.injectParameters(parameters: parameters)
        }
    }
    
    func performTestScenario() {
        runDiscoverFirmwareInfo()
        
        for i in 0..<tests.count {
            weak var weakSelf = self
            observableTokens.append(self.tests[i].testResult.observe( { testResult in
                guard let testResult = testResult else { return }
                guard let weakSelf = weakSelf else { return }
                weakSelf.privTestResults[i] = testResult
                weakSelf.testResults.value = weakSelf.privTestResults
                if i + 1 < weakSelf.tests.count && testResult.testStatus != .inProgress {
                    weakSelf.tests[i + 1].performTestCase()
                }
            }))
            disposeBag.add(token: observableTokens.last!!)
        }
    }
    
    private func runDiscoverFirmwareInfo() {
        weak var weakSelf = self
        observableTokens.append(self.discoverFirmwareInfo.state.observe( { state in
            guard let weakSelf = weakSelf else { return }
            switch state {
            case .initiated:
                debugPrint("DISCOVER FIRMWARE INFO INITIATED")
                break
                
            case .running:
                debugPrint("DISCOVER FIRMWARE INFO RUNNING")
                break
                
            case .failed:
                debugPrint("DISCOVER FIRMWARE INFO FAILED")
                weakSelf.tests[0].performTestCase()
                break
                
            case let .completed(stackVersion: stackVersion):
                debugPrint("DISCOVER FIRMWARE COMPLETED")
                weakSelf.parameters["stackVersion"] = stackVersion
                weakSelf.discoverRFUFeatures.injectParameters(parameters: weakSelf.parameters)
                weakSelf.runDiscoverRFUFeatures()
                break
            }
        }))
        disposeBag.add(token: observableTokens.last!!)
        
        discoverFirmwareInfo.run()
    }
    
    private func runDiscoverRFUFeatures() {
        weak var weakSelf = self
        observableTokens.append(self.discoverRFUFeatures.state.observe( { state in
            guard let weakSelf = weakSelf else { return }
            switch state {
            case .initiated:
                debugPrint("DISCOVER RFU INITIATED")
                break
                
            case .running:
                debugPrint("DISCOVER RFU RUNNING")
                break
                
            case .failed:
                debugPrint("DISCOVER RFU FAILED")
                weakSelf.tests[0].performTestCase()
                break
                
            case let .completed(firmwareInfo: firmwareInfo, connectionParameters: connectionParameters):
                debugPrint("DISCOVER RFU COMPLETED")
                weakSelf.firmwareInfo = firmwareInfo
                weakSelf.connectionParameters = connectionParameters
                weakSelf.tests[0].performTestCase()
            }
        }))
        disposeBag.add(token: observableTokens.last!!)
        
        discoverRFUFeatures.run()
    }
    
    func getTestsArtifacts() -> Dictionary<String, Any> {
        var artifacts = self.tests[0].getTestArtifacts()
        if let firmwareInfo = self.firmwareInfo {
            artifacts["firmwareInfo"] = firmwareInfo
        }
        if let connectionParameters = self.connectionParameters {
            artifacts["connectionParameters"] = connectionParameters
        }

        return artifacts
    }
    
    func stopTesting() {
        discoverFirmwareInfo.stopTesting()
        discoverRFUFeatures.stopTesting()
        
        for test in tests {
            test.stopTesting()
        }
        
        invalidateObservableTokens()
    }
}
