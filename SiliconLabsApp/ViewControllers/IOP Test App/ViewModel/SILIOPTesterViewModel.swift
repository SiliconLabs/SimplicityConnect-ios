//
//  SILIOPTesterViewModel.swift
//  BlueGecko
//
//  Created by RAVI KUMAR on 03/12/19.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit
import CocoaLumberjack
import DeviceGuru

protocol SILIOPTesterViewModelDelegate {
    func notifyAfterAllTest()
}

class SILIOPTesterViewModel: NSObject, ObservableObject {
    private var iopCentralManager: SILIOPTesterCentralManager = SILIOPTesterCentralManager()
    private var browserCentralManager = SILCentralManager(serviceUUIDs: [])
    private var peripheral: CBPeripheral?
    private var peripheralDelegate: SILPeripheralDelegate!
    private var deviceNameToSearch: String!
    private var discoveredPeripheral: SILDiscoveredPeripheral!
    private var testParameters: Dictionary<String, Any> = [:]
    
    private var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private var iopTest: [SILTestScenario] = []
    var cellViewModels: [SILIOPTestScenarioCellViewModel] = []
    var updateTableViewWithCurrentTestScenarioIndex: SILObservable<Int> = SILObservable(initialValue: 0)
    
    private var allTestCases: Int = 0
    private var inProgressTestCases: Int = 0
    var testCasesInProgress: SILObservable<String> = SILObservable(initialValue: "")
    
    private var testCaseResults: SILTestCaseResults!
    private var timestamp: Date?
    private var firmwareInfo: SILIOPTestFirmwareInfo?
    private var connectionParameters: SILIOPTestConnectionParameters?
    private var testReport: SILIOPTestReport?
    
    /// When Throughput (scenario index 6) finishes, advancing to Security is delayed until the user dismisses the throughput popup (or an early-failure notification runs this immediately).
    private var deferredAfterThroughputScenario: (() -> Void)?
    
    enum TestState {
        case initiated
        case running
        case ended
    }
    
   var SILIOPTesterViewModelDelegate:SILIOPTesterViewModelDelegate?
    var testStateStatus: SILObservable<TestState> = SILObservable(initialValue: .initiated)
    var bluetoothState: SILObservable<Bool> = SILObservable(initialValue: true)
    
    let deviceModelName = UIDevice.current.model
    
    //MARK: INITIALIZATION
    
    init(deviceNameToSearch: String) {
        super.init()
        self.deviceNameToSearch = deviceNameToSearch
        createNewIOPTest()
        setInitialUIState()
    }
    
    func stopTest() {
        deferredAfterThroughputScenario = nil
        for test in iopTest {
            test.stopTesting()
        }
        
        for token in observableTokens {
            token?.invalidate()
        }
        
        observableTokens = []
        
        if let peripheral = peripheral {
            iopCentralManager.disconnect(peripheral: peripheral)
        }
    }
    
    
    /// Call after the throughput summary popup is dismissed (Done / backdrop) or when throughput ended without the popup.
    func continueAfterThroughputScenarioDeferred() {
        guard let continuation = deferredAfterThroughputScenario else { return }
        deferredAfterThroughputScenario = nil
        continuation()
    }
    
    // MARK: Creating a new test
    
    private func createNewIOPTest() {
        iopTest = [
            SILIOPTester_Test1(),
            SILIOPTester_Test2(),
            SILIOPTester_Test3(),
            SILIOPTester_Test4(),
            SILIOPTester_Test5(),
            SILIOPTester_Test6(),
            SILIOPTester_Test7(),
            SILIOPTester_Test8(),
            SILIOPTester_Test9()
        ]
    }
    
    private func setInitialUIState() {
        cellViewModels = []
        testCaseResults = nil
        allTestCases = 0
        inProgressTestCases = 0
        SILIOPFileWriter().clearLogDir()
        firmwareInfo = nil
        connectionParameters = nil
        
        var testCaseResults = [SILTestResult]()
        for testScenario in iopTest {
            let testCaseStatuses: [SILTestStatus] = testScenario.tests.map { _ in return .waiting }
            print(testScenario.tests)
            allTestCases += testScenario.tests.count
            print(allTestCases)
            
            for testCase in testScenario.tests {
                testCaseResults.append(SILTestResult(testID: testCase.testID, testName: testCase.testName, testStatus: .waiting))
            }
            
            cellViewModels.append(SILIOPTestScenarioCellViewModel(name: testScenario.scenarioName, description: testScenario.scenarioDescription, testCaseStatuses: testCaseStatuses))
        }
        
        self.testCaseResults = SILTestCaseResults(testCaseResults: testCaseResults)
        
        testCasesInProgress.value = "\(inProgressTestCases)/\(allTestCases)"
        updateTableViewWithCurrentTestScenarioIndex.value = 0
    }
    
    // MARK: Start Test
    
    private func markRestTestsAsFailed(fromTestAtIndex index: Int, andfromTestID testID: String) {
        guard index < iopTest.count else {
            return
        }
        
        for (i, cellViewModel) in cellViewModels.enumerated() {
            if i >= index {
                cellViewModel.markTestCasesAsFail()
            }
        }
        
        guard let indexOfFailedTestID = testCaseResults.testCaseResults.firstIndex(where: { testCaseResult in
            testCaseResult.testID == testID
        }) else { return }
        
        let failureStatus = SILTestStatus.failed(reason: SILTestFailureReason(description: "Mandatory test \(testID) failed."))
        testCaseResults.markTestAfterIndex(indexOfFailedTestID, with: failureStatus)
    }
    private func prepareLoggerForTesting() {
        //ViewModelServices.sharedInstance.bluetoothMeshNetworkManager.dropDatabase()
        IOPLogFilePrinter.clearLogDir()
        if let fileLogger = DDLog.allLoggers.last as? DDFileLogger {
            fileLogger.rollLogFile(withCompletion: {
                print("File rolled")
            })
        }
    }
    func startTest() {
        prepareLoggerForTesting()
        createNewIOPTest()
        setInitialUIState()
        timestamp = Date.init()
        testStateStatus.value = .running
        SILIOPExpertLogPublisher.publishSessionEvent(title: "Test run started",
                                                     detail: "Device: \(deviceNameToSearch ?? "Unknown")",
                                                     tone: "info")
        SILIOPExpertLogPublisher.publishScenarioEvent(index: 0,
                                                      name: iopTest[0].scenarioName,
                                                      description: iopTest[0].scenarioDescription)
        debugPrint("START TEST")
        IOPLog().step(source: "SILIOPTesterViewModel",
                      action: "Started IOP test run",
                      detail: "Device=\(deviceNameToSearch ?? "Unknown") | scenarios=\(iopTest.count)")
        
        testParameters = ["iopCentralManager": self.iopCentralManager,
                          "browserCentralManager": self.browserCentralManager,
                          "peripheralLocalName": self.deviceNameToSearch] as [String : Any]
        
        iopTest[0].injectParameters(parameters: testParameters)

        for (i, _) in iopTest.enumerated() {
            weak var weakSelf = self
            observableTokens.append(iopTest[i].testResults.observe({ testResults in
                if testResults.isEmpty { return }
                guard let weakSelf = weakSelf else { return }
                print(i)
                weakSelf.printTestResultInfo(testResults)
                let newTestCaseStatuses: [SILTestStatus] = testResults.map { testResult in
                    weakSelf.testCaseResults.update(newTestResult: testResult)
                    return testResult.testStatus
                }
               
               
                weakSelf.cellViewModels[i].update(newTestCaseStatuses: newTestCaseStatuses)
                weakSelf.updateTableViewWithCurrentTestScenarioIndex.value = i
                weakSelf.inProgressTestCases = weakSelf.testCaseResults.testInProgressCount()
                weakSelf.testCasesInProgress.value = "\(weakSelf.inProgressTestCases)/\(weakSelf.allTestCases)"
                
                if !weakSelf.isBluetoothEnabled(testResults) {
                    weakSelf.bluetoothState.value = false
                    weakSelf.endTesting()
                    return
                }
                weakSelf.objectWillChange.send()
                switch weakSelf.cellViewModels[i].status {
                case .passed(details: _):
                    //weakSelf.runNextTestIfPossible(index: i)
                    if i == 7, let privacyFailureReason = weakSelf.privacyPrerequisiteFailureReason(from: testResults) {
                        weakSelf.failPrivacyScenario(reason: privacyFailureReason)
                        return
                    }
                    if i == 6 {
                        weakSelf.deferredAfterThroughputScenario = { [weak self] in
                            self?.runNextTestIfPossible(index: 6)
                        }
                    } else {
                        weakSelf.runNextTestIfPossible(index: i)
                    }
                    
                case .failed(reason: _),
                     .unknown(reason: _):
                   
                    if weakSelf.iopTest[i].isMandatory {
                        weakSelf.markRestTestsAsFailed(fromTestAtIndex: i + 1, andfromTestID: testResults.last!.testID)
                        weakSelf.endTesting()
                    } else {
                        if i == 7, let privacyFailureReason = weakSelf.privacyPrerequisiteFailureReason(from: testResults) {
                            weakSelf.failPrivacyScenario(reason: privacyFailureReason)
                            return
                        }
                        if i == 7, weakSelf.didAllTestsFail(testResults) {
                            weakSelf.markRestTestsAsFailed(fromTestAtIndex: 8, andfromTestID: testResults.last!.testID)
                            weakSelf.inProgressTestCases = weakSelf.testCaseResults.testInProgressCount()
                            weakSelf.testCasesInProgress.value = "\(weakSelf.inProgressTestCases)/\(weakSelf.allTestCases)"
                            weakSelf.updateTableViewWithCurrentTestScenarioIndex.value = 8
                            weakSelf.objectWillChange.send()
                            weakSelf.endTesting()
                            return
                        }
                        //                        weakSelf.runNextTestIfPossible(index: i)
                        //                        if i == 6 {
                        //                            //print(i)
                        //                            weakSelf.markRestTestsAsFailed(fromTestAtIndex: 6 + 1, andfromTestID: testResults.last!.testID)
                        //                            weakSelf.markRestTestsAsFailed(fromTestAtIndex: 8 + 1, andfromTestID: testResults.last!.testID)
                        //                        }
                        
                        if i == 6 {
                            let lastID = testResults.last!.testID
                            weakSelf.deferredAfterThroughputScenario = { [weak self] in
                                guard let self = self else { return }
                                self.runNextTestIfPossible(index: 6)
                                self.markRestTestsAsFailed(fromTestAtIndex: 7, andfromTestID: lastID)
                                self.markRestTestsAsFailed(fromTestAtIndex: 9, andfromTestID: lastID)
                            }
                        } else {
                            weakSelf.runNextTestIfPossible(index: i)
                        }
                    }
                    
                default:
                    break
                }
            }))
            self.disposeBag.add(token: observableTokens.last!!)
        }

        iopTest[0].performTestScenario()
    }
    
    private func printTestResultInfo(_ testResults: [SILTestResult]) {
        for testResult in testResults {
            var testResultText = "TEST RESULT \(testResult.testID) \(testResult.testName) \(testResult.testStatus.rawValue)"
            print(testResult)
            switch testResult.testStatus {
            case let .passed(details: details):
                if let details = details {
                    testResultText.append(" \(details)")
                }
            case let .failed(reason: reason):
                if let reason = reason {
                    testResultText.append(" \(reason.description)")
                }
        
            case let .unknown(reason: reason):
                if let reason = reason {
                    testResultText.append(" \(reason)")
                }
                
            default:
                break
            }
            
            IOPLog().emit(source: "SILIOPTesterViewModel", message: testResultText)
            debugPrint(testResultText)
        }
    }
    
    private func isBluetoothEnabled(_ testResults: [SILTestResult]) -> Bool {
        for testResult in testResults {
            if case let SILTestStatus.failed(reason: reason) = testResult.testStatus {
                if let reason = reason, reason.description.contains("Bluetooth disabled") {
                    return false
                }
            }
        }
        
        return true
    }
    
    private func didAllTestsFail(_ testResults: [SILTestResult]) -> Bool {
        guard !testResults.isEmpty else { return false }
        
        for testResult in testResults {
            if case .failed = testResult.testStatus {
                continue
            }
            return false
        }
        
        return true
    }
    
    private func privacyPrerequisiteFailureReason(from securityResults: [SILTestResult]) -> String? {
        let failedPrerequisites = securityResults.compactMap { testResult -> String? in
            guard testResult.testID == "7.4" || testResult.testID == "7.5" else { return nil }
            if case .failed = testResult.testStatus {
                return testResult.testID
            }
            return nil
        }
        
        guard !failedPrerequisites.isEmpty else { return nil }
        return "Prerequisite bonding test(s) \(failedPrerequisites.joined(separator: ", ")) failed."
    }
    
    private func failPrivacyScenario(reason: String) {
        guard iopTest.indices.contains(8), !iopTest[8].privTestResults.isEmpty else { return }
        iopTest[8].privTestResults[0] = SILTestResult(testID: "7.6",
                                                      testName: "LE Privacy.",
                                                      testStatus: .failed(reason: SILTestFailureReason(description: reason)))
        iopTest[8].testResults.value = iopTest[8].privTestResults
    }
    
    private func runNextTestIfPossible(index i: Int) {
        let dict = iopTest[i].getTestsArtifacts()
        updateParametersDictionary(newArtifacts: dict, testIndex: i)
        
        iopTest[i].invalidateObservableTokens()
        //print(iopTest)
       // print(iopTest.count)
        if i + 1 < iopTest.count {
            iopTest[i + 1].injectParameters(parameters: testParameters)
            SILIOPExpertLogPublisher.publishScenarioEvent(index: i + 1,
                                                          name: iopTest[i + 1].scenarioName,
                                                          description: iopTest[i + 1].scenarioDescription)
            iopTest[i + 1].performTestScenario()
        } else {
            endTesting()
        }
    }

    private func updateParametersDictionary(newArtifacts dict: Dictionary<String, Any>, testIndex: Int) {
        if testIndex == 0 {
            discoveredPeripheral = dict["discoveredPeripheral"] as? SILDiscoveredPeripheral
            testParameters["discoveredPeripheral"] = discoveredPeripheral
        } else if testIndex == 1 {
            peripheral = dict["peripheral"] as? CBPeripheral
            testParameters["peripheral"] = peripheral
            if let peripheral = peripheral {
                peripheralDelegate = SILPeripheralDelegate(peripheral: peripheral)
                testParameters["peripheralDelegate"] = peripheralDelegate
            }
        } else if testIndex == 3 {
            connectionParameters = dict["connectionParameters"] as? SILIOPTestConnectionParameters
            if let connectionParameters = connectionParameters {
                testParameters["mtu_size"] = connectionParameters.mtu_size as NSObject
                testParameters["pdu_size"] = connectionParameters.pdu_size as NSObject
                testParameters["interval"] = connectionParameters.interval as NSObject
                testParameters["phy"] = connectionParameters.phy as NSObject
            }
            if let firmwareInfo = dict["firmwareInfo"] as? SILIOPTestFirmwareInfo {
                self.firmwareInfo = firmwareInfo
                testParameters["firmwareInfo"] = firmwareInfo
            }
        } else if testIndex == 4 {
            peripheral = dict["peripheral"] as? CBPeripheral
            testParameters["peripheral"] = peripheral
            discoveredPeripheral = dict["discoveredPeripheral"] as? SILDiscoveredPeripheral
            testParameters["discoveredPeripheral"] = discoveredPeripheral
            if let firmwareInfo = dict["firmwareInfo"] as? SILIOPTestFirmwareInfo {
                self.firmwareInfo = firmwareInfo
                testParameters["firmwareInfo"] = firmwareInfo
            }
        } else if testIndex == 5 {
            peripheral = dict["peripheral"] as? CBPeripheral
            testParameters["peripheral"] = peripheral
            discoveredPeripheral = dict["discoveredPeripheral"] as? SILDiscoveredPeripheral
            testParameters["discoveredPeripheral"] = discoveredPeripheral
            if let firmwareInfo = dict["firmwareInfo"] as? SILIOPTestFirmwareInfo {
                self.firmwareInfo = firmwareInfo
                testParameters["firmwareInfo"] = firmwareInfo
            }
        } else if testIndex == 6 {
            peripheral = dict["peripheral"] as? CBPeripheral
            testParameters["peripheral"] = peripheral
            peripheralDelegate = dict["peripheralDelegate"] as? SILPeripheralDelegate
            testParameters["peripheralDelegate"] = peripheralDelegate
            discoveredPeripheral = dict["discoveredPeripheral"] as? SILDiscoveredPeripheral
            testParameters["discoveredPeripheral"] = discoveredPeripheral
        }
    }
    
    func endTesting() {
        debugPrint("END TESTING")
        
        IOPLog().step(source: "SILIOPTesterViewModel",
                      action: "Finished IOP test run",
                      detail: "Preparing final report and reset popup.")
        SILIOPExpertLogPublisher.publishSessionEvent(title: "Test run finished", detail: nil, tone: "success")
        
        stopTest()
        prepareTestReport()
        SILOTAFirmwareUpdateManager.resetOTADataCharacteristicState()
        self.iopCentralManager  = SILIOPTesterCentralManager()
        self.browserCentralManager = SILCentralManager(serviceUUIDs: [])
        testStateStatus.value = .ended
        SILIOPTesterViewModelDelegate?.notifyAfterAllTest()
        
    }
    
    func prepareTestReport() {
        IOPLog().step(source: "SILIOPTesterViewModel",
                      action: "Preparing IOP test report",
                      detail: "Collecting phone info, firmware info, connection parameters, and test results.")
        let deviceGuru = DeviceGuruImplementation()
        let deviceName = deviceGuru.hardware
        
        let deviceSystemVersion = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
                
        testReport = SILIOPTestReport(timestamp: timestamp ?? Date(),
                                      phoneInfo: SILIOPTestPhoneInfo(phoneName: "\(deviceName)", phoneOSVersion: deviceSystemVersion),
                                      firmwareInfo: firmwareInfo,
                                      connectionParameters: connectionParameters,
                                      testCaseResults: testCaseResults)
    }
    
    func getReportFile() -> URL {
            let fileWriter = SILIOPFileWriter(firmware: self.firmwareInfo?.firmware ?? .unknown,
                                              timestamp: self.timestamp ?? Date(),
                                              deviceModelName: self.deviceModelName)
            
            
            if fileWriter.createEmptyFile(atPath: fileWriter.getFilePath), let testReport = self.testReport {
                let report = testReport.generateReport()
                if fileWriter.openFile(filePath: fileWriter.getFilePath) {
                    _ = fileWriter.append(text: report)
                    fileWriter.closeFile()
                }
            }
       
        
        return  fileWriter.getFileUrl
    }

    func getConsolLogsFile() -> URL? {
        if let fileLogger = DDLog.allLoggers.last as? DDFileLogger {
            return URL(fileURLWithPath: fileLogger.currentLogFileInfo!.filePath)
        }
        return nil
    }
}
