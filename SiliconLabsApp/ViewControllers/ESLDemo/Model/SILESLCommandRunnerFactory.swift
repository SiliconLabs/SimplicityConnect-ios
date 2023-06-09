//
//  SILESLCommandRunnerFactory.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 24.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth

class SILESLCommandRunnerFactory {
    func createCommandProvisioning(peripheral: CBPeripheral,
                                   peripheralReferences: SILESLPeripheralGATTReferences,
                                   commandRunnerFactory: SILESLCommandRunnerFactory,
                                   address: SILBluetoothAddress,
                                   passcode: String? = nil) -> SILESLProvisioningTag {
        return SILESLProvisioningTag(peripheral: peripheral,
                                     peripheralReferences: peripheralReferences,
                                     commandRunnerFactory: commandRunnerFactory,
                                     address: address,
                                     passcode: passcode)
    }
    
    func createCommandImageUpdate(peripheral: CBPeripheral,
                                  peripheralReferences: SILESLPeripheralGATTReferences,
                                  commandRunnerFactory: SILESLCommandRunnerFactory,
                                  address: SILESLIdAddress,
                                  imageIndex: UInt,
                                  imageFile: URL,
                                  showImageAfterUpdate: Bool = false) -> SILESLImageUpdate {
        return SILESLImageUpdate(peripheral: peripheral,
                                 peripheralReferences: peripheralReferences,
                                 commandRunnerFactory: commandRunnerFactory,
                                 address: address,
                                 imageIndex: imageIndex,
                                 imageFile: imageFile,
                                 showImageAfterUpdate: showImageAfterUpdate)
    }
    
    func createCommandConnectRunner(peripheral: CBPeripheral,
                                    peripheralReferences: SILESLPeripheralGATTReferences,
                                    address: SILAddress,
                                    passcode: String? = nil) -> SILESLCommandConnectRunner {
        let connectCommand = SILESLCommandConnect(address: address,
                                                  passcode: passcode)
        return SILESLCommandConnectRunner(peripheral: peripheral,
                                          peripheralReferences: peripheralReferences,
                                          command: connectCommand)
    }
    
    func createCommandDisconnectRunner(peripheral: CBPeripheral,
                                       peripheralReferences: SILESLPeripheralGATTReferences,
                                       address: SILAddress? = nil) -> SILESLCommandDisconnectRunner {
        let disconnectCommand = SILESLCommandDisconnect(address: address)
        return SILESLCommandDisconnectRunner(peripheral: peripheral,
                                             peripheralReferences: peripheralReferences,
                                             command: disconnectCommand)
    }
    
    func createCommandImageUpdateRunner(peripheral: CBPeripheral,
                                        peripheralReferences: SILESLPeripheralGATTReferences,
                                        imageIndex: UInt,
                                        imageFile: URL) -> SILESLCommandImageUpdateRunner {
        let imageUpdateCommand = SILESLCommandImageUpdate(imageIndex: imageIndex,
                                                          imageFile: imageFile)
        return SILESLCommandImageUpdateRunner(peripheral: peripheral,
                                              peripheralReferences: peripheralReferences,
                                              command: imageUpdateCommand)
    }
    
    func createCommandLedRunner(peripheral: CBPeripheral,
                                peripheralReferences: SILESLPeripheralGATTReferences,
                                ledState: SILESLLedState,
                                address: SILESLIdAddress,
                                index: UInt) -> SILESLCommandLedRunner {
        let ledCommand = SILESLCommandLed(ledState: ledState,
                                          address: address,
                                          index: index)
        return SILESLCommandLedRunner(peripheral: peripheral,
                                      peripheralReferences: peripheralReferences,
                                      command: ledCommand)
    }
    
    func createCommandDeleteRunner(peripheral: CBPeripheral,
                                   peripheralReferences: SILESLPeripheralGATTReferences,
                                   address: SILAddress) -> SILESLCommandDeleteRunner {
        let deleteCommand = SILESLCommandDelete(address: address)
        return SILESLCommandDeleteRunner(peripheral: peripheral,
                                         peripheralReferences: peripheralReferences,
                                         command: deleteCommand)
    }
    
    func createCommandListRunner(peripheral: CBPeripheral,
                                 peripheralReferences: SILESLPeripheralGATTReferences) -> SILESLCommandListRunner {
        let listCommand = SILESLCommandList()
        return SILESLCommandListRunner(peripheral: peripheral,
                                       peripheralReferences: peripheralReferences,
                                       command: listCommand)
    }
    
    func createCommandConfigureRunner(peripheral: CBPeripheral,
                                      peripheralReferences: SILESLPeripheralGATTReferences) -> SILESLCommandConfigureRunner {
        let configureCommand = SILESLCommandConfigure()
        return SILESLCommandConfigureRunner(peripheral: peripheral,
                                            peripheralReferences: peripheralReferences,
                                            command: configureCommand)
    }
    
    func createCommandDisplayImageRunner(peripheral: CBPeripheral,
                                         peripheralReferences: SILESLPeripheralGATTReferences,
                                         eslId: SILESLIdAddress,
                                         imageIndex: UInt,
                                         displayIndex: UInt) -> SILESLCommandDisplayImageRunner {
        let displayImageCommand = SILESLCommandDisplayImage(eslId: eslId,
                                                            imageIndex: imageIndex,
                                                            displayIndex: displayIndex)
        return SILESLCommandDisplayImageRunner(peripheral: peripheral,
                                               peripheralReferences: peripheralReferences,
                                               command: displayImageCommand)
    }
    
    func createCommandPingRunner(peripheral: CBPeripheral,
                                 peripheralReferences: SILESLPeripheralGATTReferences,
                                 eslId: SILESLIdAddress) -> SILESLCommandPingRunner {
        let pingCommand = SILESLCommandPing(eslId: eslId)
        return SILESLCommandPingRunner(peripheral: peripheral,
                                       peripheralReferences: peripheralReferences,
                                       command: pingCommand)
    }
}
