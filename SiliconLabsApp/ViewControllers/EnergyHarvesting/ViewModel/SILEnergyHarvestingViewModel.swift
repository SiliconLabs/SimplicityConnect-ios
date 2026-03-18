//
//  SILEnergyHarvestingViewModel.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 29/09/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import UIKit
protocol SILEnergyHarvestingViewModelDelegate: AnyObject {
    func energyHarvestingViewModel(didReceiveVoltage value: Int, RSSI: NSNumber, peripheralName: String, peripheralUUID: String, timeStamp: String, advertisingInterval: Double)
}

class SILEnergyHarvestingViewModel: NSObject,  SILEHBluetoothManagerDelegate{

    var SILEnergyHarvestingViewModelDelegate: SILEnergyHarvestingViewModelDelegate?
    var energyHarvestingBluetoothManagerOBj: SILEHBluetoothManager!
    var timeDiff: Double = 0.0
    var advertisingInterval = 0.0
    private var lastTimestamp = 0.0
    private var packetReceivedCount: Int64 = 0

    init(delegate: SILEnergyHarvestingViewModelDelegate)  {
        super.init()
        SILEnergyHarvestingViewModelDelegate = delegate
        self.energyHarvestingBluetoothManagerOBj = SILEHBluetoothManager(delegate: self)
        advertisingInterval = 0
        lastTimestamp = 0
        packetReceivedCount = 0
    }
    
    func getEnergyHarvestingData(voltage: Data, peripheral: CBPeripheral, rssi: NSNumber, timeStamp: Double)  {
        let voltageInHex = voltage.decodeManufacturerDataForEnergyHarvesting()
        let volatgeInInt = voltageInHex.hexToMillivolts()

           // timeDiff = timeStamp - self.timeDiff
        calculateAdvertisingInterval(with: timeStamp)
        lastTimestamp = timeStamp
            
       // advertisingInterval
        
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss" // 24-hour format. Use "hh:mm:ss a" for 12-hour format with AM/PM
        let timeString = formatter.string(from: currentDate)

        SILEnergyHarvestingViewModelDelegate?.energyHarvestingViewModel(didReceiveVoltage: volatgeInInt, RSSI: rssi, peripheralName: peripheral.name ?? "EH" , peripheralUUID: "\(peripheral.identifier)", timeStamp: timeString, advertisingInterval: advertisingInterval)
        
    }
    //MARK:- SILEHBluetoothManagerDelegate
 
    func energyHarvestingBluetoothManagerIO(simpleBluetoothIO: SILEHBluetoothManager, didReceiveValue advValue: [String : Any], from peripheral: CBPeripheral, rssi: NSNumber) {
        if let manufacturerData = advValue[CBAdvertisementDataManufacturerDataKey] as? Data {
            packetReceivedCount += 1
            self.getEnergyHarvestingData(voltage: manufacturerData, peripheral: peripheral, rssi: rssi, timeStamp: advValue["kCBAdvDataTimestamp"] as? Double ?? 0.0)
        }

    }
    
    private func timeDifference(advTimeStamp: Double) -> String {
                //let advTimestamp = 780314283.577829
                let referenceDate = Date(timeIntervalSinceReferenceDate: advTimeStamp)
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: referenceDate)
        
                if let hour = components.hour, let minute = components.minute {
                    let formattedTime = String(format: "%d:%02d", hour, minute)
                    print(formattedTime)
                    return formattedTime
                }
        return ""
    }
    private func calculateAdvertisingInterval(with currentTimestamp: Double) {
        let add3MsToInterval: Double = 0.003
        let multiplierForBegginingCalculating: Double = 0.0007
        let multiplierForAverageInterval: Double = 0.0014
        let reliableForCalculatingPacketAmount: Int64 = 29
        let minimumCount: Int64 = 10

        let currentInterval = currentTimestamp - lastTimestamp
        
        if currentInterval <= 0 {
            return
        }

        if advertisingInterval == 0 {
            advertisingInterval = currentInterval
            //advertisingInterval = 0.0

        } else if (currentInterval < advertisingInterval * multiplierForBegginingCalculating) && packetReceivedCount < minimumCount {
            advertisingInterval = currentInterval
        } else if currentInterval < advertisingInterval + add3MsToInterval {
            let limitedCount = min(packetReceivedCount, minimumCount)
            advertisingInterval = (advertisingInterval * Double(limitedCount - 1) + currentInterval) / Double(limitedCount)
        } else if currentInterval < advertisingInterval * multiplierForAverageInterval {
            advertisingInterval = Double(advertisingInterval * Double(reliableForCalculatingPacketAmount) + currentInterval) / Double(reliableForCalculatingPacketAmount + 1)
        }
    }
}
