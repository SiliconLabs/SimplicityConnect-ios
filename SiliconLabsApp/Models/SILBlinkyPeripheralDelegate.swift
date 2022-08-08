//
//  SILBlinkyPeripheralDelegate.swift
//  BlueGecko
//
//  Created by Vasyl Haievyi on 08/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

enum SILBlinkyPeripheralDelegateState {
    case initiated
    case failure(reason: String)
    case unknown
}

enum SILBlinkyCharacteristicState: Equatable {
    case unknown
    case updateValue(data: Data)
}

class SILBlinkyPeripheralDelegate: NSObject, CBPeripheralDelegate {
    var state: SILObservable<SILBlinkyPeripheralDelegateState> = SILObservable(initialValue: .unknown)
    var lightCharacteristicState: SILObservable<SILBlinkyCharacteristicState> = SILObservable(initialValue: .unknown)
    var reportButtonCharacteristicState: SILObservable<SILBlinkyCharacteristicState> = SILObservable(initialValue: .unknown)
    
    var powerSourceState: SILObservable<PowerSource?> = SILObservable(initialValue: nil)
    var firmwareVersion: String = "N/A"
    private var powerSource: PowerSource = .unknown
    
    private var peripheral: CBPeripheral
    private var lightCharacteristic: CBCharacteristic?
    private var reportButtonCharacteristic: CBCharacteristic?
    
    private var isThunderboard: Bool = false
    
    private var serviceUUID: CBUUID!
    private var lightUUID: CBUUID!
    private var reportUUID: CBUUID!
        
    private var turnOnData: Data!
    private var turnOffData: Data!
        
    private var lightProperties: CBCharacteristicProperties?
    private var reportProperties: CBCharacteristicProperties?

    init(peripheral: CBPeripheral, name: String) {
        self.peripheral = peripheral
        super.init()
        initDevice(name: name)
        self.peripheral.delegate = self
    }
    
    private func initDevice(name: String) {
        if (name.contains("Blinky") == true) {
            self.isThunderboard = false
            self.serviceUUID = SILBlinkyPeripheralGATTDatabase.BlinkyService.cbUUID
                
            self.lightUUID = SILBlinkyPeripheralGATTDatabase.BlinkyService.LightCharacteristic.cbUUID
            self.reportUUID = SILBlinkyPeripheralGATTDatabase.BlinkyService.ReportButtonCharacteristic.cbUUID
                
            self.turnOnData = SILBlinkyPeripheralGATTDatabase.BlinkyService.LightCharacteristic.WriteValues.TurnOn
            self.turnOffData = SILBlinkyPeripheralGATTDatabase.BlinkyService.LightCharacteristic.WriteValues.TurnOff
                
            self.lightProperties = nil
            self.reportProperties = nil
        } else if (name.contains("Thunder") == true) {
            self.isThunderboard = true
            
            self.serviceUUID = SILThunderboardPeripheralGATTDatabase.ThunderboardService.cbUUID
            self.lightUUID = SILThunderboardPeripheralGATTDatabase.ThunderboardService.LightCharacteristic.cbUUID
            self.reportUUID = SILThunderboardPeripheralGATTDatabase.ThunderboardService.ReportButtonCharacteristic.cbUUID
                
            self.turnOnData = SILThunderboardPeripheralGATTDatabase.ThunderboardService.LightCharacteristic.WriteValues.TurnOn
            self.turnOffData = SILThunderboardPeripheralGATTDatabase.ThunderboardService.LightCharacteristic.WriteValues.TurnOff
                
            self.lightProperties = SILThunderboardPeripheralGATTDatabase.ThunderboardService.LightCharacteristic.properties
            self.reportProperties = SILThunderboardPeripheralGATTDatabase.ThunderboardService.ReportButtonCharacteristic.properties
        }
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
        
        self.peripheral.discoverServices(nil)
    }
    
    // MARK: - access to Light characteristics
    
    public func writeOnValueToLightCharacteristic() {
        guard let lightCharacteristic = self.lightCharacteristic else {
            return
        }
        peripheral.writeValue(turnOnData, for: lightCharacteristic, type: .withResponse)
    }
    
    public func writeOffValueToLightCharacteristic() {
        guard let lightCharacteristic = self.lightCharacteristic else {
            return
        }
        peripheral.writeValue(turnOffData, for: lightCharacteristic, type: .withResponse)
    }
    
    // MARK: - Bluetooth delegate's methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        debugPrint("Blinky peripheral(:didDiscoverServices:error)")
        
        guard error == nil else {
            state.value = .failure(reason: "Failure discovering blinky service: \(String(describing: error?.localizedDescription))")
            return
        }
        
        let blinkyService: CBService? = peripheral.services?.first(where: {service in service.uuid == self.serviceUUID})
        
        guard let _ = blinkyService else {
            state.value = .failure(reason: "No Blinky service discovered")
            return
        }
        
        peripheral.services?.forEach({
            peripheral.discoverCharacteristics(nil, for: $0)
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        debugPrint("Blinky peripheral(:didDiscoverCharacteristicsFor:service:error)")
        
        if service.uuid == self.serviceUUID {
            guard error == nil else {
                state.value = .failure(reason: "Failure discovering Blinky service characteristics: \(String(describing: error?.localizedDescription))")
                return
            }
            
            guard let lightCharacteristic = findCharacteristic(characteristics: service.characteristics,
                                                               withUUID: self.lightUUID, withProperties: self.lightProperties)
            else {
                state.value = .failure(reason: "Blinky light characteristic not discovered")
                return
            }
            self.lightCharacteristic = lightCharacteristic
            
            guard let reportButtonCharacteristic = findCharacteristic(characteristics: service.characteristics,
                                                                      withUUID: self.reportUUID, withProperties: self.reportProperties)
            else {
                state.value = .failure(reason: "Blinky report button characteristic not discovered")
                return
            }
            self.reportButtonCharacteristic = reportButtonCharacteristic
            
            subscribeToReportButton()
            readCharacteristicsInitialValues()
        } else if isThunderboard {
            if service.uuid == SILThunderboardPeripheralGATTDatabase.BatteryService.cbUUID {
                guard let batteryCharacteristic = findCharacteristic(characteristics: service.characteristics,
                                                                     withUUID: SILThunderboardPeripheralGATTDatabase.BatteryService
                                                                        .BatteryLevelCharacteristic.cbUUID,
                                                                     withProperties: nil) else {
                    state.value = .failure(reason: "Battery Characteristic not discovered")
                    return
                }
                peripheral.setNotifyValue(true, for: batteryCharacteristic)
                
            } else if service.uuid == SILThunderboardPeripheralGATTDatabase.PowerSourceCustomService.cbUUID {
                guard let powerSourceCharacteristic = findCharacteristic(characteristics: service.characteristics,
                                                                         withUUID: SILThunderboardPeripheralGATTDatabase.PowerSourceCustomService
                                                                            .PowerSourceCustomCharacteristic.cbUUID,
                                                                         withProperties: nil) else {
                    state.value = .failure(reason: "Power Source Characteristic not discovered")
                    return
                }
                peripheral.readValue(for: powerSourceCharacteristic)
            } else if service.uuid == SILThunderboardPeripheralGATTDatabase.DeviceInformationService.cbUUID {
                guard let firmwareRevisionCharacteristic = findCharacteristic(characteristics: service.characteristics,
                                                                         withUUID: SILThunderboardPeripheralGATTDatabase.DeviceInformationService
                                                                         .FirmwareRevisionCharacteristic.cbUUID,
                                                                         withProperties: nil) else {
                    state.value = .failure(reason: "Firmware Revision not discovered")
                    return
                }
                peripheral.readValue(for: firmwareRevisionCharacteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        debugPrint("Blinky peripheral(:didUpdateValueFor:characteristic:error)")
        
        if (checkIsReportButtonCharacteristic(characteristic))  {
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
            updateStateIfIsInitiated()
            return
        }
        
        if (checkIsLightCharacteristic(characteristic)) {
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
                updateStateIfIsInitiated()
            default:
                break;
            }
            return
        }
        
        if (characteristic.uuid == SILThunderboardPeripheralGATTDatabase.DeviceInformationService.FirmwareRevisionCharacteristic.cbUUID) {
            debugPrint("Response from firmware revision characteristic for initial value request")
            
            guard error == nil else {
                state.value = .failure(reason: "Failure on receiving response from firmware revision characteristic: \(String(describing: error?.localizedDescription))")
                return
            }
            
            guard let firmwareVersion = characteristic.tb_stringValue() else {
                state.value = .failure(reason: "Missing firmware revision characteristic value")
                return
            }
            
            self.firmwareVersion = firmwareVersion
            updateStateIfIsInitiated()
            return
        }
        
        if (characteristic.uuid == SILThunderboardPeripheralGATTDatabase.PowerSourceCustomService.PowerSourceCustomCharacteristic.cbUUID) {
            debugPrint("Response from light characteristic for initial value request")
 
            guard error == nil else {
                state.value = .failure(reason: "Failure on receiving response from power source characteristic: \(String(describing: error?.localizedDescription))")
                return
            }
            
            guard let value = characteristic.tb_int8Value() else {
                state.value = .failure(reason: "Missing power source characteristic value")
                return
            }
            updatePowerSource(with: value)
            updateStateIfIsInitiated()
            return
        }
        
        if (characteristic.uuid == SILThunderboardPeripheralGATTDatabase.BatteryService.BatteryLevelCharacteristic.cbUUID) {
            debugPrint("Response from battery level characteristic for initial value request")

            guard error == nil else {
                state.value = .failure(reason: "Failure on receiving response from battery level characteristic: \(String(describing: error?.localizedDescription))")
                return
            }
            
            guard let value = characteristic.tb_int8Value() else {
                state.value = .failure(reason: "Missing battery level characteristic value")
                return
            }
            
            self.updatePower(batteryLevel: Int(value))
            updateStateIfIsInitiated()
        }
    }
    
    private func checkIsLightCharacteristic(_ characteristic: CBCharacteristic) -> Bool {
        if let properties = self.lightProperties {
            return characteristic.uuid == self.lightCharacteristic?.uuid && characteristic.properties.rawValue == properties.rawValue
        }
        return characteristic.uuid == self.lightCharacteristic?.uuid
    }
    
    private func checkIsReportButtonCharacteristic(_ characteristic: CBCharacteristic) -> Bool {
        if let properties = self.reportProperties {
            return characteristic.uuid == self.reportButtonCharacteristic?.uuid && characteristic.properties.rawValue == properties.rawValue
        }
        return characteristic.uuid == self.reportButtonCharacteristic?.uuid
    }
    
    private func checkIsInitiated() -> Bool {
        var result = true
        if isThunderboard {
            result = result && self.powerSourceState.value != nil
        }

        return result && lightCharacteristicState.value != .unknown && reportButtonCharacteristicState.value != .unknown
    }
    
    private func updateStateIfIsInitiated() {
        if checkIsInitiated() {
            self.state.value = .initiated
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
    
    private func updatePowerSource(with characteristicValue: Int8) {
        var knownPowerSource: PowerSource = .unknown
        switch characteristicValue {
        case 1:
            knownPowerSource = .usb
        case 2, 3:
            knownPowerSource = .aa(0)
        case 4:
            knownPowerSource = .coinCell(0)
        default:
            break
        }
        self.powerSource = knownPowerSource
        self.powerSourceState.value = knownPowerSource
    }
    
    private func updatePower(batteryLevel: Int) {
        switch powerSource {
        case .unknown:
            break
        case .usb:
            self.powerSourceState.value = .usb
        case .genericBattery:
            self.powerSourceState.value = .genericBattery(batteryLevel)
        case .aa:
            self.powerSourceState.value = .aa(batteryLevel)
        case .coinCell:
            self.powerSourceState.value = .coinCell(batteryLevel)
        }
    }
    
    private func readCharacteristicsInitialValues() {
        self.peripheral.readValue(for: self.lightCharacteristic!)
        self.peripheral.readValue(for: self.reportButtonCharacteristic!)
    }
    
    private func subscribeToReportButton() {
        self.peripheral.setNotifyValue(true, for: reportButtonCharacteristic!)
    }
}
