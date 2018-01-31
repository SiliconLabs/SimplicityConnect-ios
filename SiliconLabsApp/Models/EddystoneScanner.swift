//
//  EddystoneScanner.swift
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 2/23/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

import Foundation
import Eddystone

@objc protocol EddystoneScannerDelegate: class {
    func eddystoneScanner(_ eddystoneScanner: EddystoneScanner, didFindBeacons beacons: [EddystoneBeacon])
}

final class EddystoneScanner: NSObject, ScannerDelegate {

    weak var delegate: EddystoneScannerDelegate?

    func scanForEddystoneBeacons() {
        Eddystone.Scanner.start(self as ScannerDelegate)
    }

    func stopScanningForEddystoneBeacons() {
        Eddystone.Scanner.stopScan()
    }

    // MARK: - ScannerDelegate

    func eddystoneNearbyDidChange() {
        let generics = Scanner.nearby
        let eddystones = generics.map { generic -> EddystoneBeacon in

            var tlmData: TLMData? = nil

            if let batteryVolts = generic.battery,
                let temperature = generic.temperature,
                let advertisementCount = generic.advertisementCount,
                let onTime = generic.onTime {
                tlmData = TLMData(batteryVolts: batteryVolts,
                                  temperature: temperature,
                                  advertisementCount: advertisementCount,
                                  onTime: onTime)
            }

            return EddystoneBeacon(url: generic.url,
                                   namespace: generic.namespace,
                                   instance: generic.instance,
                                   rssi: Int16(generic.rssi),
                                   txPower: generic.txPower,
                                   tlmData: tlmData)
        }
        self.delegate?.eddystoneScanner(self, didFindBeacons: eddystones)
    }
}
