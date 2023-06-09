//
//  SILESLCommandRunnerFactoryTestSpec.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 24.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation
import Quick
import Nimble
import CoreBluetooth
import Mockingbird
import RxSwift
import RxCocoa
@testable import BlueGecko

class SILESLCommandRunnerFactoryTestSpec: QuickSpec {
    var sut: SILESLCommandRunnerFactory!
    var peripheralMock: CBPeripheral!
    var peripheralReferencesMock: SILESLPeripheralGATTReferences!
    var addressMock: SILAddress!
    
    override func spec() {
        beforeEach {
            self.sut = SILESLCommandRunnerFactory()
            self.peripheralMock = mock(CBPeripheral.self)
            self.peripheralReferencesMock = SILESLPeripheralGATTReferences()
            self.addressMock = .eslId(.broadcast)
        }
        
        describe("createCommandProvisioning") {
            it("should create proper object") {
                let provisioning = self.sut.createCommandProvisioning(peripheral: self.peripheralMock,
                                                                      peripheralReferences: self.peripheralReferencesMock,
                                                                      commandRunnerFactory: self.sut,
                                                                      address: SILBluetoothAddress(address: "", addressType: .public),
                                                                      passcode: "12345")
             
                expect(provisioning.isKind(of: SILESLProvisioningTag.self)).to(beTrue())
            }
        }
        
        describe("createCommandImageUpdate") {
            it("should create proper object") {
                let imageUpdate = self.sut.createCommandImageUpdate(peripheral: self.peripheralMock,
                                                                    peripheralReferences: self.peripheralReferencesMock,
                                                                    commandRunnerFactory: self.sut,
                                                                    address: .unicast(id: 5),
                                                                    imageIndex: 0,
                                                                    imageFile: URL(string: "../apple.png")!,
                                                                    showImageAfterUpdate: true)
             
                expect(imageUpdate.isKind(of: SILESLImageUpdate.self)).to(beTrue())
            }
        }
        
        describe("createCommandConnectRunner") {
            it("should create proper object") {
                let connectRunner = self.sut.createCommandConnectRunner(peripheral: self.peripheralMock,
                                                                        peripheralReferences: self.peripheralReferencesMock,
                                                                        address: self.addressMock,
                                                                        passcode: "12345")
             
                expect(connectRunner.isKind(of: SILESLCommandConnectRunner.self)).to(beTrue())
            }
        }
        
        describe("createCommandDisconnectRunner") {
            it("should create proper object") {
                let disconnectRunner = self.sut.createCommandDisconnectRunner(peripheral: self.peripheralMock,
                                                                              peripheralReferences: self.peripheralReferencesMock,
                                                                              address: self.addressMock)
             
                expect(disconnectRunner.isKind(of: SILESLCommandDisconnectRunner.self)).to(beTrue())
            }
        }
        
        describe("createCommandImageUpdateRunner") {
            it("should create proper object") {
                let updateImageRunner = self.sut.createCommandImageUpdateRunner(peripheral: self.peripheralMock,
                                                                                peripheralReferences: self.peripheralReferencesMock,
                                                                                imageIndex: 4,
                                                                                imageFile: URL(string: "/")!)
             
                expect(updateImageRunner.isKind(of: SILESLCommandImageUpdateRunner.self)).to(beTrue())
            }
        }
        
        describe("createCommandLedRunner") {
            it("should create proper object") {
                let ledRunner = self.sut.createCommandLedRunner(peripheral: self.peripheralMock,
                                                                peripheralReferences: self.peripheralReferencesMock,
                                                                ledState: .off,
                                                                address: .broadcast,
                                                                index: 1)
             
                expect(ledRunner.isKind(of: SILESLCommandLedRunner.self)).to(beTrue())
            }
        }
        
        describe("createCommandDeleteRunner") {
            it("should create proper object") {
                let deleteRunner = self.sut.createCommandDeleteRunner(peripheral: self.peripheralMock,
                                                                      peripheralReferences: self.peripheralReferencesMock,
                                                                      address: self.addressMock)
             
                expect(deleteRunner.isKind(of: SILESLCommandDeleteRunner.self)).to(beTrue())
            }
        }
        
        describe("createCommandListRunner") {
            it("should create proper object") {
                let listRunner = self.sut.createCommandListRunner(peripheral: self.peripheralMock,
                                                                  peripheralReferences: self.peripheralReferencesMock)
                
                expect(listRunner.isKind(of: SILESLCommandListRunner.self)).to(beTrue())
            }
        }
        
        describe("createCommandConfigureRunner") {
            it("should create proper object") {
                let configureRunner = self.sut.createCommandConfigureRunner(peripheral: self.peripheralMock,
                                                                            peripheralReferences: self.peripheralReferencesMock)
             
                expect(configureRunner.isKind(of: SILESLCommandConfigureRunner.self)).to(beTrue())
            }
        }
        
        describe("createCommandDisplayImageRunner") {
            it("should create proper object") {
                let displayImageRunner = self.sut.createCommandDisplayImageRunner(peripheral: self.peripheralMock,
                                                                                  peripheralReferences: self.peripheralReferencesMock,
                                                                                  eslId: .broadcast,
                                                                                  imageIndex: 5,
                                                                                  displayIndex: 4)
             
                expect(displayImageRunner.isKind(of: SILESLCommandDisplayImageRunner.self)).to(beTrue())
            }
        }
        
        describe("createPingRunner") {
            it("should create proper object") {
                let provisioning = self.sut.createCommandPingRunner(peripheral: self.peripheralMock,
                                                                    peripheralReferences: self.peripheralReferencesMock,
                                                                    eslId: .broadcast)
             
                expect(provisioning.isKind(of: SILESLCommandPingRunner.self)).to(beTrue())
            }
        }
    }
}
