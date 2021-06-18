//
//  SILThroughputPeripheralDelegate.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 26.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

enum SILThroughputPeripheralDelegateState {
    case initiated
    case updateValue(data: Data, for: CBCharacteristic)
    case failure(reason: String)
    case unknown
}

protocol SILThroughputPeripheralDelegateType: class {
    var state: SILObservable<SILThroughputPeripheralDelegateState> { get }
    var throughputResult: SILObservable<SILThroughputResult> { get }
    var currentTestDirection: SILObservable<SILThroughputTestDirection> { get }
    
    func discoverThroughputGATTServices()
    func subscribeGATT()
    func readConnectionParameters()
    func stopTesting()
    func getMTU(for writeType: CBCharacteristicWriteType) -> Int
    func phoneToEFRStatusChanged(isTesting: Bool)
}

class SILThroughputPeripheralDelegate : NSObject, SILThroughputPeripheralDelegateType, CBPeripheralDelegate {
    var state: SILObservable<SILThroughputPeripheralDelegateState> = SILObservable(initialValue: .unknown)
    var throughputResult: SILObservable<SILThroughputResult> = SILObservable(initialValue: SILThroughputResult(sender: .none, testType: .none, valueInBits: 0))
    var currentTestDirection: SILObservable<SILThroughputTestDirection> = SILObservable(initialValue: .none)
    
    private var throughputCountInBits = 0
    private var currentTestType = SILThroughputTestType.none
    private var throughputReleaseTimer: Timer?
    
    private var peripheral: CBPeripheral
    private var throughputPeripheralReferences: SILThroughputPeripheralGATTReferences
    
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.throughputPeripheralReferences = SILThroughputPeripheralGATTReferences()
        super.init()
        self.peripheral.delegate = self
    }
    
    func newState() -> SILObservable<SILThroughputPeripheralDelegateState> {
        state = SILObservable(initialValue: .unknown)
        return state
    }
    
    // MARK: - Setup environment
    
    func discoverThroughputGATTServices() {
        debugPrint("Discover Throughput GATT")
        peripheral.discoverServices([SILThroughputPeripheralGATTDatabase.ThroughputService.cbUUID,
                                     SILThroughputPeripheralGATTDatabase.ThroughputInformationService.cbUUID])
    }
    
    func subscribeGATT() {
        debugPrint("Subscribe Throughput GATT")
        for service in peripheral.services! {
            for characteristic in service.characteristics! {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        
        _ = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { timer in
            timer.invalidate()
            guard let throughputService = self.throughputPeripheralReferences.throughputService else {
                self.state.value = .failure(reason: "Throughput Service didn't find.")
                return
            }
            
            guard let characteristics = throughputService.characteristics, characteristics.count == 4 else {
                self.state.value = .failure(reason: "Throughput Service's characteristics didn't find.")
                return
            }
            
            for characteristic in characteristics {
                if !characteristic.isNotifying {
                    self.state.value = .failure(reason: "At least one of Throughput Service's characteristic isn't notifying.")
                    return
                }
            }
            
            self.state.value = .initiated
        })
    }
    
    func readConnectionParameters() {
        for characteristic in throughputPeripheralReferences.throughputInformationService!.characteristics ?? [] {
            peripheral.readValue(for: characteristic)
        }
    }
        
    func stopTesting() {
        throughputReleaseTimer?.invalidate()
        throughputReleaseTimer = nil
    }
    
    func getMTU(for writeType: CBCharacteristicWriteType) -> Int {
        return peripheral.maximumWriteValueLength(for: writeType)
    }
    
    func phoneToEFRStatusChanged(isTesting: Bool) {
        debugPrint("UPDATE PHONE TO EFR TEST STATUS \(isTesting)")
        
        if isTesting {
            currentTestDirection.value = .phoneToEFR
        } else {
            currentTestDirection.value = .none
        }
    }
    
    // MARK: - Bluetooth delegate's methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            state.value = .failure(reason: "Discovering Throughput Service with error \(String(describing: error?.localizedDescription))")
            return
        }
        
        let throughputService = peripheral.services?.first(where: { service in service.uuid == SILThroughputPeripheralGATTDatabase.ThroughputService.cbUUID })
        
        guard throughputService != nil else {
            state.value = .failure(reason: "Did not found Throughput Service.")
            return
        }
        
        throughputPeripheralReferences.throughputService = throughputService
        
        let throughputInformationService = peripheral.services?.first(where: { service in service.uuid == SILThroughputPeripheralGATTDatabase.ThroughputInformationService.cbUUID })
        
        guard throughputInformationService != nil else {
            state.value = .failure(reason: "Did not found Throughput Information Service.")
            return
        }
        
        throughputPeripheralReferences.throughputInformationService = throughputInformationService
        
        peripheral.discoverCharacteristics([SILThroughputPeripheralGATTDatabase.ThroughputService.ThroughputIndications.cbUUID,
                                            SILThroughputPeripheralGATTDatabase.ThroughputService.ThroughputNotifications.cbUUID,
                                            SILThroughputPeripheralGATTDatabase.ThroughputService.TransmissionOn.cbUUID,
                                            SILThroughputPeripheralGATTDatabase.ThroughputService.ThroughputResult.cbUUID], for: throughputPeripheralReferences.throughputService!)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            state.value = .failure(reason: "Discovering Throughput Service characteristics with error \(String(describing: error?.localizedDescription))")
            return
        }
        
        let characteritics = service.characteristics
        
        guard characteritics != nil else {
            state.value = .failure(reason: "Did not found any Throughput Service characteristic.")
            return
        }
        
        if service.uuid == SILThroughputPeripheralGATTDatabase.ThroughputService.cbUUID {
            guard let indicationsCharacteristic =   findCharacteristic(SILThroughputPeripheralGATTDatabase.ThroughputService.ThroughputIndications.cbUUID, in: characteritics!) else {
                state.value = .failure(reason: "Did not found Throughput Indiciations.")
                return
            }
            
            throughputPeripheralReferences.throughputIndications = indicationsCharacteristic
            
            guard let notificationsCharacteristic =  findCharacteristic(SILThroughputPeripheralGATTDatabase.ThroughputService.ThroughputNotifications.cbUUID, in: characteritics!) else {
                state.value = .failure(reason: "Did not found Throughput Notifications.")
                return
            }
            
            throughputPeripheralReferences.throughputNotifications = notificationsCharacteristic
            
            guard let transmissionOnCharacteristic = findCharacteristic(SILThroughputPeripheralGATTDatabase.ThroughputService.TransmissionOn.cbUUID, in: characteritics!) else {
                state.value = .failure(reason: "Did not found Transmission On.")
                return
            }
            
            throughputPeripheralReferences.throughputTransmissionOn = transmissionOnCharacteristic
            
            guard let throughputResult = findCharacteristic(SILThroughputPeripheralGATTDatabase.ThroughputService.ThroughputResult.cbUUID, in: characteritics!) else {
                state.value = .failure(reason: "Did not found Throughput Result.")
                return
            }
            
            throughputPeripheralReferences.throughputResult = throughputResult
            
            debugPrint("Discovered Throughput Service!")
            
            peripheral.discoverCharacteristics([SILThroughputPeripheralGATTDatabase.ThroughputInformationService.PHYStatus.cbUUID,
                                                SILThroughputPeripheralGATTDatabase.ThroughputInformationService.ConnectionInterval.cbUUID,
                                                SILThroughputPeripheralGATTDatabase.ThroughputInformationService.SlaveLatency.cbUUID,
                                                SILThroughputPeripheralGATTDatabase.ThroughputInformationService.SupervisionTimeout.cbUUID,
                                                SILThroughputPeripheralGATTDatabase.ThroughputInformationService.MTUSize.cbUUID,
                                                SILThroughputPeripheralGATTDatabase.ThroughputInformationService.PDUSize.cbUUID], for: throughputPeripheralReferences.throughputInformationService!)
            
        } else {
            guard let phyStatusCharacteristic =   findCharacteristic(SILThroughputPeripheralGATTDatabase.ThroughputInformationService.PHYStatus.cbUUID, in: characteritics!) else {
                state.value = .failure(reason: "Did not found PHY Status.")
                return
            }
            
            throughputPeripheralReferences.phyStatus = phyStatusCharacteristic
            
            guard let connectionInterval =  findCharacteristic(SILThroughputPeripheralGATTDatabase.ThroughputInformationService.ConnectionInterval .cbUUID, in: characteritics!) else {
                state.value = .failure(reason: "Did not found Connection Interval.")
                return
            }
            
            throughputPeripheralReferences.connectionInterval = connectionInterval
            
            guard let slaveLatencyCharacteristic = findCharacteristic(SILThroughputPeripheralGATTDatabase.ThroughputInformationService.SlaveLatency.cbUUID, in: characteritics!) else {
                state.value = .failure(reason: "Did not found Slave Latency.")
                return
            }
            
            throughputPeripheralReferences.slaveLatency = slaveLatencyCharacteristic
            
            guard let supervisionTimeoutCharacteristic = findCharacteristic(SILThroughputPeripheralGATTDatabase.ThroughputInformationService.SupervisionTimeout.cbUUID, in: characteritics!) else {
                state.value = .failure(reason: "Did not found Supervision Timeout.")
                return
            }
            
            throughputPeripheralReferences.supervisionTimeout = supervisionTimeoutCharacteristic
            
            guard let mtuSizeCharacteristic = findCharacteristic(SILThroughputPeripheralGATTDatabase.ThroughputInformationService.MTUSize.cbUUID, in: characteritics!) else {
                state.value = .failure(reason: "Did not found MTU Size.")
                return
            }
            
            throughputPeripheralReferences.mtuSize = mtuSizeCharacteristic
            
            guard let pduSizeCharacteristic = findCharacteristic(SILThroughputPeripheralGATTDatabase.ThroughputInformationService.PDUSize.cbUUID, in: characteritics!) else {
                state.value = .failure(reason: "Did not found PDU Size.")
                return
            }
            
            throughputPeripheralReferences.pduSize = pduSizeCharacteristic
            
            debugPrint("Discovered Throughput Information Service!")
            
            subscribeGATT()
        }
    }
    
    private func findCharacteristic(_ characteristicUUID: CBUUID, in characteristics: [CBCharacteristic]) -> CBCharacteristic? {
        return characteristics.first(where: { characteristic in characteristic.uuid == characteristicUUID })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        debugPrint("DID UPDATE NOTIFICATION STATE FOR \(characteristic.uuid) \(characteristic.isNotifying) \(String(describing: characteristic.value?.hexa()))")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            debugPrint(error.localizedDescription)
            return
        }
        
        if characteristic.uuid.uuidString == SILThroughputPeripheralGATTDatabase.ThroughputService.TransmissionOn.uuid {
            didUpdateTransmissionOn(value: characteristic.value)
            return
        }
        
        if currentTestDirection.value == .EFRToPhone {
            if characteristic.uuid.uuidString == SILThroughputPeripheralGATTDatabase.ThroughputService.ThroughputNotifications.uuid || characteristic.uuid.uuidString == SILThroughputPeripheralGATTDatabase.ThroughputService.ThroughputIndications.uuid {
                if let value = characteristic.value {
                    throughputCountInBits += value.count * 8
                    
                    if currentTestType == .none {
                        if characteristic.uuid.uuidString == SILThroughputPeripheralGATTDatabase.ThroughputService.ThroughputNotifications.uuid {
                            currentTestType = .notifications
                        } else {
                            currentTestType = .indications
                        }
                        
                        debugPrint("SET TEST TYPE")
                        self.throughputResult.value = SILThroughputResult(sender: .EFRToPhone, testType: currentTestType, valueInBits: 0)
                    }
                }
                
                return
            }
        } else if characteristic.uuid.uuidString == SILThroughputPeripheralGATTDatabase.ThroughputService.ThroughputResult.uuid {
            didUpdateThroughputResult(value: characteristic.value)
            return
        }
        
        if let value = characteristic.value {
            state.value = .updateValue(data: value, for: characteristic)
        }
    }
    
    private func didUpdateTransmissionOn(value: Data?) {
        if value?.hexa() == "0x00" {
            debugPrint("TEST INACTIVE")
            currentTestType = .none
            currentTestDirection.value = .none
            throughputReleaseTimer?.invalidate()
            throughputReleaseTimer = nil
            throughputCountInBits = 0
        } else if currentTestDirection.value != .phoneToEFR {
            debugPrint("TEST ACTIVE")
            currentTestDirection.value = .EFRToPhone
            if throughputReleaseTimer == nil {
                throughputReleaseTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { timer in
                    debugPrint("RELEASE FROM EFR \(self.throughputCountInBits)")
                    self.throughputResult.value = SILThroughputResult(sender: .EFRToPhone, testType: self.currentTestType, valueInBits: self.throughputCountInBits * 5)
                    self.throughputCountInBits = 0
                })
            }
        }
    }
        
    private func didUpdateThroughputResult(value: Data?) {
        self.throughputResult.value = SILThroughputResult(sender: .EFRToPhone, testType: self.currentTestType, valueInBits: 0)
        debugPrint("RELEASE FROM EFR \(self.throughputResult.value.valueInBits)")
        self.throughputCountInBits = 0
        self.currentTestType = .none
    }
}
