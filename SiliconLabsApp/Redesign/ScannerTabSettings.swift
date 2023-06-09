//
//  ScannerTabSettings.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 04/01/2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation

@objc class ScannerTabSettings : NSObject {
    @objc static let sharedInstance = ScannerTabSettings()
    @objc var scanningStartedTime : Date = Date()
    @objc var scanningPausedByUser : Bool = false
}
