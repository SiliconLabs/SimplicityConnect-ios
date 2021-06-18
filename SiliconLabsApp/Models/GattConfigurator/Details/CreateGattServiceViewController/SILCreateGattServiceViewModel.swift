//
//  SILCreateGattServiceViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 16/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILCreateGattServiceViewModelDelegate: class {
    func clearTextFields()
    func updateServiceTypePicker(type: String)
    func updateServiceNameTextField(name: String?)
    func updateServiceUUIDField(uuid: String?)
}

protocol SILCreateGattServiceViewModelType : class {
    var delegate: SILCreateGattServiceViewModelDelegate? { get set }
    var autocompleteValues: [String] { get }
    var isClearButtonEnabled: SILObservable<Bool> { get set }
    var isSaveButtonEnabled: SILObservable<Bool> { get set }
    init(wireframe: SILGattConfiguratorDetailsWireframeType, repository: SILGattAssignedNumbersRepository, service: SILGattConfigurationServiceEntity?, onSave: @escaping (SILGattConfigurationServiceEntity) -> ())
    func updateView()
    func update(serviceName: String?)
    func update(serviceUUID: String?)
    func update(serviceIsPrimary: Bool)
    func toggleMandatoryRequirementsSwitch(isOn: Bool)
    func openLink()
    func onClear()
    func onCancel()
    func onSave()
}

class SILCreateGattServiceViewModel {
    private let wireframe: SILGattConfiguratorDetailsWireframeType
    private let onSaveCallback: (SILGattConfigurationServiceEntity) -> ()
    private lazy var serviceMandatoryRequirementsSupplier = SILServiceMandatoryRequirementsSupplier()
    
    private var serviceName: String = ""
    private var serviceUUID: String = ""
    private var serviceIsPrimary: Bool = true {
        didSet {
            viewDelegate?.updateServiceTypePicker(type: serviceType)
        }
    }
    private var serviceType: String {
        get {
            return serviceIsPrimary ? "Primary Service" : "Secondary Service"
        }
    }
    
    let descriptionText = """
Please insert your service name and UUID.
128-bit UUIDs will be automatically formatted as they are entered. Example:
030a590b-0e23-4482-8567-8434046b5a25

A full list of 16-bit service UUIDs is available from the Bluetooth SIG.
"""
    let linkTitle = "Bluetooth SIG"
    let linkUrl = "https://www.bluetooth.com/specifications/assigned-numbers/"
    
    weak var viewDelegate: SILCreateGattServiceViewModelDelegate?

    
    private let servicesDropDownInfo: SILGattAssignedNumberDropDownInfo
    
    var autocompleteValues: [String] {
        return servicesDropDownInfo.autocompleteValues
    }
    
    var isClearButtonEnabled: SILObservable<Bool> = SILObservable(initialValue: false)
    var isSaveButtonEnabled: SILObservable<Bool> = SILObservable(initialValue: false)
    var isSelected16BitService: SILObservable<Bool> = SILObservable(initialValue: false)
    
    var shouldAddMandatoryServiceRequirements: Bool = false
    
    init(wireframe: SILGattConfiguratorDetailsWireframeType, repository: SILGattAssignedNumbersRepository, onSave: @escaping (SILGattConfigurationServiceEntity) -> ()) {
        self.wireframe = wireframe
        self.servicesDropDownInfo = SILGattAssignedNumberDropDownInfo(entityType: .service, repository: repository)
        self.onSaveCallback = onSave
    }
    
    func updateView() {
        viewDelegate?.updateServiceNameTextField(name: serviceName)
        viewDelegate?.updateServiceUUIDField(uuid: serviceUUID)
        viewDelegate?.updateServiceTypePicker(type: serviceType)
    }
    
    func update(serviceName: String?) {
        self.serviceName = serviceName ?? ""
        
        enableButtonsIfNeeded()
    }
    
    func update(serviceUUID: String?) {
        self.serviceUUID = serviceUUID ?? ""
        
        enableButtonsIfNeeded()
    }
    
    func update(serviceIsPrimary: Bool) {
        self.serviceIsPrimary = serviceIsPrimary
    }
    
    private func enableButtonsIfNeeded() {
        isClearButtonEnabled.value = (self.serviceName.count > 0 || self.serviceUUID.count > 0)
        isSaveButtonEnabled.value = checkIsSavePossible()
        isSelected16BitService.value = checkIfIsUUID16Right()
    }
    
    private func checkIsSavePossible() -> Bool {
        let isUUID128Right = servicesDropDownInfo.isUUID128Right(uuid: serviceUUID)
        let isUUID16Right = checkIfIsUUID16Right()
        return isUUID128Right || isUUID16Right
    }
    
    private func checkIfIsUUID16Right() -> Bool {
        return servicesDropDownInfo.isUUID16Right(uuid: serviceUUID) && servicesDropDownInfo.isServiceNameRight(name: serviceName)
    }
    
    func toggleMandatoryRequirementsCheckBox(isChecked: Bool) {
        debugPrint("mandatory requirement", isChecked)
        shouldAddMandatoryServiceRequirements = isChecked
        if isChecked {
            serviceIsPrimary = isChecked
        }
    }
    
    func openLink() {
        wireframe.open(url: linkUrl)
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
        save(gattService: SILGattConfigurationServiceEntity())
        wireframe.dismissPopover()
    }
    
    private func save(gattService: SILGattConfigurationServiceEntity) {
        gattService.name = serviceName
        gattService.cbuuidString = serviceUUID.hasPrefix("0x") ? String(serviceUUID.dropFirst(2)) : serviceUUID
        gattService.isPrimary = serviceIsPrimary
        addMandatoryRequirementsIfNeeded(gattService: gattService)
        onSaveCallback(gattService)
    }
    
    private func addMandatoryRequirementsIfNeeded(gattService: SILGattConfigurationServiceEntity) {
        if shouldAddMandatoryServiceRequirements {
            for requiredCharacteristic in serviceMandatoryRequirementsSupplier.getMandatoryCharacteristics(serviceUuid: self.serviceUUID) {
                gattService.characteristics.append(requiredCharacteristic)
            }
        }
    }
    
    func uuidTextField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return servicesDropDownInfo.uuidTextField(textField, shouldChangeCharactersIn: range, replacementString: string)
    }
}

extension SILCreateGattServiceViewModel: SILDropDownViewControllerSelectDelegate {
    func dropDownDidSelect(value: String) {
        let service = servicesDropDownInfo.entities.first { serviceInfo in
            return serviceInfo.fullName.lowercased() == value.lowercased()
        }
        if let serviceInfo = service {
            viewDelegate?.updateServiceNameTextField(name: serviceInfo.name)
            viewDelegate?.updateServiceUUIDField(uuid: serviceInfo.uuid)
        } else {
            return
        }
    }
}
