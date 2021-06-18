//
//  SILGattAssignedNumberDropDownInfoSpec.swift
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 26/04/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

@testable import BlueGecko

import Foundation
import Quick
import Nimble
import RealmSwift

class SILGattAssignedNumberDropDownInfoSpec: QuickSpec {
    
    override func spec() {
        context("SILGattAssignedNumberDropDownInfo") {
            context("service type") {
                var dropDownInfo: SILGattAssignedNumberDropDownInfo!
                
                beforeSuite {
                    dropDownInfo = SILGattAssignedNumberDropDownInfo(entityType: .service, repository: SILGattAssignedNumbersRepository())
                }
                
                describe("autocompleteValues") {
                    it("should contain service weight scale") {
                        let fullName = "Weight Scale (0x181D)"
                        expect(dropDownInfo.autocompleteValues).to(contain(fullName))
                    }
                    
                    it("should has 33 services") {
                        expect(dropDownInfo.autocompleteValues.count).to(equal(33))
                    }
                }
            }
            
            context("characteristic type") {
                var dropDownInfo: SILGattAssignedNumberDropDownInfo!
                
                beforeSuite {
                    dropDownInfo = SILGattAssignedNumberDropDownInfo(entityType: .characteristic, repository: SILGattAssignedNumbersRepository())
                }
                
                describe("autocompleteValues") {
                    it("should contain service waist circumference") {
                        let fullName = "Waist Circumference (0x2A97)"
                        expect(dropDownInfo.autocompleteValues).to(contain(fullName))
                    }
                    
                    it("should has 180 services") {
                        expect(dropDownInfo.autocompleteValues.count).to(equal(180))
                    }
                }
            }
            
            describe("isUUID16Right") {
                var dropDownInfo: SILGattAssignedNumberDropDownInfo!
                
                beforeSuite {
                    dropDownInfo = SILGattAssignedNumberDropDownInfo(entityType: .characteristic, repository: SILGattAssignedNumbersRepository())
                }
                
                it("should 0x2343 be true") {
                    let uuid = "0x2343"
                    expect(dropDownInfo.isUUID16Right(uuid: uuid)).to(beTrue())
                }
                
                it("should 0x23g3 be false") {
                    let uuid = "0x23g3"
                    expect(dropDownInfo.isUUID16Right(uuid: uuid)).to(beFalse())
                }
                
                it("should 0x23aff3 be false") {
                    let uuid = "0x23aff3"
                    expect(dropDownInfo.isUUID16Right(uuid: uuid)).to(beFalse())
                }
                
                it("should aaff be true") {
                    let uuid = "aaff"
                    expect(dropDownInfo.isUUID16Right(uuid: uuid)).to(beTrue())
                }
                
                it("should aagf be false") {
                    let uuid = "aagf"
                    expect(dropDownInfo.isUUID16Right(uuid: uuid)).to(beFalse())
                }
                
                it("should aaf456 be false") {
                    let uuid = "aaf456"
                    expect(dropDownInfo.isUUID16Right(uuid: uuid)).to(beFalse())
                }
            }
            
            describe("isUUID128Right") {
                var dropDownInfo: SILGattAssignedNumberDropDownInfo!
                
                beforeSuite {
                    dropDownInfo = SILGattAssignedNumberDropDownInfo(entityType: .characteristic, repository: SILGattAssignedNumbersRepository())
                }
                
                it("should aaffafcd-dada-adad-acdc-adfdadfdadfd be true") {
                    let uuid = "aaffafcd-dada-adad-acdc-adfdadfdadfd"
                    expect(dropDownInfo.isUUID128Right(uuid: uuid)).to(beTrue())
                }
                
                it("should aaffafcd-dada-adad-acdc-adfdadfdadfhh be false") {
                    let uuid = "aaffafcd-dada-adad-acdc-adfdadfdadfhh"
                    expect(dropDownInfo.isUUID128Right(uuid: uuid)).to(beFalse())
                }
                
                it("should aaffafcd-adad-acdc-aaaddaaddacd be false") {
                    let uuid = "aaffafcd-adad-acdc-aaaddaaddacd"
                    expect(dropDownInfo.isUUID128Right(uuid: uuid)).to(beFalse())
                }
            }
            
            describe("onlyHexString") {
                
                it("should adfvcasdfa return adfcadfa") {
                    let string = "adfvcasdfa"
                    let expected = "adfcadfa"
                    expect(SILGattAssignedNumberDropDownInfo.onlyHexString(string)).to(equal(expected))
                }
                
                it("should aafa return aafa") {
                    let string = "aafa"
                    let expected = "aafa"
                    expect(SILGattAssignedNumberDropDownInfo.onlyHexString(string)).to(equal(expected))
                }
                
                it("should rtgrg return none") {
                    let string = "rtgrg"
                    let expected = ""
                    expect(SILGattAssignedNumberDropDownInfo.onlyHexString(string)).to(equal(expected))
                }
            }
        }
    }
}
