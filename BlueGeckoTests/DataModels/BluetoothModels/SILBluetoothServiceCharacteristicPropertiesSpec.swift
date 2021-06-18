//
//  SILBluetoothServiceCharacteristicPropertiesSpec.swift
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 15/04/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

@testable import BlueGecko

import Foundation
import Quick
import Nimble
import RealmSwift

class SILBluetoothServiceCharacteristicPropertiesSpec: QuickSpec {
    
    override func spec() {
        context("SILBluetoothServiceCharacteristicProperties") {
            var propertyDict: NSDictionary!
            var properties: SILBluetoothServiceCharacteristicProperties!
            beforeEach {
                propertyDict = [
                    "Broadcast" : "Excluded",
                    "Indicate" : "Excluded",
                    "Notify" : "Mandatory",
                    "Read" : "Excluded",
                    "ReliableWrite" : "Excluded",
                    "SignedWrite" : "Excluded",
                    "WritableAuxiliaries" : "Excluded",
                    "Write" : "Optional",
                    "WriteWithoutResponse" : "Excluded",
                ]
                properties = SILBluetoothServiceCharacteristicProperties(propertyDict: propertyDict)
            }

            describe("init") {
                it("should have set right properties") {
                    expect(properties.propertyMap[.Broadcast]).to(equal(.Excluded))
                    expect(properties.propertyMap[.Indicate]).to(equal(.Excluded))
                    expect(properties.propertyMap[.Notify]).to(equal(.Mandatory))
                    expect(properties.propertyMap[.Read]).to(equal(.Excluded))
                    expect(properties.propertyMap[.ReliableWrite]).to(equal(.Excluded))
                    expect(properties.propertyMap[.SignedWrite]).to(equal(.Excluded))
                    expect(properties.propertyMap[.WritableAuxiliaries]).to(equal(.Excluded))
                    expect(properties.propertyMap[.Write]).to(equal(.Optional))
                    expect(properties.propertyMap[.WriteWithoutResponse]).to(equal(.Excluded))
                }
            }
            
            describe("mandatoriesProperties") {
                it("should have set right properties") {
                    expect(properties.mandatoryProperties.count).to(equal(2))
                    expect(properties.mandatoryProperties).to(contain(.Notify))
                    expect(properties.mandatoryProperties).to(contain(.Write))
                }
            }
        }
    }
}
