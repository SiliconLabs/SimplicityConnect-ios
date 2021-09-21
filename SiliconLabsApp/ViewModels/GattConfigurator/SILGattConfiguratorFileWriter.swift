//
//  SILGattConfiguratorFileWriter.swift
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 24/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGattConfiguratorFileWriter : NSObject {
    fileprivate var fileHandle: FileHandle?
    
    override init() {
        super.init()
    }
    
    func getFileUrl(filePath: String) -> URL {
        return URL(fileURLWithPath: filePath)
    }
    
    func clearExportDir() {
        let fileManager = FileManager.default
        
        do {
            let fileNames = try fileManager.contentsOfDirectory(atPath: exportDirPath)
            for fileName in fileNames {
                let filePath = (exportDirPath as NSString).appendingPathComponent(fileName)
                try fileManager.removeItem(atPath: filePath)
            }
        } catch {
            print("Could not clear dictionary: \(error)")
        }
    }
    
    func getFilePath(withName name: String) -> String {
        return (self.exportDirPath as NSString).appendingPathComponent(name).appending(".xml")
    }
    
    private var exportDirPath: String {
        let documentDirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let exportDir = (documentDirPath as NSString).appendingPathComponent("SILGattConfiguratorExport")
        return exportDir
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
    
    func fileExists(atPath filePath: String) -> Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir)
        return (exists && !isDir.boolValue)
    }
    
    func createEmptyFile(atPath filePath: String) -> Bool {
        let fileManager = FileManager.default
        
        if !directoryExists(atPath: exportDirPath) {
            do {
                try FileManager.default.createDirectory(atPath: exportDirPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                debugPrint("Error when creating a directory \(error.localizedDescription)")
                return false
            }
        }
        
        // Check Log directory existance again
        guard directoryExists(atPath: exportDirPath) else {
            debugPrint("Directory \(exportDirPath) doesn't exists!")
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
    
    func addSkipBackupAttributeToItem(filePath: String)
    {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: filePath) {
            return
        }
        
        var url = URL(fileURLWithPath: filePath)
        url.setTemporaryResourceValue(true, forKey: .isExcludedFromBackupKey)
    }
    
}
