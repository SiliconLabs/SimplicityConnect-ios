//
//  SILIOPGATTOperationsTestHelper.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 26.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILIOPGATTOperationsTestHelper {
    // MARK: - Validators
    
    func checkInjectedParameters(iopCentralManager: SILIOPTesterCentralManager?,
                                 peripheral: CBPeripheral?,
                                 peripheralDelegate: SILPeripheralDelegate?) -> (areValid: Bool, reason: String) {
        guard let iopCentralManager = iopCentralManager else {
            return (false, "Central manager is nil.")
        }
        
        guard iopCentralManager.bluetoothState else {
            return (false, "Bluetooth disabled!")
        }
        
        guard let _ = peripheral else {
            return (false, "Peripheral is nil.")
        }
        
        guard let _ = peripheralDelegate else {
            return (false, "Peripheral delegate is nil")
        }
        
        return (true, "")
    }
    
    // MARK: - Subscriptions
    
    func getCentralManagerSubscription(iopCentralManager: SILIOPTesterCentralManager, testCase: SILTestCase) -> SILObservableToken {
        weak var weakTestCase = testCase
        let centralManagerSubscription = iopCentralManager.newPublishConnectionStatus().observe( { status in
            guard let weakTestCase = weakTestCase else { return }
            switch status {
            case let .disconnected(peripheral: _, error: error):
                debugPrint("Peripheral disconnected with \(String(describing: error?.localizedDescription))")
                IOPLog().iopLogSwiftFunction(message: "Peripheral disconnected with \(String(describing: error?.localizedDescription))")
                weakTestCase.publishTestResult(passed: false, description: "Peripheral was disconnected with \(String(describing: error?.localizedDescription)).")
            
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    debugPrint("Bluetooth disabled!")
                    IOPLog().iopLogSwiftFunction(message: "Bluetooth disabled!")
                    weakTestCase.publishTestResult(passed: false, description: "Bluetooth disabled.")
                }
                
            case .unknown:
                break
            
            default:
                weakTestCase.publishTestResult(passed: false, description: "Unknown failure from central manager.")
            }
        })
        return centralManagerSubscription
    }
    
    func getROLenTestSubscription(for characteristicUUID: CBUUID,
                                  exceptedValue: String,
                                  peripheralDelegate: SILPeripheralDelegate,
                                  testCase: SILTestCase) -> SILObservableToken {
        weak var weakTestCase = testCase
        let peripheralDelegateSubscription = peripheralDelegate.newStatus().observe( { status in
            guard let weakTestCase = weakTestCase else { return }
            switch status {
            case let .successForCharacteristics(characteristics):
                guard let iopTestPropertiesROLen = peripheralDelegate.findCharacteristic(with: characteristicUUID, in: characteristics) else {
                    weakTestCase.publishTestResult(passed: false, description: "Characteristic RO Len wasn't discovered.")
                    return
                }
                
                guard iopTestPropertiesROLen.properties.contains(.read) else {
                    weakTestCase.publishTestResult(passed: false, description: "Characteristic RO Len doesn't have read property.")
                    return
                }
                
                peripheralDelegate.readCharacteristic(characteristic: iopTestPropertiesROLen)
                
            case let .successGetValue(value: data, characteristic: characteristic):
                if characteristic.uuid == characteristicUUID {
                    debugPrint("DATA \(String(describing: data?.hexa()))")
                    IOPLog().iopLogSwiftFunction(message: "DATA \(String(describing: data?.hexa()))")
                    if data?.hexa() == exceptedValue {
                        weakTestCase.publishTestResult(passed: true)
                    } else {
                        weakTestCase.publishTestResult(passed: false, description: "Wrong value in a characteristic.")
                    }
                    return
                }
                
                weakTestCase.publishTestResult(passed: false, description: "Failure during read from a characteristic.")
                
            case .unknown:
                break
                
            default:
                weakTestCase.publishTestResult(passed: false, description: "Unknown failure from peripheral delegate.")

            }
        })
        
        return peripheralDelegateSubscription
    }
    
    func getWRLenTestSubscription(for characteristicUUID: CBUUID,
                                  valueToWrite: String,
                                  count: Int,
                                  peripheralDelegate: SILPeripheralDelegate,
                                  testCase: SILTestCase) -> SILObservableToken {
        weak var weakTestCase = testCase
        let peripheralDelegateSubscription = peripheralDelegate.newStatus().observe( { status in
            guard let weakTestCase = weakTestCase else { return }
            switch status {
            case let .successForCharacteristics(characteristics):
                guard let iopTestPropertiesWRLen = peripheralDelegate.findCharacteristic(with: characteristicUUID, in: characteristics) else {
                    weakTestCase.publishTestResult(passed: false, description: "Characteristic WR Len wasn't discovered.")
                    return
                }
                
                guard iopTestPropertiesWRLen.properties.contains(.write) else {
                    weakTestCase.publishTestResult(passed: false, description: "Characteristic WR Len doesn't have write property.")
                    return
                }
                
                guard let dataToWrite = valueToWrite.data(withCount: count) else {
                    weakTestCase.publishTestResult(passed: false, description: "Invalid value to write.")
                    return
                }
                
                peripheralDelegate.writeToCharacteristic(data: dataToWrite, characteristic: iopTestPropertiesWRLen, writeType: .withResponse)
  
            case let .successWrite(characteristic):
                if characteristic.uuid == characteristicUUID {
                    debugPrint("DATA \(String(describing: characteristic.value?.hexa()))")
                    IOPLog().iopLogSwiftFunction(message: "DATA \(String(describing: characteristic.value?.hexa()))")
                    weakTestCase.publishTestResult(passed: true)
                    return
                }
                
                weakTestCase.publishTestResult(passed: false, description: "Failure during write to characteristic.")
          
            case .unknown:
                break
                
            default:
                weakTestCase.publishTestResult(passed: false, description: "Unknown failure from peripheral delegate.")
            }
        })
        
        return peripheralDelegateSubscription
    }
    
    func getWRNoResLenTestSubscription(for characteristicUUID: CBUUID,
                                       valueToWrite: String,
                                       count: Int,
                                       exceptedValue: String,
                                       peripheralDelegate: SILPeripheralDelegate,
                                       testCase: SILTestCase) -> SILObservableToken {
        weak var weakTestCase = testCase
        let peripheralDelegateSubscription = peripheralDelegate.newStatus().observe( { status in
            guard let weakTestCase = weakTestCase else { return }
            switch status {
            case let .successForCharacteristics(characteristics):
                guard let iopTestPropertiesWRNoResLen = peripheralDelegate.findCharacteristic(with: characteristicUUID, in: characteristics) else {
                    weakTestCase.publishTestResult(passed: false, description: "Characteristic WRNoRes Len wasn't discovered.")
                    return
                }
                
                guard iopTestPropertiesWRNoResLen.properties.contains(.writeWithoutResponse) else {
                    weakTestCase.publishTestResult(passed: false, description: "Characteristic WRNoRes Len doesn't have write without response property.")
                    return
                }
                
                guard let dataToWrite = valueToWrite.data(withCount: count) else {
                    weakTestCase.publishTestResult(passed: false, description: "Invalid value to write.")
                    return
                }

                peripheralDelegate.writeToCharacteristic(data: dataToWrite, characteristic: iopTestPropertiesWRNoResLen, writeType: .withoutResponse)
                peripheralDelegate.readCharacteristic(characteristic: iopTestPropertiesWRNoResLen)
                
            case let .successGetValue(value: data, characteristic: characteristic):
                if characteristic.uuid == characteristicUUID {
                    debugPrint("DATA \(String(describing: data?.hexa()))")
                    IOPLog().iopLogSwiftFunction(message: "DATA \(String(describing: data?.hexa()))")
                    if data?.hexa() == exceptedValue {
                        weakTestCase.publishTestResult(passed: true)
                    } else {
                        weakTestCase.publishTestResult(passed: false, description: "Wrong value in a characteristic.")
                    }
                    return
                }
                
                weakTestCase.publishTestResult(passed: false, description: "Failure during read value from a characteristic.")
                
            case .unknown:
                break
                
            default:
                weakTestCase.publishTestResult(passed: false, description: "Unknown failure from peripheral delegate.")
            }
        })
        
        return peripheralDelegateSubscription
    }
    
    func getTypesRWLenTestSubscription(for characteristicUUID: CBUUID,
                                       valueToWrite: String,
                                       count: Int,
                                       exceptedValue: String,
                                       peripheralDelegate: SILPeripheralDelegate,
                                       testCase: SILTestCase) -> SILObservableToken {
        weak var weakTestCase = testCase
        let peripheralDelegateSubscription = peripheralDelegate.newStatus().observe( { status in
            guard let weakTestCase = weakTestCase else { return }
            switch status {
            case let .successForCharacteristics(characteristics):
                guard let iopTestCharacteristicTypesRWLen = peripheralDelegate.findCharacteristic(with: characteristicUUID, in: characteristics) else {
                    weakTestCase.publishTestResult(passed: false, description: "Characteristic Types RW Len wasn't discovered.")
                    return
                }
                
                guard let dataToWrite = exceptedValue.data(withCount: count) else {
                    weakTestCase.publishTestResult(passed: false, description: "Invalid data to write.")
                    return
                }
              
                peripheralDelegate.writeToCharacteristic(data: dataToWrite, characteristic: iopTestCharacteristicTypesRWLen, writeType: .withResponse)
             
            case let .successWrite(characteristic: characteristic):
                if characteristic.uuid == characteristicUUID {
                    debugPrint("DATA \(String(describing: characteristic.value?.hexa()))")
                    IOPLog().iopLogSwiftFunction(message: "DATA \(String(describing: characteristic.value?.hexa()))")
                    peripheralDelegate.readCharacteristic(characteristic: characteristic)
                    return
                }
                
                weakTestCase.publishTestResult(passed: false, description: "Characteristic not found.")
                
            case let .successGetValue(value: data, characteristic: characteristic):
                if characteristic.uuid == characteristicUUID {
                    debugPrint("DATA \(String(describing: data?.hexa()))")
                    IOPLog().iopLogSwiftFunction(message: "DATA \(String(describing: data?.hexa()))")
                    if data?.hexa() == exceptedValue {
                        weakTestCase.publishTestResult(passed: true)
                    } else {
                        weakTestCase.publishTestResult(passed: false, description: "Wrong value in a characteristic.")
                    }
                    return
                }
                
                weakTestCase.publishTestResult(passed: false, description: "Characteristic not found.")
                
            case .unknown:
                break
                
            default:
                weakTestCase.publishTestResult(passed: false, description: "Unknown failure from peripheral delegate.")
            }
        })
        
        return peripheralDelegateSubscription
    }
}
