//
//  SILGattAssignedNumberDropDownInfo.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 30/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGattAssignedNumberDropDownInfo {
    
    enum EntityType {
        case service
        case characteristic
        case iosAvailableDescriptors
    }
    
    var entityType: EntityType
    private let repository: SILGattAssignedNumbersRepository
    private let notAllowedServicesUuids = ["180F", "1805", "180A", "1800", "1801", "181E", "1812"]
    
    init(entityType: EntityType, repository: SILGattAssignedNumbersRepository) {
        self.entityType = entityType
        self.repository = repository
    }
    
    lazy var entities: [SILGattAssignedNumberInfo] = {
        switch entityType {
        case .service:
            return repository.getServices()
                .filter( { !self.notAllowedServicesUuids.contains($0.uuid) })
                .map({ SILGattAssignedNumberInfo(entity: $0) })
        case .characteristic:
            return repository.getCharacteristics().map({ SILGattAssignedNumberInfo(entity: $0) })
        case .iosAvailableDescriptors:
            return repository.getIosDescriptors().map({ SILGattAssignedNumberInfo(entity: $0) })
        }
    }()
    
    var autocompleteValues: [String] {
        return entities.map({ $0.fullName }).sorted()
    }
    
    func isUUID16Right(uuid: String) -> Bool {
        let hexRegex = "[0-9a-f]"
        let uuid16Regex = try! NSRegularExpression(pattern: "^(0x)?\(hexRegex){4}$")
        return checkRegex(regex: uuid16Regex, text: uuid)
    }
    
    func isUUID128Right(uuid: String) -> Bool {
        let hexRegex = "[0-9a-f]"
        let uuid128Regex = try! NSRegularExpression(pattern: "\(hexRegex){8}-\(hexRegex){4}-\(hexRegex){4}-\(hexRegex){4}-\(hexRegex){12}")
        return checkRegex(regex: uuid128Regex, text: uuid)
    }
    
    private func checkRegex(regex: NSRegularExpression, text: String) -> Bool {
        let lowercaseText = text.lowercased()
        
        let textRange = NSRange(location: 0, length: lowercaseText.utf16.count)
        
        if regex.firstMatch(in: lowercaseText, options: [], range: textRange) != nil {
            return true
        } else {
            let entity = entities.first { entityInfo in
                return entityInfo.fullName.lowercased() == lowercaseText
            }
            return entity != nil
        }
    }
    
    func isServiceNameRight(name: String) -> Bool {
        let entityInfo = entities.first { info in
            return info.name == name
        }
        return entityInfo != nil
    }
    
    func uuidTextField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var strText = textField.text
        // Allow deleting
        if range.length > 0 && string.isEmpty {
            // Remove also character before hyphen
            if strText?.last == "-" {
                strText?.removeLast()
                textField.text = strText
            }
            return true
        }
        // All characters entered
        if range.location == 36 {
            return false
        }
        
        if strText == nil {
            strText = ""
        }
        // Paste and write only hexString
        var replaceString = SILGattAssignedNumberDropDownInfo.onlyHexString(string)
        // Auto-add hyphen before appending 8, 12, 16 and 20 hex char
        strText = strText?.replacingOccurrences(of: "-", with: "")
        if strText!.count > 1 && [8, 12, 16, 20].contains(strText!.count + 1) && replaceString != "" {
            replaceString.append("-")
         }
        textField.text = "\(textField.text!)\(replaceString)"
        if !replaceString.isEmpty {
            textField.sendActions(for: .editingChanged)
        }
        return false
    }
    
    class func onlyHexString(_ string: String) -> String {
        let hexChars = CharacterSet(charactersIn: "0123456789abcdef")
        return String(string.unicodeScalars.filter { hexChars.contains($0) })
    }
}
