//
//  EddystoneBeacon.swift
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 2/27/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

import Foundation

final class EddystoneBeacon: NSObject {
    private(set) var url: URL?
    private(set) var namespace: String?
    private(set) var instance: String?
    private(set) var rssi: Int16
    private(set) var txPower: Int
    private(set) var tlmData: TLMData?

    init(url: URL?, namespace: String?, instance: String?, rssi: Int16, txPower: Int, tlmData: TLMData?) {
        self.url = url
        self.namespace = namespace
        self.instance = instance
        self.rssi = rssi
        self.txPower = txPower
        self.tlmData = tlmData
        super.init()
    }

    convenience override init() {
        self.init(url: nil, namespace: nil, instance: nil, rssi: 0, txPower: 0, tlmData: nil)
    }
}
