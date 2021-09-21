//
//  SILCreateGattDescriptorViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 29/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILCreateGattDescriptorViewModelDelegate: class {
    func clearTextFields()
    func updateServiceNameTextField(name: String?)
    func updateServiceUUIDField(uuid: String?)
    func updateDescriptorInitialTextTextField(value: String?)
    func updateDescriptorInitialHexTextField(value: String?)
}

class SILCreateGattDescriptorViewModel {
    private var descriptor: SILGattConfigurationDescriptorEntity?
    private let wireframe: SILGattConfiguratorDetailsWireframe
    private let onSaveCallback: (SILGattConfigurationDescriptorEntity) -> ()
    
    enum DescriptorType: Equatable {
        case uuidCharacteristicPresentationFormat
        case uuidCharacteristicUserDescription
        case uuid128bit(SILGattConfigurationValueType)
    }
    
    private var descriptorType: DescriptorType = .uuid128bit(.text) {
        didSet {
            descriptorTypeObservable.value = descriptorType
            if case DescriptorType.uuid128bit(_) = descriptorType {
                viewDelegate?.updateServiceNameTextField(name: descriptorName)
            }
        }
    }
    
    private var descriptorName: String = ""
    private var descriptorUUID: String = ""
    private var descriptorInitialValue: String = ""
    private var descriptorInitialValueType: SILGattConfigurationValueType = .text {
        didSet {
            descriptorInitialValue = ""
            viewDelegate?.updateDescriptorInitialHexTextField(value: "")
            viewDelegate?.updateDescriptorInitialTextTextField(value: "")
        }
    }
    
    private let descriptorDropDownInfo: SILGattAssignedNumberDropDownInfo
    
    var autocompleteValues: [String] {
        return descriptorDropDownInfo.autocompleteValues
    }
    
    weak var viewDelegate: SILCreateGattDescriptorViewModelDelegate?
    
    var isClearButtonEnabled: SILObservable<Bool> = SILObservable(initialValue: false)
    var isSaveButtonEnabled: SILObservable<Bool> = SILObservable(initialValue: false)
    var descriptorTypeObservable: SILObservable<DescriptorType> = SILObservable(initialValue: .uuid128bit(.text))
    
    var isEditing: Bool

    init(wireframe: SILGattConfiguratorDetailsWireframe, repository: SILGattAssignedNumbersRepository, descriptor: SILGattConfigurationDescriptorEntity? = nil, onSave: @escaping (SILGattConfigurationDescriptorEntity) -> ()) {
        self.wireframe = wireframe
        self.descriptorDropDownInfo = SILGattAssignedNumberDropDownInfo(entityType: .iosAvailableDescriptors, repository: repository)
        self.onSaveCallback = onSave
        self.isEditing = descriptor != nil
        self.descriptorType = .uuid128bit(.text)
        if let descriptor = descriptor {
            self.descriptor = descriptor
            self.descriptorName = descriptor.name ?? ""
            self.descriptorUUID = descriptor.cbuuidString.count == 4 ? "0x\(descriptor.cbuuidString)" : descriptor.cbuuidString
            self.descriptorInitialValue = descriptor.initialValue ?? ""
            self.descriptorInitialValueType = descriptor.initialValueType
            self.descriptorType = getDescriptorTypeFromCbuuidString(cbuuidString: descriptor.cbuuidString, initialValueType: descriptor.initialValueType)
        }
    }
    
    func updateView() {
        viewDelegate?.updateServiceNameTextField(name: descriptorName)
        viewDelegate?.updateServiceUUIDField(uuid: descriptorUUID)
        if descriptorInitialValueType == .hex {
            viewDelegate?.updateDescriptorInitialHexTextField(value: descriptorInitialValue)
        } else if descriptorInitialValueType == .text {
            viewDelegate?.updateDescriptorInitialTextTextField(value: descriptorInitialValue)
        }
    }
    
    func update(descriptorName: String?) {
        self.descriptorName = descriptorName ?? ""
        
        enableButtonsIfNeeded()
    }
    
    func update(descriptorUUID: String?) {
        self.descriptorUUID = descriptorUUID ?? ""
        
        self.descriptorType = getDescriptorTypeFromCbuuidString(cbuuidString: self.descriptorUUID, initialValueType: self.descriptorInitialValueType)
        
        enableButtonsIfNeeded()
    }
    
    func update(descriptorInitialValueType: SILGattConfigurationValueType) {
        self.descriptorInitialValueType = descriptorInitialValueType
        self.descriptorType = .uuid128bit(descriptorInitialValueType)
        
        enableButtonsIfNeeded()
    }
    
    func update(descriptorInitialValue: String?) {
        self.descriptorInitialValue = descriptorInitialValue ?? ""
        
        enableButtonsIfNeeded()
    }
    
    private func enableButtonsIfNeeded() {
        isClearButtonEnabled.value = (self.descriptorName.count > 0 || self.descriptorUUID.count > 0 || self.descriptorInitialValue.count > 0)
        isSaveButtonEnabled.value = checkIsSavePossible()
    }
    
    private func checkIsSavePossible() -> Bool {
        let isUUID16Right = descriptorDropDownInfo.isUUID16Right(uuid: descriptorUUID) && descriptorDropDownInfo.isServiceNameRight(name: descriptorName)
        let isUUID128Right = descriptorDropDownInfo.isUUID128Right(uuid: descriptorUUID)
        let isUUIDRight = isUUID16Right || isUUID128Right
        return isUUIDRight && isInitialValueRight()
    }
    
    func onClear() {
        viewDelegate?.clearTextFields()
        self.descriptorType = .uuid128bit(self.descriptorInitialValueType)
    }
    
    func onCancel() {
        wireframe.dismissPopover()
    }
    
    func onSave() {
        guard checkIsSavePossible() else {
            return
        }
        if let descriptor = self.descriptor {
            save(gattDescriptor: SILGattConfigurationDescriptorEntity(value: descriptor))
        } else {
            save(gattDescriptor: SILGattConfigurationDescriptorEntity())
        }
        wireframe.dismissPopover()
    }
    
    private func save(gattDescriptor: SILGattConfigurationDescriptorEntity) {
        gattDescriptor.name = descriptorName
        gattDescriptor.cbuuidString = descriptorUUID.hasPrefix("0x") ? String(descriptorUUID.dropFirst(2)) : descriptorUUID
        gattDescriptor.initialValueType = descriptorInitialValueType
        gattDescriptor.initialValue = descriptorInitialValueType != .none ? descriptorInitialValue : nil
        gattDescriptor.properties = [SILGattConfigurationProperty(type: .read, permission: .none), SILGattConfigurationProperty(type: .write, permission: .none)]
        onSaveCallback(gattDescriptor)
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
        switch descriptorType {
        case .uuid128bit(let valueType):
            switch valueType {
            case .hex:
                return checkHexValueString(descriptorInitialValue, isPresentationFormatValueTypeRequired: false)
            case .text:
                return descriptorInitialValue.count > 0
            default:
                return false
            }
        case .uuidCharacteristicPresentationFormat:
            return checkHexValueString(descriptorInitialValue, isPresentationFormatValueTypeRequired: true)
        case .uuidCharacteristicUserDescription:
            return descriptorInitialValue.count > 0
        }
    }
    
    private func checkHexValueString(_ string: String, isPresentationFormatValueTypeRequired: Bool) -> Bool {
        let hexRegex = "[0-9a-f]"
        let pattern = isPresentationFormatValueTypeRequired ? "^(\(hexRegex){2}){7}$" : "^(\(hexRegex){2})+$"
        return string.range(of: pattern, options: .regularExpression) != nil
    }
    
    private func getDescriptorTypeFromCbuuidString(cbuuidString: String, initialValueType: SILGattConfigurationValueType = .text) -> DescriptorType {
        let cbuuidString = cbuuidString.hasPrefix("0x") ? String(cbuuidString.dropFirst(2)) : cbuuidString
        if cbuuidString == "2901" {
            return .uuidCharacteristicUserDescription
        } else if cbuuidString == "2904" {
            return .uuidCharacteristicPresentationFormat
        } else {
            return .uuid128bit(initialValueType)
        }
    }
    
    // Text fields delegates
    
    func uuidTextField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return descriptorDropDownInfo.uuidTextField(textField, shouldChangeCharactersIn: range, replacementString: string)
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

extension SILCreateGattDescriptorViewModel: SILDropDownViewControllerSelectDelegate {
    func dropDownDidSelect(value: String) {
        let characteristic = descriptorDropDownInfo.entities.first { characteristicInfo in
            return characteristicInfo.fullName.lowercased() == value.lowercased()
        }
        if let characteristicInfo = characteristic {
            viewDelegate?.updateServiceNameTextField(name: characteristicInfo.name)
            viewDelegate?.updateServiceUUIDField(uuid: characteristicInfo.uuid)
            if characteristicInfo.prefixUUID == "0x2901" {
                descriptorType = .uuidCharacteristicUserDescription
                descriptorInitialValueType = .text
            } else if characteristicInfo.prefixUUID == "0x2904" {
                descriptorType = .uuidCharacteristicPresentationFormat
                descriptorInitialValueType = .hex
            }
        } else {
            return
        }
    }
}
