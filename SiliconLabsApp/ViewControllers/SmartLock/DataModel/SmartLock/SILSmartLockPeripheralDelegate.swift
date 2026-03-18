//
//  SILSmartLockPeripheralDelegate.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 26/06/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import UIKit
import CoreBluetooth

enum SILSmartLockPeripheralDelegateState {
    case initiated
    case failure(reason: String)
    case unknown
}

enum SILSmartLockConnectionOption: String {
    case ble
    case wifi
    case cancel
}

enum SILSmartLockCharacteristicState: Equatable {
    case unknown
    case updateValue(data: Data)
}

class SILSmartLockPeripheralDelegate: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate {
    
    var smartLockState: SILObservable<SILSmartLockPeripheralDelegateState> = SILObservable(initialValue: .unknown)
    var smartLockStateCharacteristicState: SILObservable<SILSmartLockCharacteristicState> = SILObservable(initialValue: .unknown)
    
    var smartLockfirmwareVersion: String = "N/A"
    private var smartLockPowerSource: PowerSource = .unknown
    
    private var smartLockPeripheral: CBPeripheral
    private var smartLockCharacteristic: CBCharacteristic?
    private var smartLockStateCharacteristic: CBCharacteristic?
    
    private var isDevkit: Bool = false
    
    private var smartLockServiceUUID: CBUUID!
    private var smartLockCharUUID: CBUUID!
    private var smartLockStateUUID: CBUUID!

    private var stateReadQuery: Data!
    private var unlock: Data!
    private var lock: Data!
        
    private var smartLockProperties: CBCharacteristicProperties?
    private var smartLockStateProperties: CBCharacteristicProperties?
    var centeralManager: CBCentralManager!
    
    // In your class initializer:
    init(peripheral: CBPeripheral, name: String) {
        self.smartLockPeripheral = peripheral
        super.init()
        
        if !isDeviceConnected() {
            self.centeralManager = CBCentralManager(delegate: self, queue: nil)
            //self.connectDevice()
        }else{
            self.smartLockPeripheral.delegate = self
        }
        initDevice(name: name)
    }
    
    private func initDevice(name: String) {
        
        self.smartLockServiceUUID = SILSmartLockPeripheralGATTDatabase.SmartLockService.cbUUID
        self.smartLockCharUUID = SILSmartLockPeripheralGATTDatabase.SmartLockService.SmartLockCharacteristic.cbUUID
        self.smartLockStateUUID = SILSmartLockPeripheralGATTDatabase.SmartLockService.SmartLockStateCharacteristic.cbUUID
        
        self.stateReadQuery = SILSmartLockPeripheralGATTDatabase.SmartLockService.SmartLockStateCharacteristic.WriteValues.stateReadQuery
        self.unlock = SILSmartLockPeripheralGATTDatabase.SmartLockService.SmartLockCharacteristic.WriteValues.unlock
        self.lock = SILSmartLockPeripheralGATTDatabase.SmartLockService.SmartLockCharacteristic.WriteValues.lock
        
        self.smartLockProperties = nil
        self.smartLockStateProperties = nil
        
        print("self.smartLockPeripheral \(self.smartLockPeripheral)")
    }
    func isDeviceConnected() -> Bool {
        if self.smartLockPeripheral.state != .connected {
            return false
        }else {
            return true
        }
    }
    func connectDevice() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            if self.smartLockPeripheral.state != .connected {
                print("Not Connected")
                self.centeralManager.connect(self.smartLockPeripheral)
//            } else {
             //   print("Already Connected")
                //self.discoverSmartLockService()
            //}
        }
    }
    
    func newState() -> SILObservable<SILSmartLockPeripheralDelegateState> {
        smartLockState = SILObservable(initialValue: .unknown)
       
        return smartLockState
    }
    
    
    func newLockStateCharacteristicState() -> SILObservable<SILSmartLockCharacteristicState> {
        smartLockStateCharacteristicState = SILObservable(initialValue: .unknown)
        
        return smartLockStateCharacteristicState;
    }
    
    // MARK: - Setup environment
    
    func discoverSmartLockService() {
        debugPrint("Discover Smart Lock service")
        self.smartLockPeripheral.discoverServices(nil)
    }
    
    // MARK: - access to Smart Lock characteristics
    public func writeReadQueryValueToSmartLockCharacteristic () {
        
        guard smartLockPeripheral.state == .connected else {
            smartLockState.value = .failure(reason: "Bluetooth is not connected")
            return
        }
           
        guard let smartLockCharacteristic = self.smartLockCharacteristic else {
            return
        }
        smartLockPeripheral.writeValue(self.stateReadQuery, for: smartLockCharacteristic, type: .withResponse)
    }
    
    public func writeOnValueToSmartLockCharacteristic() {
        
        guard smartLockPeripheral.state == .connected else {
            smartLockState.value = .failure(reason: "Bluetooth is not connected")
            return
        }
        
        guard let smartLockCharacteristic = self.smartLockCharacteristic else {
            return
        }
        print(self.unlock)
        smartLockPeripheral.writeValue(self.unlock, for: smartLockCharacteristic, type: .withResponse)
    }
    
    public func writeOffValueToSmartLockCharacteristic() {
        guard let smartLockCharacteristic = self.smartLockCharacteristic else {
            return
        }
        print(self.lock)
        smartLockPeripheral.writeValue(self.lock, for: smartLockCharacteristic, type: .withResponse)
    }
    
    // MARK: - Bluetooth delegate's methods
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral)")
        self.discoverSmartLockService()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            debugPrint("Bluetooth is ON")
            self.connectDevice()
        } else {
            debugPrint("Bluetooth is OFF")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil {
            // Write succeeded, now read the characteristic value
           // peripheral.readValue(for: characteristic)
        } else {
            // Handle error
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        debugPrint("Smart Lock peripheral(:didDiscoverServices:error)")
        
        guard error == nil else {
            smartLockState.value = .failure(reason: "Failure discovering Smart Lock service: \(String(describing: error?.localizedDescription))")
            return
        }
        
        let smartLockService: CBService? = peripheral.services?.first(where: {service in service.uuid == self.smartLockServiceUUID})
        
        guard let _ = smartLockService else {
            smartLockState.value = .failure(reason: "No Smart Lock service discovered")
            return
        }
        
        peripheral.services?.forEach({
            peripheral.discoverCharacteristics(nil, for: $0)
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        debugPrint("Smart Lock peripheral(:didDiscoverCharacteristicsFor:service:error)")
        
        if service.uuid == self.smartLockServiceUUID {
            guard error == nil else {
                smartLockState.value = .failure(reason: "Failure discovering Smart Lock service characteristics: \(String(describing: error?.localizedDescription))")
                return
            }
            
            guard let smartLockCharacteristic = findCharacteristic(characteristics: service.characteristics,
                                                               withUUID: self.smartLockCharUUID, withProperties: self.smartLockProperties)
            else {
                smartLockState.value = .failure(reason: "Smart Lock characteristic not discovered")
                return
            }
            self.smartLockCharacteristic = smartLockCharacteristic
            
            // Read State Characteristic
            guard let reportStateCharacteristic = findCharacteristic(characteristics: service.characteristics,
                                                                      withUUID: self.smartLockStateUUID, withProperties: self.smartLockStateProperties)
            else {
                smartLockState.value = .failure(reason: "Blinky report button characteristic not discovered")
                return
            }
            self.smartLockStateCharacteristic = reportStateCharacteristic
            readCharacteristicsInitialValues()
            subscribeToLock()
            writeReadQueryValueToSmartLockCharacteristic()
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        debugPrint("Smart Lock peripheral(:didUpdateValueFor:characteristic:error)")
        
        if (checkIsSmartLockStateCharacteristic(characteristic))  {
            debugPrint("Notification from report button characteristic")
            
            guard error == nil else {
                smartLockState.value = .failure(reason: "Failure on receiving notification from report button characteristic: \(String(describing: error?.localizedDescription))")
                return
            }
            
            guard let value = characteristic.value else {
                smartLockState.value = .failure(reason: "Missing report button characteristic value")
                return
            }
            
            self.smartLockStateCharacteristicState.value = .updateValue(data: value)
            updateStateIfIsInitiated()
            return
        }
    }
    
    private func checkIsSmartLockCharacteristic(_ characteristic: CBCharacteristic) -> Bool {
        if let properties = self.smartLockProperties {
            return characteristic.uuid == self.smartLockCharacteristic?.uuid && characteristic.properties.rawValue == properties.rawValue
        }
        return characteristic.uuid == self.smartLockCharacteristic?.uuid
    }
    
    private func checkIsSmartLockStateCharacteristic(_ characteristic: CBCharacteristic) -> Bool {
        if let properties = self.smartLockStateProperties {
            return characteristic.uuid == self.smartLockStateCharacteristic?.uuid && characteristic.properties.rawValue == properties.rawValue
        }
        return characteristic.uuid == self.smartLockStateCharacteristic?.uuid
    }
    
    private func checkIsInitiated() -> Bool {
        var result = true
        //return result && smartLockCharacteristicState.value != .unknown && smartLockStateCharacteristicState.value != .unknown
        return result && smartLockStateCharacteristicState.value != .unknown
    }
    
    private func updateStateIfIsInitiated() {
        if checkIsInitiated() {
            self.smartLockState.value = .initiated
        }
    }
    
    //MARK: - Helper methods
    func findCharacteristic(characteristics: [CBCharacteristic]?, withUUID uuid: CBUUID, withProperties properties: CBCharacteristicProperties?) -> CBCharacteristic? {
        if let properties = properties {
            return characteristics?.first(where: {characteristic in
                characteristic.uuid == uuid && characteristic.properties.rawValue == properties.rawValue
            })
        } else {
            return characteristics?.first(where: {characteristic in
                characteristic.uuid == uuid
            })
        }
    }
        
    private func readCharacteristicsInitialValues() {
        self.smartLockPeripheral.readValue(for: self.smartLockStateCharacteristic!)
    }
    
    private func subscribeToLock() {
        self.smartLockPeripheral.setNotifyValue(true, for: smartLockStateCharacteristic!)
    }
}
