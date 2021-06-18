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

class SILBluetoothServiceDescriptorPropertiesSpec: QuickSpec {
    
    override func spec() {
        context("SILBluetoothServiceDescriptorProperties") {
            var propertyDict: NSDictionary!
            var properties: SILBluetoothServiceDescriptorProperties!
            beforeEach {
                propertyDict = [
                    "Read" : "Excluded",
                    "Write" : "Mandatory"
                ]
                properties = SILBluetoothServiceDescriptorProperties(propertyDict: propertyDict)
            }

            describe("init") {
                it("should have set right properties") {
                    expect(properties.propertyMap[.Read]).to(equal(.Excluded))
                    expect(properties.propertyMap[.Write]).to(equal(.Mandatory))
                }
            }
            
            describe("mandatoriesProperties") {
                it("should have set right properties") {
                    expect(properties.mandatoryProperties.count).to(equal(1))
                    expect(properties.mandatoryProperties).to(contain(.Write))
                }
            }
        }
    }
}
