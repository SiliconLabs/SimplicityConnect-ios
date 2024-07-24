//
//  LogFile.swift
//  ble_mesh-app
//
//  Created by Kamil Czajka on 28/07/2020.
//  Copyright © 2020 Silicon Labs, http://www.silabs.com. All rights reserved.
//

import Foundation
import CocoaLumberjack

struct LogFile {
    var info: DDLogFileInfo
    var url: URL {
        URL(fileURLWithPath: info.filePath)
    }
}
