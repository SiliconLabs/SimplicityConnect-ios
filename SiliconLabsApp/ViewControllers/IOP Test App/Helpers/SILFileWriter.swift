//
//  SILFileWriter.swift
//  BlueGecko
//
//  Created by RAVI KUMAR on 12/12/19.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

import Foundation


import Foundation

class SILFileWriter : NSObject {
    fileprivate var fileHandle: FileHandle?
    
    var timestamp: Date
    var firmware: SILIOPFirmware
    
    override init() {
        firmware = .unknown
        timestamp = Date()
        super.init()
    }
    
    init(firmware: SILIOPFirmware, timestamp: Date) {
        self.firmware = firmware
        self.timestamp = timestamp
    }
    
    var getFileUrl: URL {
        return URL(fileURLWithPath: getFilePathOfExistingFile())
    }
    
    func clearLogDir() {
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
    
    func getFilePathOfExistingFile() -> String {
        do {
            let fileNames: [String] = try FileManager.default.contentsOfDirectory(atPath: self.logDirPath)
            if fileNames.count == 1, let fileName =  fileNames.first {
                return (self.logDirPath as NSString).appendingPathComponent(fileName)
            } else {
                return self.getFilePath
            }
        } catch {
            return ""
        }
    }
    
    private var getLogFileName: String {
        let nowString = longStyleDateFormatter().string(from: timestamp)
        return String(format: "%@_%@_%@.txt", UIDevice.deviceName.replacingOccurrences(of: " ", with: "_"), firmware.rawValue, nowString.replacingOccurrences(of: " ", with: "_"))
    }
    
    var getFilePath: String {
        return  (self.logDirPath as NSString).appendingPathComponent(getLogFileName)
    }
    
    private var logDirPath: String {
        let documentDirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let logDir = (documentDirPath as NSString).appendingPathComponent("SILLog")
        return logDir
    }
    
    fileprivate func longStyleDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatString.fileNameDateTime.formatString
        return dateFormatter
    }
    
    // @notes Create the file if it doesn't exist
    func openFile(filePath: String) -> Bool {
        if !self.fileExists(atPath: filePath) && !self.createEmptyFile(atPath: filePath) {
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
        
    func directoryExists(atPath dirPath: String) -> Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: dirPath, isDirectory: &isDir)
        return (exists && isDir.boolValue)
    }
    
    func fileExists(atPath dirPath: String) -> Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: dirPath, isDirectory: &isDir)
        return (exists && !isDir.boolValue)
    }
    
    func createEmptyFile(atPath filePath: String) -> Bool {
        let fileManager = FileManager.default
        
        if !directoryExists(atPath: logDirPath) {
            do {
                try FileManager.default.createDirectory(atPath: logDirPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                debugPrint("Error when creating a directory \(error.localizedDescription)")
                return false
            }
        }
        
        // Check Log directory existance again
        guard directoryExists(atPath: logDirPath) else {
            debugPrint("Directory \(logDirPath) doesn't exists!")
            return false
        }
        
        if fileExists(atPath: filePath) {
            do {
                debugPrint("File at path \(filePath) already exists.")
                try fileManager.removeItem(atPath: filePath)
            }
            catch let error {
                debugPrint("Error when removing a file \(error.localizedDescription)")
                return false
            }
        }
        
        // Check the file existance again
        guard !fileExists(atPath: filePath) else {
            debugPrint("File still exists at \(filePath)")
            return false
        }
        
        // Create empty file
        let success = fileManager.createFile(atPath: filePath, contents: nil, attributes: nil)
        if !success {
            debugPrint("File didn't created.")
            return false
        }
        
        // Add Skip Backup Attribute
        addSkipBackupAttributeToItem(filePath: filePath)
        
        return true
    }
    
    func addSkipBackupAttributeToItem(filePath:String)
    {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: filePath) {
            return
        }
        
        var url = URL(fileURLWithPath: filePath)
        url.setTemporaryResourceValue(true, forKey: .isExcludedFromBackupKey)
    }
    
}
