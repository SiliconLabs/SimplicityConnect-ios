//
//  SILIOPGATTSpecCatalog.swift
//  BlueGecko
//
//  Created by Cursor on 07/07/26.
//

import Foundation
import CoreBluetooth

struct SILIOPGATTSpecCharacteristic {
    let name: String
    let specLabel: String
    let uuid: CBUUID
    let properties: [String]
}

struct SILIOPGATTSpecService {
    let name: String
    let specLabel: String
    let uuid: CBUUID
    let characteristics: [SILIOPGATTSpecCharacteristic]
}

enum SILIOPGATTSpecCatalog {
    static let services: [SILIOPGATTSpecService] = [
        SILIOPGATTSpecService(
            name: "Device Information Service",
            specLabel: "Core device information",
            uuid: SILIOPPeripheral.DeviceInformationService.cbUUID,
            characteristics: [
                SILIOPGATTSpecCharacteristic(
                    name: "Model Number String",
                    specLabel: "Board / model identifier",
                    uuid: SILIOPPeripheral.DeviceInformationService.ModelNumberStringCharacteristic.cbUUID,
                    properties: ["Read"]
                )
            ]
        ),
        SILIOPGATTSpecService(
            name: "IOP Test Service",
            specLabel: "IOP control and connection metadata",
            uuid: SILIOPPeripheral.SILIOPTest.cbUUID,
            characteristics: [
                SILIOPGATTSpecCharacteristic(
                    name: "IOP Test Version",
                    specLabel: "Firmware / stack version readout",
                    uuid: SILIOPPeripheral.SILIOPTest.IOPTestVersion.cbUUID,
                    properties: ["Read"]
                ),
                SILIOPGATTSpecCharacteristic(
                    name: "IOP Test Connection",
                    specLabel: "Connection parameters payload",
                    uuid: SILIOPPeripheral.SILIOPTest.IOPTestConnection.cbUUID,
                    properties: ["Read"]
                ),
                SILIOPGATTSpecCharacteristic(
                    name: "IOP Test Control RFU",
                    specLabel: "Reserved test control / RFU payload",
                    uuid: SILIOPPeripheral.SILIOPTest.IOPTestControlRFU.cbUUID,
                    properties: ["Read"]
                )
            ]
        ),
        SILIOPGATTSpecService(
            name: "IOP Test Properties Service",
            specLabel: "GATT property interoperability matrix",
            uuid: SILIOPPeripheral.SILIOPTestProperties.cbUUID,
            characteristics: [
                SILIOPGATTSpecCharacteristic(name: "IOP Test Read Only Length 1", specLabel: "Test 4.1", uuid: SILIOPPeripheral.SILIOPTestProperties.IOPTest_ROLen1.cbUUID, properties: ["Read"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Read Only Length 255", specLabel: "Test 4.2", uuid: SILIOPPeripheral.SILIOPTestProperties.IOPTest_ROLen255.cbUUID, properties: ["Read"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Write Only Length 1", specLabel: "Test 4.3", uuid: SILIOPPeripheral.SILIOPTestProperties.IOPTest_WRLen1.cbUUID, properties: ["Write"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Write Only Length 255", specLabel: "Test 4.4", uuid: SILIOPPeripheral.SILIOPTestProperties.IOPTest_WRLen255.cbUUID, properties: ["Write"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Write Without Response Length 1", specLabel: "Test 4.5", uuid: SILIOPPeripheral.SILIOPTestProperties.IOPTest_WRNoResLen1.cbUUID, properties: ["Write Without Response"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Write Without Response Length 255", specLabel: "Test 4.6", uuid: SILIOPPeripheral.SILIOPTestProperties.IOPTest_WRNoResLen255.cbUUID, properties: ["Write Without Response"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Notify Length 1", specLabel: "Test 4.7", uuid: SILIOPPeripheral.SILIOPTestProperties.IOPTest_NotifyLen1.cbUUID, properties: ["Notify"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Notify Length MTU - 3", specLabel: "Test 4.8", uuid: SILIOPPeripheral.SILIOPTestProperties.IOPTest_NotifyLen255.cbUUID, properties: ["Notify"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Indicate Length 1", specLabel: "Test 4.9", uuid: SILIOPPeripheral.SILIOPTestProperties.IOPTest_IndicateLen1.cbUUID, properties: ["Indicate"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Indicate Length MTU - 3", specLabel: "Test 4.10", uuid: SILIOPPeripheral.SILIOPTestProperties.IOPTest_IndicateLen255.cbUUID, properties: ["Indicate"])
            ]
        ),
        SILIOPGATTSpecService(
            name: "IOP Test Characteristic Types Service",
            specLabel: "Characteristic type interoperability matrix",
            uuid: SILIOPPeripheral.SILIOPTestCharacteristicTypes.cbUUID,
            characteristics: [
                SILIOPGATTSpecCharacteristic(name: "IOP Test Length 1", specLabel: "Test 5.1", uuid: SILIOPPeripheral.SILIOPTestCharacteristicTypes.IOPTestChar_RWLen1.cbUUID, properties: ["Read", "Write"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Length 255", specLabel: "Test 5.2", uuid: SILIOPPeripheral.SILIOPTestCharacteristicTypes.IOPTestChar_RWLen255.cbUUID, properties: ["Read", "Write"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Length Variable 4", specLabel: "Test 5.3", uuid: SILIOPPeripheral.SILIOPTestCharacteristicTypes.IOPTestChar_RWVariableLen4.cbUUID, properties: ["Read", "Write"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Const Length 1", specLabel: "Test 5.4", uuid: SILIOPPeripheral.SILIOPTestCharacteristicTypes.IOPTestChar_RWConstLen1.cbUUID, properties: ["Read", "Write"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Const Length 255", specLabel: "Test 5.5", uuid: SILIOPPeripheral.SILIOPTestCharacteristicTypes.IOPTestChar_RWConstLen255.cbUUID, properties: ["Read", "Write"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test User Len 1", specLabel: "Test 5.6", uuid: SILIOPPeripheral.SILIOPTestCharacteristicTypes.IOPTestChar_RWUserLen1.cbUUID, properties: ["Read", "Write"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test User Len 255", specLabel: "Test 5.7", uuid: SILIOPPeripheral.SILIOPTestCharacteristicTypes.IOPTestChar_RWUserLen255.cbUUID, properties: ["Read", "Write"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test User Len Variable 4", specLabel: "Test 5.8", uuid: SILIOPPeripheral.SILIOPTestCharacteristicTypes.IOPTestChar_RWUserLen4.cbUUID, properties: ["Read", "Write"])
            ]
        ),
        SILIOPGATTSpecService(
            name: "IOP Test Phase 3 Service",
            specLabel: "Security, throughput, and caching flows",
            uuid: SILIOPPeripheral.SILIOPTestPhase3.cbUUID,
            characteristics: [
                SILIOPGATTSpecCharacteristic(name: "IOP Test Phase 3 Control", specLabel: "Phase 3 control", uuid: SILIOPPeripheral.SILIOPTestPhase3.IOPTest_Phase3_Control.cbUUID, properties: ["Write"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Security Pairing", specLabel: "Test 7.2", uuid: SILIOPPeripheral.SILIOPTestPhase3.IOPTest_Security_Pairing.cbUUID, properties: ["Read"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Security Authentication", specLabel: "Test 7.3", uuid: SILIOPPeripheral.SILIOPTestPhase3.IOPTest_Security_Authen.cbUUID, properties: ["Read"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Security Bonding", specLabel: "Tests 7.4 / 7.5 / 7.6", uuid: SILIOPPeripheral.SILIOPTestPhase3.IOPTest_Security_Bonding.cbUUID, properties: ["Read", "Notify"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test Throughput GATT Notification", specLabel: "Test 7.1", uuid: SILIOPPeripheral.SILIOPTestPhase3.IOPTest_Throughput_GATT.cbUUID, properties: ["Notify"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test GATT Caching 7.5", specLabel: "GATT caching reference", uuid: SILIOPPeripheral.SILIOPTestPhase3.IOPTest_GATT_Caching_7_5Test.cbUUID, properties: ["Read"]),
                SILIOPGATTSpecCharacteristic(name: "IOP Test GATT Caching 7.6", specLabel: "LE privacy reference", uuid: SILIOPPeripheral.SILIOPTestPhase3.IOPTest_GATT_Caching_7_6Test.cbUUID, properties: ["Read"])
            ]
        )
    ]
    
    static func service(for uuid: CBUUID) -> SILIOPGATTSpecService? {
        services.first { $0.uuid == uuid }
    }
    
    static func characteristic(for uuid: CBUUID) -> SILIOPGATTSpecCharacteristic? {
        for service in services {
            if let characteristic = service.characteristics.first(where: { $0.uuid == uuid }) {
                return characteristic
            }
        }
        return nil
    }
    
    static func displayServiceName(for uuid: CBUUID) -> String {
        service(for: uuid)?.name ?? "Spec Service \(uuid.uuidString)"
    }
    
    static func displayCharacteristicName(for uuid: CBUUID) -> String {
        characteristic(for: uuid)?.name ?? "Spec Characteristic \(uuid.uuidString)"
    }
}
