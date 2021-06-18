//
//  SILIOPTesterViewModel.swift
//  BlueGecko
//
//  Created by RAVI KUMAR on 03/12/19.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth

class SILIOPTesterViewModel: NSObject {
    let nameAckOTA = "IOP Test Update"
    let nameNoneAckOTA = "IOP Test"
    
    var central: SILIOPTesterCentralManager = SILIOPTesterCentralManager()
    var disposeBag =  SILObservableTokenBag()
    var peripheral: CBPeripheral?
    var peripheralServices: [CBService] = []
    var peripheralDelegate: SILIOPTesterPeripheralDelegate!
    
    var centralManager = SILCentralManager(serviceUUIDs: [])
    var deviceNameToSearch:String!
    var selectedPeripheral: SILDiscoveredPeripheral!
    
    //MARK: INITIALIZATION
    
    init(deviceNameToSearch: String) {
        super.init()
        self.deviceNameToSearch = deviceNameToSearch
    }
    
    deinit {
        print("DeInit Called")
    }
        
    // MARK: Start Test
    
    func startTest() {
        let numberOfTests = SILIOPTester_Test1.numberOfTests() + SILIOPTester_Test2.numberOfTests() + SILIOPTester_Test3.numberOfTests()
        
        debugPrint("THERE IS \(numberOfTests) TESTS")
        
        debugPrint("CREATE TEST OBJECT WITH CENTRAL MANAGER AND \(String(describing: self.deviceNameToSearch))")
        let test = SILIOPTester_Test1()
        test.injectParameters(parameters: ["centralManager": self.central,
                                           "peripheralLocalName": self.deviceNameToSearch])
        debugPrint("START TEST")
        weak var weakSelf = self
        let observer = test.testResults.observe({ testResults in
            if testResults.isEmpty { return }
            guard let weakSelf = weakSelf else { return }
            var testScenarioResult: IOPTestStatus = .None
            for testResult in testResults {
                debugPrint("TEST RESULT \(testResult.testID) \(testResult.testName) \(testResult.testResult)")
                testScenarioResult = testResult.testResult
            }
            if testScenarioResult == .Pass {
                let dict = test.getTestsArtifacts()
                weakSelf.selectedPeripheral = dict["discoveredPeripheral"] as? SILDiscoveredPeripheral
                weakSelf.startTest2()
            } else if testScenarioResult == .InProgress {
                debugPrint("SHOULD UPDATE UI")
            } else {
                debugPrint("TEST CANCELLED")
            }
        })
        self.disposeBag.add(token: observer)
        
        test.performTestScenario()
    }
    
    func startTest2() {
        let test2 = SILIOPTester_Test2()
        test2.injectParameters(parameters: ["centralManager": self.central,
                                            "discoveredPeripheral": self.selectedPeripheral!])
        weak var weakSelf = self
        let observer2 = test2.testResults.observe({ testResults in
            if testResults.isEmpty { return }
            guard let weakSelf = weakSelf else { return }
            var testScenarioResult: IOPTestStatus = .None
            for testResult in testResults {
                debugPrint("TEST RESULT \(testResult.testID) \(testResult.testName) \(testResult.testResult)")
                testScenarioResult = testResult.testResult
            }
            if testScenarioResult == .Pass {
                let dict = test2.getTestsArtifacts()
                weakSelf.peripheral = dict["peripheral"] as? CBPeripheral
                weakSelf.peripheralDelegate = SILIOPTesterPeripheralDelegate(peripheral: weakSelf.peripheral!)
                weakSelf.startTest3()
            } else if testScenarioResult == .InProgress {
                debugPrint("SHOULD UPDATE UI")
            } else {
                debugPrint("TEST CANCELLED")
            }
        })
        self.disposeBag.add(token: observer2)
        
        test2.performTestScenario()
    }
    
    func startTest3() {
        let test3 = SILIOPTester_Test3()
        test3.injectParameters(parameters: ["peripheral": self.peripheral!,
                                            "peripheralDelegate": self.peripheralDelegate])
        
        weak var weakSelf = self
        let observer3 = test3.testResults.observe({ testResults in
            if testResults.isEmpty { return }
            guard let weakSelf = weakSelf else { return }
            var testScenarioResult: IOPTestStatus = .None
            for testResult in testResults {
                debugPrint("TEST RESULT \(testResult.testID) \(testResult.testName) \(testResult.testResult)")
                testScenarioResult = testResult.testResult
            }
            if testScenarioResult == .Pass {
                let dict = test3.getTestsArtifacts()
                weakSelf.peripheral = dict["peripheral"] as? CBPeripheral
                weakSelf.peripheralServices = (dict["services"] as? [CBService])!
                weakSelf.startTest4()
            } else if testScenarioResult == .InProgress {
                debugPrint("SHOULD UPDATE UI")
            } else {
                debugPrint("TEST CANCELLED")
            }
        })
        self.disposeBag.add(token: observer3)
        
        test3.performTestScenario()
    }
    
    func startTest4() {
        let test4 = SILIOPTester_Test4()
        test4.injectParameters(parameters: ["peripheral": self.peripheral!,
                                            "services": self.peripheralServices,
                                            "peripheralDelegate": self.peripheralDelegate])
        
        weak var weakSelf = self
        let observer4 = test4.testResults.observe({ testResults in
            if testResults.isEmpty { return }
            guard let weakSelf = weakSelf else { return }
            var testScenarioResult: IOPTestStatus = .None
            for testResult in testResults {
                debugPrint("TEST RESULT \(testResult.testID) \(testResult.testName) \(testResult.testResult)")
                testScenarioResult = testResult.testResult
            }
            if testScenarioResult == .Pass {
                let dict = test4.getTestsArtifacts()
                weakSelf.peripheralServices = (dict["services"] as? [CBService])!
                weakSelf.startTest5()
            } else if testScenarioResult == .InProgress {
                debugPrint("SHOULD UPDATE UI")
            } else {
                debugPrint("TEST CANCELLED")
            }
        })
        self.disposeBag.add(token: observer4)
        
        test4.performTestScenario()
    }
    
    func startTest5() {
        let test5 = SILIOPTester_Test5()
        test5.injectParameters(parameters: ["centralManager": self.centralManager,
                                            "peripheral": self.peripheral!,
                                            "central": self.central,
                                            "peripheralLocalName": self.deviceNameToSearch])
        weak var weakSelf = self
        let observer5 = test5.testResults.observe({ testResults in
            if testResults.isEmpty { return }
            guard let weakSelf = weakSelf else { return }
            var testScenarioResult: IOPTestStatus = .None
            for testResult in testResults {
                debugPrint("TEST RESULT \(testResult.testID) \(testResult.testName) \(testResult.testResult)")
                testScenarioResult = testResult.testResult
            }
            if testScenarioResult == .Pass {
                let dict = test5.getTestsArtifacts()
                self.peripheral = dict["peripheral"] as? CBPeripheral
                self.selectedPeripheral = dict["discoveredPeripheral"] as? SILDiscoveredPeripheral
                weakSelf.startTest6()
            } else if testScenarioResult == .InProgress {
                debugPrint("SHOULD UPDATE UI")
            } else {
                debugPrint("TEST CANCELLED")
            }
        })
        self.disposeBag.add(token: observer5)
        
        test5.performTestScenario()
    }
    
    func startTest6() {
        let test6 = SILIOPTester_Test6()
        test6.injectParameters(parameters: ["centralManager": self.centralManager,
                                            "peripheral": self.peripheral!])
        weak var weakSelf = self
        let observer6 = test6.testResults.observe({ testResults in
            if testResults.isEmpty { return }
            guard let weakSelf = weakSelf else { return }
            var testScenarioResult: IOPTestStatus = .None
            for testResult in testResults {
                debugPrint("TEST RESULT \(testResult.testID) \(testResult.testName) \(testResult.testResult)")
                testScenarioResult = testResult.testResult
            }
            if testScenarioResult == .Pass {
                let _ = test6.getTestsArtifacts()
                weakSelf.startTest7()
            } else if testScenarioResult == .InProgress {
                debugPrint("SHOULD UPDATE UI")
            } else {
                debugPrint("TEST CANCELLED")
            }
        })
        self.disposeBag.add(token: observer6)
        
        test6.performTestScenario()
    }
    
    func startTest7() {
        let test7 = SILIOPTester_Test7()
        test7.injectParameters(parameters: ["centralManager": self.central,
                                            "discoveredPeripheral": self.selectedPeripheral!])
        
        weak var weakSelf = self
        let observer7 = test7.testResults.observe( { testResults in
            if testResults.isEmpty { return }
            guard let weakSelf = weakSelf else { return }
            var testScenarioResult: IOPTestStatus = .None
            for testResult in testResults {
                debugPrint("TEST RESULT \(testResult.testID) \(testResult.testName) \(testResult.testResult)")
                testScenarioResult = testResult.testResult
            }
            if testScenarioResult == .Pass {
                let dict = test7.getTestsArtifacts()
                self.peripheral = dict["peripheral"] as? CBPeripheral
                self.peripheralDelegate = dict["peripheralDelegate"] as? SILIOPTesterPeripheralDelegate
                weakSelf.startTest9()
            } else if testScenarioResult == .InProgress {
                debugPrint("SHOULD UPDATE UI")
            } else {
                debugPrint("TEST CANCELLED")
            }
        })
        self.disposeBag.add(token: observer7)
        
        test7.performTestScenario()
    }
    
    func startTest9() {
        let test9 = SILIOPTester_Test9()
        
        test9.injectParameters(parameters: ["centralManager" : self.central,
                                            "discoveredPeripheral" : self.selectedPeripheral!,
                                            "peripheral" : self.peripheral!,
                                            "peripheralDelegate" : self.peripheralDelegate])
        
        weak var weakSelf = self
        let observer9 = test9.testResults.observe( { testResults in
            if testResults.isEmpty { return }
            guard let weakSelf = weakSelf else { return }
            var testScenarioResult: IOPTestStatus = .None
            for testResult in testResults {
                debugPrint("TEST RESULT \(testResult.testID) \(testResult.testName) \(testResult.testResult)")
                testScenarioResult = testResult.testResult
            }
            if testScenarioResult == .Pass {
                _ = test9.getTestsArtifacts()
                weakSelf.startTest8()
            } else if testScenarioResult == .InProgress {
                debugPrint("SHOULD UPDATE UI")
            } else {
                debugPrint("TEST CANCELLED")
            }
        })
        self.disposeBag.add(token: observer9)
        
        test9.performTestScenario()
    }
    
    func startTest8() {
        let test8 = SILIOPTester_Test8()

        test8.injectParameters(parameters: ["centralManager" : self.central,
                                            "discoveredPeripheral" : self.selectedPeripheral!,
                                            "peripheral" : self.peripheral!,
                                            "peripheralDelegate" : self.peripheralDelegate])
        
        weak var weakSelf = self
        let observer8 = test8.testResults.observe( { testResults in
            if testResults.isEmpty { return }
            guard weakSelf != nil else { return }
            var testScenarioResult: IOPTestStatus = .None
            for testResult in testResults {
                debugPrint("TEST RESULT \(testResult.testID) \(testResult.testName) \(testResult.testResult)")
                testScenarioResult = testResult.testResult
            }
            if testScenarioResult == .Pass {
                _ = test8.getTestsArtifacts()
            } else if testScenarioResult == .InProgress {
                debugPrint("SHOULD UPDATE UI")
            } else {
                debugPrint("TEST CANCELLED")
            }
        })
        self.disposeBag.add(token: observer8)
        
        test8.performTestScenario()
    }
    
    func logDeviceInfo() {
        let date = Date.longStyleDateFormatter().string(from: Date())
        SILLogger.sharedInstance.log(text: "<timestamp>\(date)</timestamp>")
        let deviceData = UIDevice.getCurrentDeviceInfo()
        SILLogger.sharedInstance.log(text: "<phone_informations> \n\t <phone_name>\(deviceData.modelName)</phone_name>")
        SILLogger.sharedInstance.log(text: "\t <phone_os_version>\(deviceData.SystemVersion)</phone_os_version> \n</phone_informations>")
    }
}
