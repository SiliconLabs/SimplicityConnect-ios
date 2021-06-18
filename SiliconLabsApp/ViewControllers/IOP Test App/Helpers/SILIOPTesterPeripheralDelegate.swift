//
//  SILIOPTesterPeripheralDelegate.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 29.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

enum SILIOPTesterPeripheralDelegateStatus {
    case successForServices(_ services: [CBService])
    case successForCharacteristics(_ characteristics: [CBCharacteristic])
    case successGetValue(value: Data?, characteristic: CBCharacteristic)
    case successWrite(characteristic: CBCharacteristic)
    case updateNotificationState(characteristic: CBCharacteristic, state: Bool)
    case servicesModified(peripheral: CBPeripheral)
    case failure(error: Error)
    case unknown
}

class SILIOPTesterPeripheralDelegate: NSObject, CBPeripheralDelegate {
    private var peripheral: CBPeripheral
    
    var status: SILObservable<SILIOPTesterPeripheralDelegateStatus> = SILObservable(initialValue: .unknown)
    
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
        self.peripheral.delegate = self
    }
    
    func updatePeripheral(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.peripheral.delegate = self
    }
    
    func newStatus() -> SILObservable<SILIOPTesterPeripheralDelegateStatus> {
        status = SILObservable(initialValue: .unknown)
        return status
    }
    
    func discoverServices(services: [CBUUID]) {
        self.peripheral.discoverServices(services)
    }
    
    func discoverCharacteristics(characteristics: [CBUUID], for service: CBService) {
        self.peripheral.discoverCharacteristics(characteristics, for: service)
    }
    
    func readCharacteristic(characteristic: CBCharacteristic) {
        self.peripheral.readValue(for: characteristic)
    }
    
    func writeToCharacteristic(data: Data, characteristic: CBCharacteristic, writeType: CBCharacteristicWriteType) {
        self.peripheral.writeValue(data, for: characteristic, type: writeType)
    }
    
    func notifyCharacteristic(characteristic: CBCharacteristic, enabled: Bool = true) {
        self.peripheral.setNotifyValue(enabled, for: characteristic)
    }
    
    func getMTUValue(for writeType: CBCharacteristicWriteType) -> Int {
        return self.peripheral.maximumWriteValueLength(for: writeType)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        debugPrint("didDiscoverServices**********")
        if let error = error {
            status.value = .failure(error: error)
        } else {
            status.value = .successForServices(peripheral.services!)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        debugPrint("didDiscoverCharacteristics*********")
        if let error = error {
            status.value = .failure(error: error)
        } else {
            status.value = .successForCharacteristics(service.characteristics!)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        debugPrint("didUpdateValueForCharacteristic*********")
        if let error = error {
            status.value = .failure(error: error)
        } else {
            status.value = .successGetValue(value: characteristic.value, characteristic: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        debugPrint("didWriteValueForCharacteristic*********")
        if let error = error {
            status.value = .failure(error: error)
        } else {
            status.value = .successWrite(characteristic: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        debugPrint("didUpdateNotificationStateFor*********")
        if let error = error {
            status.value = .failure(error: error)
        } else {
            status.value = .updateNotificationState(characteristic: characteristic, state: characteristic.isNotifying)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        debugPrint("didMofifyServices*********")
        status.value = .servicesModified(peripheral: peripheral)
    }
}
