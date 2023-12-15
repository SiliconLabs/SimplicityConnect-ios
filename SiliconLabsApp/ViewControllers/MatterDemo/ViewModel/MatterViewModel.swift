//
//  MatterViewModel.swift
//  BlueGecko
//
//  Created by Mantosh Kumar on 26/08/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation

struct MatterQRData {
    let bluetoothAddress: SILBluetoothAddress
    let rawData: [UInt8]
}

class MatterQRScannerViewModel {
    func readQR(metadata: String) -> MatterQRData? {
        let words = split(metadata: metadata)
        
        guard let btAddress = words.first(where: { word in word.count == 22 }) else {
            return nil
        }

        let bluetoothAddress = SILBluetoothAddress(address: btAddress, addressType: .public)
        guard bluetoothAddress.isValid else {
            return nil
        }
        
        return MatterQRData(bluetoothAddress: bluetoothAddress, rawData: metadata.bytes)
    }
    
    private func split(metadata: String) -> [String] {
        let words = metadata.split(separator: " ")
        
        var strings = [String]()
        for word in words {
            strings.append(String(word))
        }
        
        return strings
    }
}
