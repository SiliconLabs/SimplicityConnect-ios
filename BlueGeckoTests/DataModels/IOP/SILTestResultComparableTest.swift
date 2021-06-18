//
//  SILTestResultComparableTest.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 23.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import BlueGecko

class SILTestResultComparableTest: QuickSpec {
    private var testObject1: SILTestResult!
    private var testObject2: SILTestResult!
    
    private let testName = "Test"
    private let testStatus = SILTestStatus.none
    
    override func spec() {
        afterEach {
            self.testObject1 = nil
            self.testObject2 = nil
        }
        
        describe("<") {
            it("1 < 2 -> true") {
                self.testObject1 = SILTestResult(testID: "1", testName: self.testName, testStatus: self.testStatus)
                self.testObject2 = SILTestResult(testID: "2", testName: self.testName, testStatus: self.testStatus)
                
                expect(self.testObject1 < self.testObject2).to(equal(true))
            }
            
            it("1 < 2.5 -> true") {
                self.testObject1 = SILTestResult(testID: "1", testName: self.testName, testStatus: self.testStatus)
                self.testObject2 = SILTestResult(testID: "2.5", testName: self.testName, testStatus: self.testStatus)
                
                expect(self.testObject1 < self.testObject2).to(equal(true))
            }
            
            it("2.1 < 2.2 -> true") {
                self.testObject1 = SILTestResult(testID: "2.1", testName: self.testName, testStatus: self.testStatus)
                self.testObject2 = SILTestResult(testID: "2.2", testName: self.testName, testStatus: self.testStatus)
                
                expect(self.testObject1 < self.testObject2).to(equal(true))
            }
            
            it("4.9 < 4.10 -> true") {
                self.testObject1 = SILTestResult(testID: "4.9", testName: self.testName, testStatus: self.testStatus)
                self.testObject2 = SILTestResult(testID: "4.10", testName: self.testName, testStatus: self.testStatus)
                
                expect(self.testObject1 < self.testObject2).to(equal(true))
            }
            
            it("4.10 < 7 -> true") {
                self.testObject1 = SILTestResult(testID: "4.10", testName: self.testName, testStatus: self.testStatus)
                self.testObject2 = SILTestResult(testID: "7", testName: self.testName, testStatus: self.testStatus)
                
                expect(self.testObject1 < self.testObject2).to(equal(true))
            }
        }
        
        describe("==") {
            it("1 == 1 -> true") {
                self.testObject1 = SILTestResult(testID: "1", testName: self.testName, testStatus: self.testStatus)
                self.testObject2 = SILTestResult(testID: "1", testName: self.testName, testStatus: self.testStatus)
                
                expect(self.testObject1 == self.testObject2).to(equal(true))
            }
            
            it("2.1 == 2.1 -> true") {
                self.testObject1 = SILTestResult(testID: "2.1", testName: self.testName, testStatus: self.testStatus)
                self.testObject2 = SILTestResult(testID: "2.1", testName: self.testName, testStatus: self.testStatus)
                
                expect(self.testObject1 == self.testObject2).to(equal(true))
            }
            
            it("4.10 == 4.10 -> true") {
                self.testObject1 = SILTestResult(testID: "4.10", testName: self.testName, testStatus: self.testStatus)
                self.testObject2 = SILTestResult(testID: "4.10", testName: self.testName, testStatus: self.testStatus)
                
                expect(self.testObject1 == self.testObject2).to(equal(true))
            }
        }
    }
}
