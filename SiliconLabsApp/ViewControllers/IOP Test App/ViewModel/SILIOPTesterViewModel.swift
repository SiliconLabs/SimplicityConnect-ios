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
    
    enum TestState {
        case initiated
        case running
        case ended
    }
    
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
            SILIOPTester_Test8()
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
            allTestCases += testScenario.tests.count
            
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

    func startTest() {
        createNewIOPTest()
        setInitialUIState()
        timestamp = Date.init()
        testStateStatus.value = .running
        debugPrint("START TEST")
        
        testParameters = ["iopCentralManager": self.iopCentralManager,
                          "browserCentralManager": self.browserCentralManager,
                          "peripheralLocalName": self.deviceNameToSearch] as [String : Any]
        
        iopTest[0].injectParameters(parameters: testParameters)

        for (i, _) in iopTest.enumerated() {
            weak var weakSelf = self
            observableTokens.append(iopTest[i].testResults.observe({ testResults in
                if testResults.isEmpty { return }
                guard let weakSelf = weakSelf else { return }
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
                    weakSelf.runNextTestIfPossible(index: i)
                    
                case .failed(reason: _),
                     .unknown(reason: _):
                    if weakSelf.iopTest[i].isMandatory {
                        weakSelf.markRestTestsAsFailed(fromTestAtIndex: i + 1, andfromTestID: testResults.last!.testID)
                        weakSelf.endTesting()
                    } else {
                        weakSelf.runNextTestIfPossible(index: i)
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
    
    private func runNextTestIfPossible(index i: Int) {
        let dict = iopTest[i].getTestsArtifacts()
        updateParametersDictionary(newArtifacts: dict, testIndex: i)
        
        iopTest[i].invalidateObservableTokens()
        if i + 1 < iopTest.count {
            iopTest[i + 1].injectParameters(parameters: testParameters)
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
        }
    }
    
    func endTesting() {
        debugPrint("END TESTING")
        stopTest()
        prepareTestReport()
        testStateStatus.value = .ended
    }
    
    private func prepareTestReport() {
        let deviceSystemVersion = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
                
        testReport = SILIOPTestReport(timestamp: timestamp ?? Date(),
                                      phoneInfo: SILIOPTestPhoneInfo(phoneName: self.deviceModelName, phoneOSVersion: deviceSystemVersion),
                                      firmwareInfo: firmwareInfo,
                                      connectionParameters: connectionParameters,
                                      testCaseResults: testCaseResults)
    }
    
    func getReportFile() -> URL {
        let fileWriter = SILIOPFileWriter(firmware: firmwareInfo?.firmware ?? .unknown,
                                          timestamp: timestamp ?? Date(),
                                          deviceModelName: deviceModelName)
        
        if fileWriter.createEmptyFile(atPath: fileWriter.getFilePath), let testReport = testReport {
            let report = testReport.generateReport()
            if fileWriter.openFile(filePath: fileWriter.getFilePath) {
                _ = fileWriter.append(text: report)
                fileWriter.closeFile()
            }
        }
        
        return  fileWriter.getFileUrl
    }
}
