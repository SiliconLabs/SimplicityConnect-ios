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
    let passcode: String?
}

class QRScannerViewModel {
    func readQR(metadata: String) -> ESLQRData? {
        let words = split(metadata: metadata)
        
        guard words.count <= 4 && words.count >= 2 else {
            return nil
        }
        
        guard startedFromConnect(words[0]) else {
            return nil
        }
        
        if words.count == 2 {
            return decodeWords(words, addressType: .public, passcode: nil)
        } else if words.count == 3 {
            return decodeWords(words, passcode: nil)
        } else {
            return decodeWords(words)
        }
    }
    
    private func split(metadata: String) -> [String] {
        let words = metadata.split(separator: " ")
        
        var strings = [String]()
        for word in words {
            strings.append(String(word))
        }
        
        return strings
    }
    
    private func startedFromConnect(_ word: String) -> Bool {
        return word == "connect"
    }
    
    private func decodeWords(_ words: [String],
                             addressType: SILBluetoothAddressType,
                             passcode: String?) -> ESLQRData? {
        let btAddress = SILBluetoothAddress(address: words[1], addressType: addressType)
        
        return btAddress.isValid ? ESLQRData(bluetoothAddress: btAddress, passcode: passcode) : nil
    }
    
    private func decodeWords(_ words: [String],
                             passcode: String?) -> ESLQRData? {
        let btAddressType = SILBluetoothAddressType(rawValue: words[2])
        
        guard let btAddressType = btAddressType else {
            return nil
        }
        
        return decodeWords(words, addressType: btAddressType, passcode: passcode)
    }
    
    private func decodeWords(_ words: [String]) -> ESLQRData? {
        let passcode = words[3]
        return decodeWords(words, passcode: passcode)
    }
}
