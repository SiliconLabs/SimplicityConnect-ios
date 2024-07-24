//
//  DDLogFileInfo+Ext.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 01/07/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import Foundation
import CocoaLumberjack

private let sizeDivisor = 1024.0
private let suffixes = ["KiB", "MiB", "GiB", "TiB"]
private let unknown = "Unknown"
private let dateFormat = "yyyy-MM-dd HH:mm:ss"

extension DDLogFileInfo {
    var formattedFileSize: String {
        get {
            var size: Double = Double(fileSize) / sizeDivisor
            var suffixIndex = 0
            while size >= sizeDivisor {
                size = size / sizeDivisor
                suffixIndex = suffixIndex + 1
            }
            
            let formattedSize =  String(format: "%3.2f", size)
            return "\(formattedSize) \(suffixes[suffixIndex])"
        }
    }
    
    var localCreationDateString: String {
        get {
            guard let creationDate = creationDate else {
                return unknown
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = dateFormat
            dateFormatter.timeZone = TimeZone.current
            return dateFormatter.string(from: creationDate)
        }
    }
    
    var localLastModificationDateString: String {
        get {
            guard let modificationDate = modificationDate else {
                return unknown
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = dateFormat
            dateFormatter.timeZone = TimeZone.current
            return dateFormatter.string(from: modificationDate)
        }
    }
}
