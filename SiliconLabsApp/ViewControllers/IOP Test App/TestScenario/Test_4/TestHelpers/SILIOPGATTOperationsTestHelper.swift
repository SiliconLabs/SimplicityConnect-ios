//
//  SILIOPGATTOperationsTestHelper.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 26.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILIOPGATTOperationsTestHelper {
    private let log = IOPLog()
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
                self.log.connection(source: "SILIOPGATTOperationsTestHelper",
                                    testID: weakTestCase.testID,
                                    action: "GATT operation disconnected unexpectedly",
                                    error: error)
                weakTestCase.publishTestResult(passed: false, description: "Peripheral was disconnected with \(String(describing: error?.localizedDescription)).")
            
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    self.log.step(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, action: "GATT operation interrupted", detail: "Bluetooth was disabled.")
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
                    self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Resolve read-only characteristic", uuid: characteristicUUID, outcome: "Characteristic not discovered")
                    weakTestCase.publishTestResult(passed: false, description: "Characteristic RO Len wasn't discovered.")
                    return
                }
                
                guard iopTestPropertiesROLen.properties.contains(.read) else {
                    self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Validate read property", uuid: characteristicUUID, outcome: "Characteristic does not support read")
                    weakTestCase.publishTestResult(passed: false, description: "Characteristic RO Len doesn't have read property.")
                    return
                }
                
                self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Read characteristic", uuid: characteristicUUID, expected: exceptedValue, outcome: "Reading characteristic value")
                peripheralDelegate.readCharacteristic(characteristic: iopTestPropertiesROLen)
                
            case let .successGetValue(value: data, characteristic: characteristic):
                if characteristic.uuid == characteristicUUID {
                    if data?.hexa() == exceptedValue {
                        self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Read characteristic", uuid: characteristicUUID, expected: exceptedValue, actual: data?.hexa(), outcome: "Read value matched expected payload")
                        weakTestCase.publishTestResult(passed: true, description: "Read \(data?.hexa() ?? "nil") from \(characteristicUUID.uuidString), matching expected value \(exceptedValue).")
                    } else {
                        self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Read characteristic", uuid: characteristicUUID, expected: exceptedValue, actual: data?.hexa(), outcome: "Read value did not match expected payload")
                        weakTestCase.publishTestResult(passed: false, description: "Wrong value in a characteristic.")
                    }
                    return
                }
                
                self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Read characteristic", uuid: characteristic.uuid, outcome: "Unexpected characteristic returned a value")
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
                    self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Resolve write characteristic", uuid: characteristicUUID, outcome: "Characteristic not discovered")
                    weakTestCase.publishTestResult(passed: false, description: "Characteristic WR Len wasn't discovered.")
                    return
                }
                
                guard iopTestPropertiesWRLen.properties.contains(.write) else {
                    self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Validate write property", uuid: characteristicUUID, outcome: "Characteristic does not support write")
                    weakTestCase.publishTestResult(passed: false, description: "Characteristic WR Len doesn't have write property.")
                    return
                }
                
                guard let dataToWrite = valueToWrite.data(withCount: count) else {
                    self.log.step(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, action: "Prepare write payload", detail: "Invalid value '\(valueToWrite)' for count \(count).")
                    weakTestCase.publishTestResult(passed: false, description: "Invalid value to write.")
                    return
                }
                
                self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Write characteristic", uuid: characteristicUUID, writeType: .withResponse, value: dataToWrite.hexa(), outcome: "Writing payload to characteristic")
                peripheralDelegate.writeToCharacteristic(data: dataToWrite, characteristic: iopTestPropertiesWRLen, writeType: .withResponse)
  
            case let .successWrite(characteristic):
                if characteristic.uuid == characteristicUUID {
                    self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Write characteristic", uuid: characteristicUUID, outcome: "Write with response completed successfully")
                    weakTestCase.publishTestResult(passed: true, description: "Write with response completed successfully on \(characteristicUUID.uuidString).")
                    return
                }
                
                self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Write characteristic", uuid: characteristic.uuid, outcome: "Unexpected characteristic acknowledged the write")
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
                    self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Resolve write-without-response characteristic", uuid: characteristicUUID, outcome: "Characteristic not discovered")
                    weakTestCase.publishTestResult(passed: false, description: "Characteristic WRNoRes Len wasn't discovered.")
                    return
                }
                
                guard iopTestPropertiesWRNoResLen.properties.contains(.writeWithoutResponse) else {
                    self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Validate write-without-response property", uuid: characteristicUUID, outcome: "Characteristic does not support write without response")
                    weakTestCase.publishTestResult(passed: false, description: "Characteristic WRNoRes Len doesn't have write without response property.")
                    return
                }
                
                guard let dataToWrite = valueToWrite.data(withCount: count) else {
                    self.log.step(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, action: "Prepare write-without-response payload", detail: "Invalid value '\(valueToWrite)' for count \(count).")
                    weakTestCase.publishTestResult(passed: false, description: "Invalid value to write.")
                    return
                }

                self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Write characteristic", uuid: characteristicUUID, writeType: .withoutResponse, value: dataToWrite.hexa(), outcome: "Writing payload without response and reading back for verification")
                peripheralDelegate.writeToCharacteristic(data: dataToWrite, characteristic: iopTestPropertiesWRNoResLen, writeType: .withoutResponse)
                peripheralDelegate.readCharacteristic(characteristic: iopTestPropertiesWRNoResLen)
                
            case let .successGetValue(value: data, characteristic: characteristic):
                if characteristic.uuid == characteristicUUID {
                    if data?.hexa() == exceptedValue {
                        self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Read back write-without-response characteristic", uuid: characteristicUUID, expected: exceptedValue, actual: data?.hexa(), outcome: "Readback matched expected payload")
                        weakTestCase.publishTestResult(passed: true, description: "Read back \(data?.hexa() ?? "nil") from \(characteristicUUID.uuidString) after write without response, matching expected value \(exceptedValue).")
                    } else {
                        self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Read back write-without-response characteristic", uuid: characteristicUUID, expected: exceptedValue, actual: data?.hexa(), outcome: "Readback did not match expected payload")
                        weakTestCase.publishTestResult(passed: false, description: "Wrong value in a characteristic.")
                    }
                    return
                }
                
                self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Read back write-without-response characteristic", uuid: characteristic.uuid, outcome: "Unexpected characteristic returned a value")
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
                    self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Resolve characteristic types RW characteristic", uuid: characteristicUUID, outcome: "Characteristic not discovered")
                    weakTestCase.publishTestResult(passed: false, description: "Characteristic Types RW Len wasn't discovered.")
                    return
                }
                
                guard let dataToWrite = exceptedValue.data(withCount: count) else {
                    self.log.step(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, action: "Prepare RW characteristic payload", detail: "Invalid expected value '\(exceptedValue)' for count \(count).")
                    weakTestCase.publishTestResult(passed: false, description: "Invalid data to write.")
                    return
                }
              
                self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Write characteristic types RW value", uuid: characteristicUUID, writeType: .withResponse, value: dataToWrite.hexa(), outcome: "Writing payload before readback verification")
                peripheralDelegate.writeToCharacteristic(data: dataToWrite, characteristic: iopTestCharacteristicTypesRWLen, writeType: .withResponse)
             
            case let .successWrite(characteristic: characteristic):
                if characteristic.uuid == characteristicUUID {
                    self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Write characteristic types RW value", uuid: characteristicUUID, outcome: "Write acknowledged, reading back value")
                    peripheralDelegate.readCharacteristic(characteristic: characteristic)
                    return
                }
                
                self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Write characteristic types RW value", uuid: characteristic.uuid, outcome: "Unexpected characteristic acknowledged the write")
                weakTestCase.publishTestResult(passed: false, description: "Characteristic not found.")
                
            case let .successGetValue(value: data, characteristic: characteristic):
                if characteristic.uuid == characteristicUUID {
                    if data?.hexa() == exceptedValue {
                        self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Read characteristic types RW value", uuid: characteristicUUID, expected: exceptedValue, actual: data?.hexa(), outcome: "Readback matched expected payload")
                        weakTestCase.publishTestResult(passed: true, description: "Read back \(data?.hexa() ?? "nil") from \(characteristicUUID.uuidString), matching expected value \(exceptedValue).")
                    } else {
                        self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Read characteristic types RW value", uuid: characteristicUUID, expected: exceptedValue, actual: data?.hexa(), outcome: "Readback did not match expected payload")
                        weakTestCase.publishTestResult(passed: false, description: "Wrong value in a characteristic.")
                    }
                    return
                }
                
                self.log.gatt(source: "SILIOPGATTOperationsTestHelper", testID: weakTestCase.testID, operation: "Read characteristic types RW value", uuid: characteristic.uuid, outcome: "Unexpected characteristic returned a value")
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
