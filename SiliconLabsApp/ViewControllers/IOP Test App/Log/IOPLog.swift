//
//  IOPLog.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 01/07/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import Foundation
import CocoaLumberjack


class IOPLog: NSObject {
    @objc func iopLogSwiftFunction(message: String) {
        let fileName = URL(fileURLWithPath: #file).deletingPathExtension().lastPathComponent
        DDLogVerbose("Application: \(fileName): \(message)")
    }
}
