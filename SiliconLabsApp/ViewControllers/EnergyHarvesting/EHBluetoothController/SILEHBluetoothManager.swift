//
//  SILEHBluetoothManager.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 29/09/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import UIKit
import Foundation
protocol SILEHBluetoothManagerDelegate: AnyObject {
    func energyHarvestingBluetoothManagerIO(simpleBluetoothIO: SILEHBluetoothManager, didReceiveValue advValue: [String : Any], from peripheral: CBPeripheral, rssi: NSNumber)
}
class SILEHBluetoothManager: NSObject {
    
    weak var EHBluetoothManagerDelegate: SILEHBluetoothManagerDelegate?
    
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    var targetService: CBService?
    var writableCharacteristic: CBCharacteristic?
    init(delegate: SILEHBluetoothManagerDelegate?) {
        self.EHBluetoothManagerDelegate = delegate
        super.init()
        //centralManager = CBCentralManager(delegate: self, queue: .main)
        let opts = [ CBCentralManagerOptionShowPowerAlertKey : true ]
        let queue = DispatchQueue(label: "com.silabs.EH.blequeue", attributes: [])
        centralManager = CBCentralManager(delegate: self, queue: queue, options: opts)
    }
    


}

extension SILEHBluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
        default:
            print("Central state: \(central.state.rawValue)")
        }
    }
   
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        connectedPeripheral = peripheral
        if let name = peripheral.name {
            if name == "EH Sensor" {
                // print("++++++++++++++++++ ENERGY HARVESTING: \(peripheral)")
               // print("++++++++++++++++++ ENERGY HARVESTING ADVERTISEMENT: \(advertisementData)");

               // print("++++++++++++++++++ ENERGY HARVESTING ADVERTISEMENT DATA: \(advertisementData["kCBAdvDataManufacturerData"] ?? "") TIME: \(advertisementData["kCBAdvDataTimestamp"] ?? "")")
                
               // print("RSSI VALUE: \(RSSI.intValue)")
               // print("RSSI VALUE: \(peripheral.identifier)")
                EHBluetoothManagerDelegate?.energyHarvestingBluetoothManagerIO(simpleBluetoothIO: self, didReceiveValue: advertisementData, from: peripheral, rssi: RSSI)
            }
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
        if let name = peripheral.name {
            print("Connected! With \(name)")
        }
    }
    private func startScanning() {
        guard centralManager.state == .poweredOn else { return }
//        let options: [String: Any] = [
//            CBCentralManagerScanOptionAllowDuplicatesKey: true
//        ]
        // If you know the service UUID(s), put them here to reduce load:
        // let services = [CBUUID(string: "<SERVICE>")]
        //centralManager.scanForPeripherals(withServices: nil, options: options)
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])

        print("Scanning started (duplicates ON)")
    }
}
