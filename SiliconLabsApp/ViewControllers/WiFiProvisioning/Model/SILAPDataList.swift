//
//  SILAPDataList.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 25/07/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import Foundation
// MARK: - SILAPDataList
struct SILAPDataList: Codable {
    let count: String
    let scanResults: [ScanResult]

    enum CodingKeys: String, CodingKey {
        case count
        case scanResults = "scan_results"
    }
}

// MARK: - ScanResult
struct ScanResult: Codable {
    let ssid, securityType, networkType, bssid: String
    let channel, rssi: String

    enum CodingKeys: String, CodingKey {
        case ssid
        case securityType = "security_type"
        case networkType = "network_type"
        case bssid, channel, rssi
    }
}
