//
//  SILThroughputConnectionParametersDecoderTest.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 17.5.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import BlueGecko

class SILThroughputConnectionParametersDecoderTest: QuickSpec {
    private var testObject: SILThroughputConnectionParametersDecoder!
    
    override func spec() {
        beforeEach {
            self.testObject = SILThroughputConnectionParametersDecoder()
        }
        
        afterEach {
            self.testObject = nil
        }
        
        describe("decode PHY status") {
            it("should return 1M") {
                let result = self.testObject.decode(data: Data([0x01]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.PHYStatus.cbUUID)
                
                switch result {
                case let .phy(phy: phy):
                    expect(phy).to(equal(._1M))
                
                default:
                    fail("Wrong case")
                }
            }
            
            it("should return 2M") {
                let result = self.testObject.decode(data: Data([0x02]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.PHYStatus.cbUUID)
                
                switch result {
                case let .phy(phy: phy):
                    expect(phy).to(equal(._2M))
                
                default:
                    fail("Wrong case")
                }
            }
            
            it("should return Coded 125k") {
                let result = self.testObject.decode(data: Data([0x04]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.PHYStatus.cbUUID)
                
                switch result {
                case let .phy(phy: phy):
                    expect(phy).to(equal(._125k))
                
                default:
                    fail("Wrong case")
                }
            }
            
            it("should return Coded 500k") {
                let result = self.testObject.decode(data: Data([0x08]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.PHYStatus.cbUUID)
                
                switch result {
                case let .phy(phy: phy):
                    expect(phy).to(equal(._500k))
                
                default:
                    fail("Wrong case")
                }
            }
            
            it("should return unknown - wrong value") {
                let result = self.testObject.decode(data: Data([0x00]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.PHYStatus.cbUUID)
                
                switch result {
                case let .phy(phy: phy):
                    expect(phy).to(equal(._unknown))
                
                default:
                    fail("Wrong case")
                }
            }
        }
        
        describe("decode Connection Interval") {
            it("should return correct value - one byte only") {
                let result = self.testObject.decode(data: Data([0x04, 0x00, 0x00, 0x00]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.ConnectionInterval.cbUUID)
                
                switch result {
                case let .connectionInterval(value: value):
                    expect(value).to(equal(5.0))
                
                default:
                    fail("Wrong case")
                }
            }
            
            it("should return correct value - two bytes") {
                let result = self.testObject.decode(data: Data([0x00, 0x01, 0x00, 0x00]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.ConnectionInterval.cbUUID)
                
                switch result {
                case let .connectionInterval(value: value):
                    expect(value).to(equal(320.0))
                
                default:
                    fail("Wrong case")
                }
            }
            
            it("should return correct value - three bytes") {
                let result = self.testObject.decode(data: Data([0x00, 0x00, 0x01, 0x00]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.ConnectionInterval.cbUUID)
                
                switch result {
                case let .connectionInterval(value: value):
                    expect(value).to(equal(81_920.0))
                
                default:
                    fail("Wrong case")
                }
            }

            it("should return correct value - four bytes") {
                let result = self.testObject.decode(data: Data([0x00, 0x00, 0x00, 0x01]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.ConnectionInterval.cbUUID)
                
                switch result {
                case let .connectionInterval(value: value):
                    expect(value).to(equal(20_971_520.0))
                
                default:
                    fail("Wrong case")
                }
            }
        }
        
        describe("decode Slave Latency") {
            it("should return correct value - one byte only") {
                let result = self.testObject.decode(data: Data([0x04, 0x00, 0x00, 0x00]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.SlaveLatency.cbUUID)
                
                switch result {
                case let .slaveLatency(value: value):
                    expect(value).to(equal(5.0))
                
                default:
                    fail("Wrong case")
                }
            }
            
            it("should return correct value - two bytes") {
                let result = self.testObject.decode(data: Data([0x00, 0x01, 0x00, 0x00]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.SlaveLatency.cbUUID)
                
                switch result {
                case let .slaveLatency(value: value):
                    expect(value).to(equal(320.0))
                
                default:
                    fail("Wrong case")
                }
            }
            
            it("should return correct value - three bytes") {
                let result = self.testObject.decode(data: Data([0x00, 0x00, 0x01, 0x00]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.SlaveLatency.cbUUID)
                
                switch result {
                case let .slaveLatency(value: value):
                    expect(value).to(equal(81_920.0))
                
                default:
                    fail("Wrong case")
                }
            }

            it("should return correct value - four bytes") {
                let result = self.testObject.decode(data: Data([0x00, 0x00, 0x00, 0x01]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.SlaveLatency.cbUUID)
                
                switch result {
                case let .slaveLatency(value: value):
                    expect(value).to(equal(20_971_520.0))
                
                default:
                    fail("Wrong case")
                }
            }
        }
        
        describe("decode Supervision Timeout") {
            it("should return correct value - one byte only") {
                let result = self.testObject.decode(data: Data([0x04, 0x00, 0x00, 0x00]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.SupervisionTimeout.cbUUID)
                
                switch result {
                case let .supervisionTimeout(value: value):
                    expect(value).to(equal(40.0))
                
                default:
                    fail("Wrong case")
                }
            }
            
            it("should return correct value - two bytes") {
                let result = self.testObject.decode(data: Data([0x00, 0x01, 0x00, 0x00]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.SupervisionTimeout.cbUUID)
                
                switch result {
                case let .supervisionTimeout(value: value):
                    expect(value).to(equal(2560.0))
                
                default:
                    fail("Wrong case")
                }
            }
            
            it("should return correct value - three bytes") {
                let result = self.testObject.decode(data: Data([0x00, 0x00, 0x01, 0x00]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.SupervisionTimeout.cbUUID)
                
                switch result {
                case let .supervisionTimeout(value: value):
                    expect(value).to(equal(655_360.0))
                
                default:
                    fail("Wrong case")
                }
            }

            it("should return correct value - four bytes") {
                let result = self.testObject.decode(data: Data([0x00, 0x00, 0x00, 0x01]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.SupervisionTimeout.cbUUID)
                
                switch result {
                case let .supervisionTimeout(value: value):
                    expect(value).to(equal(167_772_160.0))
                
                default:
                    fail("Wrong case")
                }
            }
        }
        
        describe("decode PDU Size") {
            it("should return correct value - one byte only") {
                let result = self.testObject.decode(data: Data([0xFF]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.PDUSize.cbUUID)
                
                switch result {
                case let .pdu(value: value):
                    expect(value).to(equal(255))
                
                default:
                    fail("Wrong case")
                }
            }
            
            it("should return that value is incoreect") {
                let result = self.testObject.decode(data: Data([0x00, 0x01]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.PDUSize.cbUUID)
                
                switch result {
                case let .pdu(value: value):
                    expect(value).to(equal(-1))
                
                default:
                    fail("Wrong case")
                }
            }
        }
        
        describe("decode MTU Size") {
            it("should return correct value - one byte only") {
                let result = self.testObject.decode(data: Data([0xFF]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.MTUSize.cbUUID)
                
                switch result {
                case let .mtu(value: value):
                    expect(value).to(equal(255))
                
                default:
                    fail("Wrong case")
                }
            }
            
            it("should return that value is incoreect") {
                let result = self.testObject.decode(data: Data([0x00, 0x01]), characterisitc: SILThroughputPeripheralGATTDatabase.ThroughputInformationService.MTUSize.cbUUID)
                
                switch result {
                case let .mtu(value: value):
                    expect(value).to(equal(-1))
                
                default:
                    fail("Wrong case")
                }
            }
        }
    }
}
