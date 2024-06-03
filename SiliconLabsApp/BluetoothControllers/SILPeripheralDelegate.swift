//
//  SILPeripheralDelegate.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 29.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

enum SILPeripheralDelegateStatus {
    case successForServices(_ services: [CBService])
    case successForCharacteristics(_ characteristics: [CBCharacteristic])
    case successForDescriptors(_ descriptors: [CBDescriptor]) //Added
    case successGetValue(value: Data?, characteristic: CBCharacteristic)
    case successGetValueDescriptor(value: Any?, descriptor: CBDescriptor) //Added
    case successWrite(characteristic: CBCharacteristic)
    case updateNotificationState(characteristic: CBCharacteristic, state: Bool)
    case servicesModified(peripheral: CBPeripheral)
    case failure(error: Error)
    case unknown
}

class SILPeripheralDelegate: NSObject, CBPeripheralDelegate {
    private var peripheral: CBPeripheral
    
    var status: SILObservable<SILPeripheralDelegateStatus> = SILObservable(initialValue: .unknown)
    
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
        self.peripheral.delegate = self
    }
    
    func updatePeripheral(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.peripheral.delegate = self
    }
    
    func newStatus() -> SILObservable<SILPeripheralDelegateStatus> {
        status = SILObservable(initialValue: .unknown)
        return status
    }
    //ADDED NEW...
    func discoverDescriptors(for characteristic: CBCharacteristic) {
        self.peripheral.discoverDescriptors(for: characteristic)
    }
    //ADDED NEW...
    func readDescriptor(descriptor: CBDescriptor) {
        self.peripheral.readValue(for: descriptor)
    }
    //ADDED NEW...
    func writeToDescriptor(data: Data, descriptor: CBDescriptor) {
        self.peripheral.writeValue(data, for: descriptor)
    }
    //END
    
    func discoverServices(services: [CBUUID]?) {
        self.peripheral.discoverServices(services)
    }
    
    func discoverCharacteristics(characteristics: [CBUUID]?, for service: CBService) {
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
    
    func findService(with serviceUUID: CBUUID, in peripheral: CBPeripheral) -> CBService? {
        return peripheral.services?.first(where: { service in service.uuid == serviceUUID})
    }
    
    func findCharacteristic(with characteristicUUID: CBUUID, in characteristics: [CBCharacteristic]) -> CBCharacteristic? {
        return characteristics.first(where: { characteristic in characteristic.uuid == characteristicUUID })
    }
    
    //ADDED NEW...
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        debugPrint("didDiscoverDescriptors*********")
        if let error = error {
            status.value = .failure(error: error)
        } else {
            status.value = .successForDescriptors(characteristic.descriptors!)
        }
    }

    //ADDED NEW...
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        debugPrint("didUpdateValueForDescriptor*********")
        if let error = error {
            status.value = .failure(error: error)
        } else {
            status.value = .successGetValueDescriptor(value: descriptor.value, descriptor: descriptor)
        }
    }
    //END
}
