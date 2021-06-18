//
//  SILServiceMandatoryRequirementsSupplierSpec.swift
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

class SILServiceMandatoryRequirementsSupplierSpec: QuickSpec {
    
    override func spec() {
        context("SILServiceMandatoryRequirementsSupplier") {
            var supplier: SILServiceMandatoryRequirementsSupplier! 
            var result: [SILGattConfigurationCharacteristicEntity]!
            
            beforeSuite {
                supplier = SILServiceMandatoryRequirementsSupplier()
                result = supplier.getMandatoryCharacteristics(serviceUuid: "180F")
            }

            describe("getMandatoryCharacteristics()") {
                it("should have right count of characteristic") {
                    expect(result.count).to(equal(1))
                }
                
                it("should have the same characteristic") {
                    let expectedCharacteristic = SILGattConfigurationCharacteristicEntity()
                    expectedCharacteristic.name = "Battery Level"
                    expectedCharacteristic.cbuuidString = "2A19"
                    expectedCharacteristic.properties = [
                        SILGattConfigurationProperty(type: .read, permission: .none),
                        SILGattConfigurationProperty(type: .notify, permission: .none)
                    ]
                    expectedCharacteristic.initialValueType = .none
                    expectedCharacteristic.initialValue = nil
                    for _ in 1...2 {
                        expectedCharacteristic.descriptors.append(SILGattConfigurationDescriptorEntity())
                    }
                    expect(result.first!).to(hasTheSameBluetoothFields(expectedCharacteristic))
                }
                
                it("should have the same descriptors") {
                    let characteristicPresentationFormatDescriptor = SILGattConfigurationDescriptorEntity()
                    characteristicPresentationFormatDescriptor.name = "Characteristic Presentation Format"
                    characteristicPresentationFormatDescriptor.cbuuidString = "2904"
                    characteristicPresentationFormatDescriptor.properties = [
                        SILGattConfigurationProperty(type: .read, permission: .none)
                    ]
                    characteristicPresentationFormatDescriptor.initialValueType = .text
                    characteristicPresentationFormatDescriptor.initialValue = "N/A - managed by system"
                    
                    let clientCharacteristicConfigurationDescriptor = SILGattConfigurationDescriptorEntity()
                    clientCharacteristicConfigurationDescriptor.name = "Client Characteristic Configuration"
                    clientCharacteristicConfigurationDescriptor.cbuuidString = "2902"
                    clientCharacteristicConfigurationDescriptor.properties = [
                        SILGattConfigurationProperty(type: .read, permission: .none),
                        SILGattConfigurationProperty(type: .write, permission: .none)
                    ]
                    clientCharacteristicConfigurationDescriptor.initialValueType = .text
                    clientCharacteristicConfigurationDescriptor.initialValue = "N/A - managed by system"
                    
                    expect(result.first!.descriptors.count).to(equal(2))
                    expect(result.first!.descriptors[0]).to(hasTheSameBluetoothFields(characteristicPresentationFormatDescriptor))
                    expect(result.first!.descriptors[1]).to(hasTheSameBluetoothFields(clientCharacteristicConfigurationDescriptor))
                }
            }
        }
    }
}
