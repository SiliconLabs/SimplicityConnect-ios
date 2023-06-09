//
//  SILAdvertiser.swift
//  BlueGecko
//
//  Created by Michał Lenart on 23/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

fileprivate struct SILRunningAdvertiser {
    var peripheralManager: CBPeripheralManager
    var advertiser: SILAdvertisingSetEntity
}

class SILAdvertiserService: NSObject, CBPeripheralManagerDelegate {
    static let shared = SILAdvertiserService()
    private let settings: SILAdvertiserSettings = SILAdvertiserSettings.shared
    
    let runningAdvertisers: SILObservable<[SILAdvertisingSetEntity]> = SILObservable(initialValue: [])
    let blutoothEnabled: SILObservable<Bool> = SILObservable(initialValue: true)
    private var runningAdvertisersMap: [String: SILRunningAdvertiser] = [:]
    
    private override init() {
        super.init()
    }
    
    deinit {
        stopAllAdvertisers()
    }
    
    func start(advertiser: SILAdvertisingSetEntity) {
        stop(advertiser: advertiser)
        
        let peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        let runningAdvertiser = SILRunningAdvertiser(peripheralManager: peripheralManager, advertiser: advertiser)
        
        runningAdvertisersMap[advertiser.uuid] = runningAdvertiser
        updateRunningAdvertisers()
    }

    func stop(advertiser: SILAdvertisingSetEntity) {
        if let runningAdvertiser = runningAdvertisersMap.removeValue(forKey: advertiser.uuid) {
            runningAdvertiser.peripheralManager.delegate = nil
            runningAdvertiser.peripheralManager.stopAdvertising()
            
            updateRunningAdvertisers()
        }
    }
    
    func stopAllAdvertisers() {
        for runningAdvertiser in runningAdvertisersMap.values {
            runningAdvertiser.peripheralManager.delegate = nil
            runningAdvertiser.peripheralManager.stopAdvertising()
        }
        
        runningAdvertisersMap.removeAll()
        updateRunningAdvertisers()
    }
    
    func isRunning(advertiser: SILAdvertisingSetEntity) -> Bool {
        return runningAdvertisers.value.contains(where: { $0.uuid == advertiser.uuid })
    }
    
    private func updateRunningAdvertisers() {
        runningAdvertisers.value = Array(runningAdvertisersMap.values.map({$0.advertiser}))
    }
    
    // MARK: CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard let runningAdvertiser = findRunningAdvertiser(withPeripheral: peripheral) else {
            return
        }
        
        if peripheral.state == CBManagerState.poweredOn {
            if blutoothEnabled.value == false {
                blutoothEnabled.value = true
                print("Bluetooth enabled")
            }
            
            let advertiser = runningAdvertiser.advertiser
            var advertisementData: [String: Any] = [:]
            
            if advertiser.isCompleteLocalName {
                advertisementData[CBAdvertisementDataLocalNameKey] = settings.completeLocalName
            }
            
            var serviceUUUIDs: [CBUUID]?
            
            if let completeList16 = advertiser.completeList16 {
                serviceUUUIDs = serviceUUUIDs ?? []
                
                let cbUUUIDs = completeList16.map({CBUUID(string: $0)})
                serviceUUUIDs?.append(contentsOf: cbUUUIDs)
            }
            
            if let completeList128 = advertiser.completeList128 {
                serviceUUUIDs = serviceUUUIDs ?? []

                let cbUUUIDs = completeList128.map({CBUUID(string: $0)})
                serviceUUUIDs?.append(contentsOf: cbUUUIDs)
            }
            
            advertisementData[CBAdvertisementDataServiceUUIDsKey] = serviceUUUIDs;
            
            peripheral.startAdvertising(advertisementData)
            
            if (runningAdvertiser.advertiser.isExecutionTime) {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(runningAdvertiser.advertiser.executionTime / 1000), execute: {
                    self.stop(advertiser: runningAdvertiser.advertiser)
                })
            }
        } else if peripheral.state == CBManagerState.poweredOff {
            blutoothEnabled.value = false
            print("Bluetooth disabled")
            stopAllAdvertisers()
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        guard let runningAdvertiser = findRunningAdvertiser(withPeripheral: peripheral) else {
            return
        }
        
        if let error = error {
            print("Error starting advertising", error.localizedDescription)
            stop(advertiser: runningAdvertiser.advertiser)
        } else {
            print("Peripheral manager did start advertising")
        }
    }

    // MARK: Utils
    
    private func findRunningAdvertiser(withPeripheral peripheral: CBPeripheralManager) -> SILRunningAdvertiser? {
        return runningAdvertisersMap.values.first { runningAdvertiser in
            return runningAdvertiser.peripheralManager === peripheral
        }
    }
}
