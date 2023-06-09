//
//  SILESLPeripheralDelegate.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 2.2.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxSwift
import RxCocoa

enum SILESLPeripheralDelegateError: Error, LocalizedError {
    case missingService
    case wrongCharacteristics
    case missingESLControlPoint
    case missingESLImageTransfer
    case eslControlPointIsntNotifying
    case eslImageTransferIsnNotifying
    case notifactionStateUpdateError
    
    public var errorDescription: String? {
        switch self {
        case .missingService:
            return "Missing ESL Demo service."
        case .wrongCharacteristics:
            return "Wrong characteristics in the ESL Demo service."
        case .missingESLControlPoint:
            return "Missing ESL Control Point characteristic."
        case .missingESLImageTransfer:
            return "Missing ESL Image Transfer characteristic."
        case .eslControlPointIsntNotifying:
            return "Characteristic ESL Control Point isn't notifying."
        case .eslImageTransferIsnNotifying:
            return "Characteristic ESL Image Transfer isn't notifying."
        case .notifactionStateUpdateError:
            return "Notification state update error."
        }
    }
}

class SILESLPeripheralDelegate: NSObject, CBPeripheralDelegate {
    let peripheral: CBPeripheral
    var peripheralReferences: SILESLPeripheralGATTReferences
    let initializationState = PublishRelay<SILESLPeripheralDelegateError?>()
    let notificationState = PublishRelay<SILESLPeripheralDelegateError?>()
    
    init(peripheral: CBPeripheral, peripheralReferences: SILESLPeripheralGATTReferences) {
        self.peripheral = peripheral
        self.peripheralReferences = peripheralReferences
        super.init()
        self.peripheral.delegate = self
    }
    
    func discoverGATTDatabase() {
        self.peripheral.discoverServices([SILESLPeripheralGATTDatabase.ESLDemoService.cbUUID])
    }
    
    func checkIfCharacteristicsAreNotifying() {
        guard let eslControlPoint = peripheralReferences.eslControlPoint, eslControlPoint.isNotifying else {
            self.notificationState.accept(.eslControlPointIsntNotifying)
            return
        }
        
        guard let eslTransferImage = peripheralReferences.eslTransferImage, eslTransferImage.isNotifying else {
            self.notificationState.accept(.eslImageTransferIsnNotifying)
            return
        }
        
        self.notificationState.accept(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            self.initializationState.accept(.missingService)
            return
        }
        
        if let services = peripheral.services {
            peripheralReferences.eslDemoService = services.first(where: { service in service.uuid == SILESLPeripheralGATTDatabase.ESLDemoService.cbUUID })
            
            if let eslDemoService = peripheralReferences.eslDemoService {
                peripheral.discoverCharacteristics([SILESLPeripheralGATTDatabase.ESLDemoService.ESLControlPoint.cbUUID,
                                                    SILESLPeripheralGATTDatabase.ESLDemoService.ESLTransferImage.cbUUID],
                                                   for: eslDemoService)
            } else {
                self.initializationState.accept(.missingService)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            self.initializationState.accept(.wrongCharacteristics)
            return
        }
        
        guard let characteristics = service.characteristics, characteristics.count == 2 else {
            self.initializationState.accept(.wrongCharacteristics)
            return
        }
        
        peripheralReferences.eslControlPoint = characteristics.first(where: { characteristic in characteristic.uuid == SILESLPeripheralGATTDatabase.ESLDemoService.ESLControlPoint.cbUUID })
        peripheralReferences.eslTransferImage = characteristics.first(where: { characteristic in characteristic.uuid == SILESLPeripheralGATTDatabase.ESLDemoService.ESLTransferImage.cbUUID })
            
        guard let eslControlPoint = peripheralReferences.eslControlPoint else {
            self.initializationState.accept(.missingESLControlPoint)
            return
        }
            
        peripheral.setNotifyValue(true, for: eslControlPoint)
        
        guard let eslTransferImage = peripheralReferences.eslTransferImage else {
            self.initializationState.accept(.missingESLImageTransfer)
            return
        }
          
        peripheral.setNotifyValue(true, for: eslTransferImage)
        
        self.initializationState.accept(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            self.initializationState.accept(.notifactionStateUpdateError)
            return
        }
    }
}
