//
//  SILBlinkyPeripheralDelegate.swift
//  BlueGecko
//
//  Created by Vasyl Haievyi on 08/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

struct SILBlinkyPeripheralGATTDatabase {
    struct BlinkyService {
        static let uuid = "de8a5aac-a99b-c315-0c80-60d4cbb51224"
        static let cbUUID = CBUUID(string: uuid)
        
        struct LightCharacteristic {
            static let uuid = "5b026510-4088-c297-46d8-be6c736a087a"
            static let cbUUID = CBUUID(string: uuid)
            
            struct WriteValues {
                static let TurnOff = Data(bytes: [0x00], count: 1)
                static let TurnOn = Data(bytes: [0x01], count: 1)
            }
        }
        
        struct ReportButtonCharacteristic {
            static let uuid = "61a885a4-41c3-60d0-9a53-6d652a70d29c"
            static let cbUUID = CBUUID(string: uuid)
            
            struct ReadValues {
                static let Released = Data(bytes: [0x00], count: 1)
                static let Pressed = Data(bytes: [0x01], count: 1)
            }
        }
    }
}

enum SILBlinkyPeripheralDelegateState {
    case initiated
    case failure(reason: String)
    case unknown
}

enum SILBlinkyCharacteristicState {
    case unknown
    case updateValue(data: Data)
}

class SILBlinkyPeripheralDelegate: NSObject, CBPeripheralDelegate {
    var state: SILObservable<SILBlinkyPeripheralDelegateState> = SILObservable(initialValue: .unknown)
    var lightCharacteristicState: SILObservable<SILBlinkyCharacteristicState> = SILObservable(initialValue: .unknown)
    var reportButtonCharacteristicState: SILObservable<SILBlinkyCharacteristicState> = SILObservable(initialValue: .unknown)
    
    private var peripheral: CBPeripheral
    private var lightCharacteristic: CBCharacteristic?
    private var reportButtonCharacteristic: CBCharacteristic?
    
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
        self.peripheral.delegate = self
    }
    
    func newState() -> SILObservable<SILBlinkyPeripheralDelegateState> {
        state = SILObservable(initialValue: .unknown)
       
        return state
    }
    
    func newLightCharacteristicState() -> SILObservable<SILBlinkyCharacteristicState> {
        lightCharacteristicState = SILObservable(initialValue: .unknown)
        
        return lightCharacteristicState
    }
    
    func newReportButtonCharacteristicState() -> SILObservable<SILBlinkyCharacteristicState> {
        reportButtonCharacteristicState = SILObservable(initialValue: .unknown)
        
        return reportButtonCharacteristicState;
    }
    
    // MARK: - Setup environment
    
    func discoverBlinkyService() {
        debugPrint("Discover Light service")
        
        self.peripheral.discoverServices([SILBlinkyPeripheralGATTDatabase.BlinkyService.cbUUID])
    }
    
    func deviceDidDisconnect() {
        self.peripheral.setNotifyValue(false, for: reportButtonCharacteristic!)
    }
    
    // MARK: - access to Light characteristics
    public func writeOnValueToLightCharacteristic() {
        let onValue = SILBlinkyPeripheralGATTDatabase.BlinkyService.LightCharacteristic.WriteValues.TurnOn
        peripheral.writeValue(onValue, for: self.lightCharacteristic!, type: .withResponse)
    }
    
    public func writeOffValueToLightCharacteristic() {
        let offValue = SILBlinkyPeripheralGATTDatabase.BlinkyService.LightCharacteristic.WriteValues.TurnOff
        peripheral.writeValue(offValue, for: self.lightCharacteristic!, type: .withResponse)
    }
    
    // MARK: - Bluetooth delegate's methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        debugPrint("Blinky peripheral(:didDiscoverServices:error)")
        
        guard error == nil else {
            state.value = .failure(reason: "Failure discovering blinky service: \(String(describing: error?.localizedDescription))")
            return
        }
        
        let blinkyService = peripheral.services?.first(where: {service in service.uuid == SILBlinkyPeripheralGATTDatabase.BlinkyService.cbUUID})
        
        guard let blinkyServiceUnwrapped = blinkyService else {
            state.value = .failure(reason: "No Blinky service discovered")
            return
        }
        
        peripheral.discoverCharacteristics([SILBlinkyPeripheralGATTDatabase.BlinkyService.LightCharacteristic.cbUUID,
                                            SILBlinkyPeripheralGATTDatabase.BlinkyService.ReportButtonCharacteristic.cbUUID], for: blinkyServiceUnwrapped)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        debugPrint("Blinky peripheral(:didDiscoverCharacteristicsFor:service:error)")
        
        guard error == nil else {
            state.value = .failure(reason: "Failure discovering Blinky service characteristics: \(String(describing: error?.localizedDescription))")
            return
        }
        
        guard let lightCharacteristic = findCharacteristic(characteristics: service.characteristics,
                                                           with: SILBlinkyPeripheralGATTDatabase.BlinkyService.LightCharacteristic.cbUUID)
        else {
            state.value = .failure(reason: "Blinky light characteristic not discovered")
            return
        }
        self.lightCharacteristic = lightCharacteristic
        
        guard let reportButtonCharacteristic = findCharacteristic(characteristics: service.characteristics,
                                                                  with: SILBlinkyPeripheralGATTDatabase.BlinkyService.ReportButtonCharacteristic.cbUUID)
        else {
            state.value = .failure(reason: "Blinky report button characteristic not discovered")
            return
        }
        self.reportButtonCharacteristic = reportButtonCharacteristic
        
        subscribeToReportButton()
        readCharacteristicsInitialValues()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        debugPrint("Blinky peripheral(:didUpdateValueFor:characteristic:error)")
        
        if (characteristic.uuid == SILBlinkyPeripheralGATTDatabase.BlinkyService.ReportButtonCharacteristic.cbUUID)  {
            debugPrint("Notification from report button characteristic")
            
            guard error == nil else {
                state.value = .failure(reason: "Failure on receiving notification from report button characteristic: \(String(describing: error?.localizedDescription))")
                return
            }
            
            guard let value = characteristic.value else {
                state.value = .failure(reason: "Missing report button characteristic value")
                return
            }
            
            self.reportButtonCharacteristicState.value = .updateValue(data: value)
        }
        
        if (characteristic.uuid == SILBlinkyPeripheralGATTDatabase.BlinkyService.LightCharacteristic.cbUUID) {
            debugPrint("Response from light characteristic for initial value request")
            
            switch self.state.value {
            case .unknown:
                guard error == nil else {
                    state.value = .failure(reason: "Failure on receiving response from light characteristic: \(String(describing: error?.localizedDescription))")
                    return
                }
                
                guard let value = characteristic.value else {
                    state.value = .failure(reason: "Missing light characteristic value")
                    return
                }
                
                self.lightCharacteristicState.value = .updateValue(data: value)
                self.state.value = .initiated
            default:
                break;
            }
        }
    }
    
    //MARK: - Helper methods
    func findCharacteristic(characteristics: [CBCharacteristic]?, with uuid: CBUUID) -> CBCharacteristic? {
        return characteristics?.first(where: {characteristic in
            characteristic.uuid == uuid
        })
    }
    
    func readCharacteristicsInitialValues() {
        self.peripheral.readValue(for: self.lightCharacteristic!)
        self.peripheral.readValue(for: self.reportButtonCharacteristic!)
    }
    
    private func subscribeToReportButton() {
        self.peripheral.setNotifyValue(true, for: reportButtonCharacteristic!)
    }
}
