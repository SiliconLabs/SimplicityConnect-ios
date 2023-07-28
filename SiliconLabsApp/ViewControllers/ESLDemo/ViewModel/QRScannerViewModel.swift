//
//  QRScannerViewModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 28.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation

struct ESLQRData {
    let bluetoothAddress: SILBluetoothAddress
    let rawData: [UInt8]
}

class QRScannerViewModel {
    func readQR(metadata: String) -> ESLQRData? {
        let words = split(metadata: metadata)
        
        guard let btAddress = words.first(where: { word in word.count == 17 }) else {
            return nil
        }

        let bluetoothAddress = SILBluetoothAddress(address: btAddress, addressType: .public)
        guard bluetoothAddress.isValid else {
            return nil
        }
        
        return ESLQRData(bluetoothAddress: bluetoothAddress, rawData: metadata.bytes)
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
