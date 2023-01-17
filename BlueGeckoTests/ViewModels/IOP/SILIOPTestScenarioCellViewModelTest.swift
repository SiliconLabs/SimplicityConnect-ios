//
//  SILIOPTestScenarioCellViewModelTest.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 22.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import BlueGecko

class SILIOPTestScenarioCellViewModelTest: QuickSpec {
    private var testObject: SILIOPTestScenarioCellViewModel!
    private let testName = "Test status"
    private let testDescription = "Testing a status"
        
    override func spec() {
        describe("status") {
            afterEach {
                self.testObject = nil
            }
            
            it("all tests waiting - should return waiting status of entire test scenario") {
                self.testObject = SILIOPTestScenarioCellViewModel(name: self.testName,
                                                                  description: self.testDescription,
                                                                  testCaseStatuses: [.waiting, .waiting, .waiting])
                
                expect(self.testObject.status == .waiting).to(beTrue())
            }
            
            it("all tests in progress - should return in progress status of entire test scenario") {
                self.testObject = SILIOPTestScenarioCellViewModel(name: self.testName,
                                                                  description: self.testDescription,
                                                                  testCaseStatuses: [.inProgress, .inProgress, .inProgress])
                
                expect(self.testObject.status == .inProgress).to(beTrue())
            }
            
            it("first test in progress - should return in progress status of entire test scenario") {
                self.testObject = SILIOPTestScenarioCellViewModel(name: self.testName,
                                                                  description: self.testDescription,
                                                                  testCaseStatuses: [.inProgress, .waiting, .waiting])
                
                expect(self.testObject.status == .inProgress).to(beTrue())
            }
            
            it("first test failed, but testing in progress - should return in progress status of entire test scenario") {
                self.testObject = SILIOPTestScenarioCellViewModel(name: self.testName,
                                                                  description: self.testDescription,
                                                                  testCaseStatuses: [.failed(reason: nil), .inProgress, .waiting])
                
                expect(self.testObject.status == .inProgress).to(beTrue())
            }
            
            it("two test failed, but testing in progress - should return in progress status of entire test scenario") {
                self.testObject = SILIOPTestScenarioCellViewModel(name: self.testName,
                                                                  description: self.testDescription,
                                                                  testCaseStatuses: [.failed(reason: nil), .failed(reason: nil), .waiting])
                
                expect(self.testObject.status == .inProgress).to(beTrue())
            }
            
            it("all test failed - should return failed status of entire test scenario") {
                self.testObject = SILIOPTestScenarioCellViewModel(name: self.testName,
                                                                  description: self.testDescription,
                                                                  testCaseStatuses: [.failed(reason: nil), .failed(reason: nil), .failed(reason: nil)])
                
                expect(self.testObject.status == .failed(reason: nil)).to(beTrue())
            }
            
            it("all test passed - should return passed status of entire test scenario") {
                self.testObject = SILIOPTestScenarioCellViewModel(name: self.testName,
                                                                  description: self.testDescription,
                                                                  testCaseStatuses: [.passed(details: nil), .passed(details: nil), .passed(details: nil)])
                
                expect(self.testObject.status == .passed(details: nil)).to(beTrue())
            }

            it("one of tests failed - should return failed status of entire test scenario") {
                self.testObject = SILIOPTestScenarioCellViewModel(name: self.testName,
                                                                  description: self.testDescription,
                                                                  testCaseStatuses: [.passed(details: nil), .failed(reason: nil), .passed(details: nil)])
                
                expect(self.testObject.status == .failed(reason: nil)).to(beTrue())
            }
            
            it("all tests are in uknown state - should return unknown status of entire test scenario") {
                self.testObject = SILIOPTestScenarioCellViewModel(name: self.testName,
                                                                  description: self.testDescription,
                                                                  testCaseStatuses: [.unknown(reason: nil), .unknown(reason: nil), .unknown(reason: nil)])
                
                expect(self.testObject.status == .unknown(reason: nil)).to(beTrue())
            }
            
            it("one of test unknown but testing in progress - should return in progress status of entire test scenario") {
                self.testObject = SILIOPTestScenarioCellViewModel(name: self.testName,
                                                                  description: self.testDescription,
                                                                  testCaseStatuses: [.unknown(reason: nil), .waiting, .waiting])
                
                expect(self.testObject.status == .inProgress).to(beTrue())
            }
            
            it("one of test unknown, rest of tests passed - should return passed status of entire test scenario") {
                self.testObject = SILIOPTestScenarioCellViewModel(name: self.testName,
                                                                  description: self.testDescription,
                                                                  testCaseStatuses: [.unknown(reason: nil), .passed(details: nil), .passed(details: nil)])
                
                expect(self.testObject.status == .passed(details: nil)).to(beTrue())
            }
            
            it("one of test unknown, one passed, one failed - should return failed status of entire test scenario") {
                self.testObject = SILIOPTestScenarioCellViewModel(name: self.testName,
                                                                  description: self.testDescription,
                                                                  testCaseStatuses: [.unknown(reason: nil), .failed(reason: nil), .passed(details: nil)])
                
                expect(self.testObject.status == .failed(reason: nil)).to(beTrue())
            }
        }
    }
}
