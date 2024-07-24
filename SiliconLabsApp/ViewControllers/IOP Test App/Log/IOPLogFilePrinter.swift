//
//  IOPLogFilePrinter.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 01/07/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit

class IOPLogFilePrinter: NSObject {
    fileprivate var fileHandle: FileHandle?
    private var timestamp: Date
    private var deviceName: String
    
    var getFileUrl: URL {
        return URL(fileURLWithPath: getFilePathOfExistingFile())
    }
    
    var getFilePath: String {
        return (IOPLogFilePrinter.logDirPath as NSString).appendingPathComponent(getLogFileName)
    }
    
    private var getLogFileName: String {
        let nowString = longStyleDateFormatter().string(from: timestamp)
        return String(format: "%@_%@.txt", deviceName.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: ".", with: "_"), nowString.replacingOccurrences(of: " ", with: "_"))
    }
    
    private static var logDirPath: String {
        let documentDirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let logDir = (documentDirPath as NSString).appendingPathComponent("TestSILOG")
        return logDir
    }
    
    init(timestamp: Date, deviceName: String) {
        self.timestamp = timestamp
        self.deviceName = deviceName
    }
    
    class func clearLogDir() {
        let fileManager = FileManager.default
        
        do {
            let fileNames = try fileManager.contentsOfDirectory(atPath: logDirPath)
            for fileName in fileNames {
                let filePath = (logDirPath as NSString).appendingPathComponent(fileName)
                try fileManager.removeItem(atPath: filePath)
            }
        } catch {
            print("Could not clear dictionary: \(error)")
        }
    }
    
    func createEmptyFile(atPath filePath: String) -> Bool {
        guard prepareDictionary() else {
            return false
        }
        
        guard clearExisitingFile(filePath: filePath) else {
            return false
        }

        let success = FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
        guard success else {
            debugPrint("File didn't created.")
            return false
        }
        
        addSkipBackupAttributeToItem(filePath: filePath)
        
        return true
    }
    
    private func prepareDictionary() -> Bool {
        if !directoryExists(atPath: IOPLogFilePrinter.logDirPath) {
            do {
                try FileManager.default.createDirectory(atPath: IOPLogFilePrinter.logDirPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                debugPrint("Error when creating a directory \(error.localizedDescription)")
                return false
            }
        }

        guard directoryExists(atPath: IOPLogFilePrinter.logDirPath) else {
            debugPrint("Directory \(IOPLogFilePrinter.logDirPath) doesn't exists!")
            return false
        }
        
        return true
    }
    
    private func clearExisitingFile(filePath: String) -> Bool {
        if fileExists(atPath: filePath) {
            do {
                debugPrint("File at path \(filePath) already exists.")
                try FileManager.default.removeItem(atPath: filePath)
            }
            catch let error {
                debugPrint("Error when removing a file \(error.localizedDescription)")
                return false
            }
        }

        return true
    }

    func openFile(filePath: String) -> Bool {
        if !fileExists(atPath: filePath) && !createEmptyFile(atPath: filePath) {
            return false
        }
        
        fileHandle = FileHandle(forWritingAtPath: filePath)
        return (fileHandle != nil)
    }
    
    func append(text: String) -> Bool {
        if fileHandle == nil {
            return false
        }
        
        guard let data = text.data(using: .utf8) else {
            return false
        }
        
        fileHandle?.seekToEndOfFile()
        fileHandle?.write(data)
        return true
    }
    
    func closeFile() {
        fileHandle?.closeFile()
    }
    
    private func getFilePathOfExistingFile() -> String {
        do {
            let fileNames: [String] = try FileManager.default.contentsOfDirectory(atPath: IOPLogFilePrinter.logDirPath)
            if fileNames.count == 1, let fileName =  fileNames.first {
                return (IOPLogFilePrinter.logDirPath as NSString).appendingPathComponent(fileName)
            } else {
                return self.getFilePath
            }
        } catch {
            return ""
        }
    }
    
    private func longStyleDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatString.fileNameDateTime.formatString
        return dateFormatter
    }
        
    private func directoryExists(atPath dirPath: String) -> Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: dirPath, isDirectory: &isDir)
        return (exists && isDir.boolValue)
    }
    
    private func fileExists(atPath dirPath: String) -> Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: dirPath, isDirectory: &isDir)
        return (exists && !isDir.boolValue)
    }
    
    private func addSkipBackupAttributeToItem(filePath: String) {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: filePath) {
            return
        }
        
        var url = URL(fileURLWithPath: filePath)
        url.setTemporaryResourceValue(true, forKey: .isExcludedFromBackupKey)
    }
}
