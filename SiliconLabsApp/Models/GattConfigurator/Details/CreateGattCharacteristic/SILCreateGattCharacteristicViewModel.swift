//
//  SILCreateGattCharacteristicViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 29/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILCreateGattCharacteristicViewModelDelegate: class {
    func clearTextFields()
    func updateTypeValuePicker(type: SILGattConfigurationValueType)
    func updateServiceNameTextField(name: String?)
    func updateServiceUUIDField(uuid: String?)
    func updateCharacteristicInitialTextTextField(value: String?)
    func updateCharacteristicInitialHexTextField(value: String?)
}

class SILCreateGattCharacteristicViewModel {
    private var characteristic: SILGattConfigurationCharacteristicEntity?
    private let wireframe: SILGattConfiguratorDetailsWireframe
    private let onSaveCallback: (SILGattConfigurationCharacteristicEntity) -> ()
    
    private var characteristicName: String = ""
    private var characteristicUUID: String = ""
    private var charactertisticProperties: [SILGattConfigurationProperty] = []
    private var characteristicInitialValue: String = ""
    private var characteristicInitialValueType: SILGattConfigurationValueType = .none {
        didSet {
            viewDelegate?.updateTypeValuePicker(type: characteristicInitialValueType)
        }
    }
    
    enum PermissionType: CaseIterable {
        case read
        case write
        case notifyIndicate
    }
    
    var characteristicPermissionsMap: [PermissionType: SILGattConfigurationAttributePermission] = [.read: .none, .write: .none, .notifyIndicate: .none]

    var propertyMap: [SILGattConfigurationPropertyType: SILObservable<Bool>] = [
        .read: SILObservable(initialValue: false),
        .write: SILObservable(initialValue: false),
        .writeWithoutResponse: SILObservable(initialValue: false),
        .notify: SILObservable(initialValue: false),
        .indicate: SILObservable(initialValue: false)
    ]
    
    private let characteristicDropDownInfo: SILGattAssignedNumberDropDownInfo
    
    var autocompleteValues: [String] {
        return characteristicDropDownInfo.autocompleteValues
    }
    
    weak var viewDelegate: SILCreateGattCharacteristicViewModelDelegate?
    
    var isClearButtonEnabled: SILObservable<Bool> = SILObservable(initialValue: false)
    var isSaveButtonEnabled: SILObservable<Bool> = SILObservable(initialValue: false)
    var isNotifyIndicateCheckboxEnabled: Bool {
        get {
            return propertyMap[.notify]!.value || propertyMap[.indicate]!.value
        }
    }
    var isWriteCheckboxEnabled: Bool {
        get {
            return propertyMap[.write]!.value || propertyMap[.writeWithoutResponse]!.value
        }
    }
    
    var isEditing: Bool

    init(wireframe: SILGattConfiguratorDetailsWireframe, repository: SILGattAssignedNumbersRepository, characteristic: SILGattConfigurationCharacteristicEntity? = nil, onSave: @escaping (SILGattConfigurationCharacteristicEntity) -> ()) {
        self.wireframe = wireframe
        self.characteristicDropDownInfo = SILGattAssignedNumberDropDownInfo(entityType: .characteristic, repository: repository)
        self.onSaveCallback = onSave
        self.isEditing = characteristic != nil
        if let characteristic = characteristic {
            self.characteristic = characteristic
            self.characteristicName = characteristic.name ?? ""
            self.characteristicUUID = characteristic.cbuuidString.count == 4 ? "0x\(characteristic.cbuuidString)" : characteristic.cbuuidString
            self.charactertisticProperties = characteristic.properties
            updatePropertiesAndPermissions()
            self.characteristicInitialValue = characteristic.initialValue ?? ""
            self.characteristicInitialValueType = characteristic.initialValueType
        } else {
            propertyMap[.read]!.value = true
        }
    }
    
    func updateView() {
        viewDelegate?.updateServiceNameTextField(name: characteristicName)
        viewDelegate?.updateServiceUUIDField(uuid: characteristicUUID)
        viewDelegate?.updateTypeValuePicker(type: characteristicInitialValueType)
        if characteristicInitialValueType == .hex {
            viewDelegate?.updateCharacteristicInitialHexTextField(value: characteristicInitialValue)
        } else if characteristicInitialValueType == .text {
            viewDelegate?.updateCharacteristicInitialTextTextField(value: characteristicInitialValue)
        }
    }
    
    private func updatePropertiesAndPermissions() {
        for property in charactertisticProperties {
            propertyMap[property.type]?.value = true
            switch property.type {
            case .read:
                characteristicPermissionsMap[.read] = property.permission
            case .write:
                characteristicPermissionsMap[.write] = property.permission
            case .writeWithoutResponse:
                characteristicPermissionsMap[.write] = property.permission
            case .notify:
                characteristicPermissionsMap[.notifyIndicate] = property.permission
            case .indicate:
                characteristicPermissionsMap[.notifyIndicate] = property.permission
            }
        }
    }
    
    func update(characteristicName: String?) {
        self.characteristicName = characteristicName ?? ""
        
        enableButtonsIfNeeded()
    }
    
    func update(characteristicUUID: String?) {
        self.characteristicUUID = characteristicUUID ?? ""
        
        enableButtonsIfNeeded()
    }
    
    func update(property: SILGattConfigurationPropertyType, isSet: Bool) {
        propertyMap[property]?.value = isSet
        
        enableButtonsIfNeeded()
    }
    
    func update(permission: SILGattConfigurationAttributePermission, withType type: PermissionType) {
        characteristicPermissionsMap[type] = permission
    }
    
    func update(characteristicInitialValueType: SILGattConfigurationValueType) {
        self.characteristicInitialValueType = characteristicInitialValueType
        
        enableButtonsIfNeeded()
    }
    
    func update(characteristicInitialValue: String?) {
        self.characteristicInitialValue = characteristicInitialValue ?? ""
        
        enableButtonsIfNeeded()
    }
    
    private func enableButtonsIfNeeded() {
        isClearButtonEnabled.value = (self.characteristicName.count > 0 || self.characteristicUUID.count > 0 || self.characteristicInitialValue.count > 0)
        isSaveButtonEnabled.value = checkIsSavePossible()
    }
    
    private func checkIsSavePossible() -> Bool {
        let isUUID128Right = characteristicDropDownInfo.isUUID128Right(uuid: characteristicUUID)
        let isUUID16Right = characteristicDropDownInfo.isUUID16Right(uuid: characteristicUUID) && characteristicDropDownInfo.isServiceNameRight(name: characteristicName)
        let isUUIDRight = isUUID128Right || isUUID16Right
        let isAnyPropertySet = propertyMap.reduce(false, { $0 || $1.value.value })
        return isAnyPropertySet && isUUIDRight && isInitialValueRight()
    }
    
    func onClear() {
        viewDelegate?.clearTextFields()
    }
    
    func onCancel() {
        wireframe.dismissPopover()
    }
    
    func onSave() {
        guard checkIsSavePossible() else {
            return
        }
        if let characteristic = self.characteristic {
            save(gattCharacteristic: SILGattConfigurationCharacteristicEntity(value: characteristic))
        } else {
            save(gattCharacteristic: SILGattConfigurationCharacteristicEntity())
        }
        wireframe.dismissPopover()
    }
    
    private func save(gattCharacteristic: SILGattConfigurationCharacteristicEntity) {
        gattCharacteristic.name = characteristicName
        gattCharacteristic.cbuuidString = characteristicUUID.hasPrefix("0x") ? String(characteristicUUID.dropFirst(2)) : characteristicUUID
        gattCharacteristic.initialValueType = characteristicInitialValueType
        gattCharacteristic.initialValue = characteristicInitialValueType != .none ? characteristicInitialValue : nil
        gattCharacteristic.properties = buildProperties()
        SILDefaultDescriptorsHelper.addDefaultIosDescriptorsIfNeeded(forCharacteristic: gattCharacteristic)
        onSaveCallback(gattCharacteristic)
    }
    
    func buildProperties() -> [SILGattConfigurationProperty] {
        var properties: [SILGattConfigurationProperty] = []
        for (property, isSetObservable) in propertyMap {
            if isSetObservable.value {
                let permissionType = getPermissionType(forPropertyType: property)
                properties.append(SILGattConfigurationProperty(type: property, permission: characteristicPermissionsMap[permissionType]!))
            }
        }
        debugPrint(properties)
        return properties
    }
    
    private func getPermissionType(forPropertyType propertyType: SILGattConfigurationPropertyType) -> PermissionType {
        switch propertyType {
        case .indicate, .notify:
            return .notifyIndicate
        case .read:
            return .read
        case .write, .writeWithoutResponse:
            return .write
        }
    }
    
    func getDescription(ofTypeValue characteristicInitialValueType: SILGattConfigurationValueType) -> String {
        switch characteristicInitialValueType {
        case .none:
            return "Empty"
        case .text:
            return "Text (ascii)"
        case .hex:
            return "Hex"
        }
    }
    
    private func isInitialValueRight() -> Bool {
        switch characteristicInitialValueType {
        case .none:
            return true
        case .text:
            return characteristicInitialValue.count > 0
        case .hex:
            return checkHexValueString(characteristicInitialValue)
        }
    }
    
    private func checkHexValueString(_ string: String) -> Bool {
        let hexRegex = "[0-9a-f]"
        let pattern = "^(\(hexRegex){2})+$"
        return string.range(of: pattern, options: .regularExpression) != nil
    }
    
    // Text fields delegates
    
    func uuidTextField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return characteristicDropDownInfo.uuidTextField(textField, shouldChangeCharactersIn: range, replacementString: string)
    }
    
    func initialHexValueTextField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var strText = textField.text
        // Allow deleting
        if range.length > 0 && string.isEmpty {
            return true
        }
        
        if strText == nil {
            strText = ""
        }
        // Paste and write only hexString
        let replaceString = SILGattAssignedNumberDropDownInfo.onlyHexString(string)
        if !replaceString.isEmpty {
            return true
        }
        return false
    }

}

extension SILCreateGattCharacteristicViewModel: SILDropDownViewControllerSelectDelegate {
    func dropDownDidSelect(value: String) {
        let characteristic = characteristicDropDownInfo.entities.first { characteristicInfo in
            return characteristicInfo.fullName.lowercased() == value.lowercased()
        }
        if let characteristicInfo = characteristic {
            viewDelegate?.updateServiceNameTextField(name: characteristicInfo.name)
            viewDelegate?.updateServiceUUIDField(uuid: characteristicInfo.prefixUUID)
        } else {
            return
        }
    }
}
