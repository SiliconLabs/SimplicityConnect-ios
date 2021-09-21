//
//  SILGattConfiguratorDetailsViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 11/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGattConfiguratorDetailsViewModel {
    private let wireframe: SILGattConfiguratorDetailsWireframe
    private let repository: SILGattConfigurationRepository
    private let service: SILGattConfiguratorService
    private var settings: SILGattConfiguratorSettingsType
    private let gattConfiguration: SILGattConfigurationEntity
    
    let gattServicesData: SILObservable<[SILGattConfiguratorServiceCellViewModel]>
    private var gattServices: [SILGattConfigurationServiceEntity] = []
    
    var gattConfigurationName: String
    
    init(wireframe: SILGattConfiguratorDetailsWireframe, service: SILGattConfiguratorService, repository: SILGattConfigurationRepository,
         settings: SILGattConfiguratorSettingsType, gattConfiguration: SILGattConfigurationEntity) {
        self.wireframe = wireframe
        self.repository = repository
        self.service = service
        self.settings = settings
        self.gattConfiguration = gattConfiguration
        self.gattServicesData = SILObservable(initialValue: [])
        self.gattConfigurationName = gattConfiguration.name
        
        self.gattServices = createGattServices(fromGattConfiguration: gattConfiguration)
        
        debugPrint("services number here", gattConfiguration.services.count)
        debugPrint("services number", repository.getServices().count)
        debugPrint("characteristics number", repository.getCharacteristics().count)
        debugPrint("descriptors number", repository.getDescriptors().count)
        buildServicesData()
    }
    
    private func createGattServices(fromGattConfiguration gattConfiguration: SILGattConfigurationEntity) -> [SILGattConfigurationServiceEntity] {
        var gattServices: [SILGattConfigurationServiceEntity] = []
        
        for service in gattConfiguration.services {
            let gattService = SILGattConfigurationServiceEntity(value: service)
            gattService.characteristics.removeAll()
            
            for characteristic in service.characteristics {
                let gattCharacteristic = SILGattConfigurationCharacteristicEntity(value: characteristic)
                gattService.characteristics.append(gattCharacteristic)
                gattCharacteristic.descriptors.removeAll()
                
                for descriptor in characteristic.descriptors {
                    let gattDescriptor = SILGattConfigurationDescriptorEntity(value: descriptor)
                    gattCharacteristic.descriptors.append(gattDescriptor)
                }
            }
            gattServices.append(gattService)
        }
        return gattServices
    }
    
    func backToHome() {
        let popupIsEnabled = !settings.gattConfiguratorNonSaveChangesExitWarning
        if popupIsEnabled && gattConfigurationWasChanged() {
            wireframe.presentNonSaveChangesExitWarningPopup {
                self.save()
            } onNo: {
                self.wireframe.popPage()
            } settingAction: {
                self.settings.gattConfiguratorNonSaveChangesExitWarning = $0
            }
        } else {
            wireframe.popPage()
        }
    }
    
    private func gattConfigurationWasChanged() -> Bool {
        if self.gattConfigurationName != gattConfiguration.name {
            return true
        }
        
        if self.gattServices.count != gattConfiguration.services.count {
            return true
        }
        
        for service in gattConfiguration.services {
            if let serviceToCheck = gattServices.first(where: { $0.uuid == service.uuid }) {
                if !serviceToCheck.isEqualTo(SILGattConfigurationServiceEntity(value: service)) {
                    return true
                }
            } else {
                return true
            }
        }
        return false
    }
    
    func save() {
        let updated = SILGattConfigurationEntity(value: gattConfiguration)
        updated.name = gattConfigurationName
        updateServicesInRepository(configuration: updated)
        repository.update(configuration: updated)
        wireframe.popPage()
    }
    
    private func updateServicesInRepository(configuration: SILGattConfigurationEntity) {
        for gattService in gattServices {
            let _service = gattConfiguration.services.first { service in
                return service.uuid == gattService.uuid
            }
            if let repositoryService = _service {
                removeCharacteristicInRepository(localService: gattService, repositoryService: repositoryService)
                repository.update(service: gattService)
            } else {
                repository.add(service: gattService)
            }
        }
        for gattService in gattConfiguration.services {
            let _service = gattServices.first { service in
                return service.uuid == gattService.uuid
            }
            if _service == nil {
                repository.remove(service: gattService)
            }
        }
        configuration.services.removeAll()
        for gattService in gattServices {
            configuration.services.append(gattService)
        }
    }
    
    private func removeCharacteristicInRepository(localService: SILGattConfigurationServiceEntity, repositoryService: SILGattConfigurationServiceEntity) {
        for gattCharacteristic in repositoryService.characteristics {
            let localCharacteristic = localService.characteristics.first { characteristic in
                return characteristic.uuid == gattCharacteristic.uuid
            }
            if let localCharacteristic = localCharacteristic {
                removeDescriptorInRepository(localCharacteristic: localCharacteristic, repositoryCharacteristic: gattCharacteristic)
            } else {
                repository.remove(characteristic: gattCharacteristic)
            }
        }
    }
    
    private func removeDescriptorInRepository(localCharacteristic: SILGattConfigurationCharacteristicEntity, repositoryCharacteristic: SILGattConfigurationCharacteristicEntity) {
        for gattDescriptor in repositoryCharacteristic.descriptors {
            let localDescriptor = localCharacteristic.descriptors.first { descriptor in
                return descriptor.uuid == gattDescriptor.uuid
            }
            if localDescriptor == nil {
                repository.remove(descriptor: gattDescriptor)
            }
        }
    }
    
    func update(gattConfigurationName: String?) {
        self.gattConfigurationName = gattConfigurationName ?? ""
    }
    
    func buildServicesData() {
        weak var weakSelf = self
        var cellViewModels: [SILGattConfiguratorServiceCellViewModel] = []
        
        for (index, service) in gattServices.enumerated() {
            let serviceModification = ServiceModification(onCopy: {
                weakSelf?.copyService(service)
            }, onDelete: {
                weakSelf?.deleteService(at: index)
            }, onCharacteristicAdd: {
                weakSelf?.addCharacteristic(toServiceAtIndex: index)
            }, onDescriptorAdd: { (characteristicIndex) in
                weakSelf?.addDescriptor(toCharacteristicAtIndex: characteristicIndex, inServiceAtIndex: index)
                debugPrint("add descriptor")
            })
            
            let characteristicModification = EntityModification<SILGattConfigurationCharacteristicEntity>(onCopy: { (characteristic) in
                weakSelf?.copyCharacteristic(characteristic, inServiceAtIndex: index)
            }, onEdit: { (characteristic) in
                weakSelf?.editCharacteristic(characteristic, inServiceAtIndex: index)
            }, onDelete: { (characteristic) in
                weakSelf?.deleteCharacteristic(characteristic, inServiceAtIndex: index)
            })
            
            let descriptorModification = EntityModificationWithIndex<SILGattConfigurationDescriptorEntity>(onCopy: { (descriptor, characteristicIndex) in
                weakSelf?.copyDescriptor(descriptor, inCharacteristicAtIndex: characteristicIndex, inServiceAtIndex: index)
                debugPrint("copy descriptor")
            }, onEdit: { (descriptor, characteristicIndex) in
                weakSelf?.editDescriptor(descriptor, inCharacteristicAtIndex: characteristicIndex, inServiceAtIndex: index)
                debugPrint("edit descriptor")
            }, onDelete: { (descriptor, characteristicIndex) in
                weakSelf?.deleteDescriptor(descriptor, inCharacteristicAtIndex: characteristicIndex, inServiceAtIndex: index)
                debugPrint("delete descriptor")
            })
            
            let cellViewModel = SILGattConfiguratorServiceCellViewModel(service: service,
                                                                        serviceModification: serviceModification,
                                                                        characteristicModification: characteristicModification,
                                                                        descriptorModification: descriptorModification)
            cellViewModels.append(cellViewModel)
        }
        createCharacteristicViewModelsIfNeeded(for: cellViewModels)
        gattServicesData.value = cellViewModels
    }
    
    private func createCharacteristicViewModelsIfNeeded(for newViewModels: [SILGattConfiguratorServiceCellViewModel]) {
        let filteredViewModels = self.gattServicesData.value.filter { viewModel in
            newViewModels.contains(where: { newViewModel in
                viewModel.service.uuid == newViewModel.service.uuid
            })
        }
        
        for newViewModel in newViewModels {
            if let oldViewModel = filteredViewModels.first(where: { $0.service.uuid == newViewModel.service.uuid }),
               oldViewModel.isExpanded {
                newViewModel.changeExpand()
            }
        }
    }
    
    func addService() {
        weak var weakSelf = self
        wireframe.presentCreateGattServicePopup { service in
            weakSelf?.gattServices.append(service)
            weakSelf?.buildServicesData()
        }
    }
    
    private func copyService(_ service: SILGattConfigurationServiceEntity) {
        let copiedService = service.getCopy()
        gattServices.append(copiedService)
        buildServicesData()
    }
    
    private func deleteService(at index: Int) {
        gattServices.remove(at: index)
        buildServicesData()
    }
    
    private func addCharacteristic(toServiceAtIndex index: Int) {
        weak var weakSelf = self
        wireframe.presentCreateGattCharacteristicPopup { characteristic in
            weakSelf?.gattServices[index].characteristics.append(characteristic)
            weakSelf?.buildServicesData()
        }
    }
    
    private func deleteCharacteristic(_ characteristic: SILGattConfigurationCharacteristicEntity, inServiceAtIndex index: Int) {
        let updatedService = gattServices[index]
        if let index = updatedService.characteristics.firstIndex(where: { $0.uuid == characteristic.uuid} ) {
            updatedService.characteristics.remove(at: index)
        }
        buildServicesData()
    }
    
    private func copyCharacteristic(_ characteristic: SILGattConfigurationCharacteristicEntity, inServiceAtIndex index: Int) {
        let updatedService = gattServices[index]
        let copiedCharacteristic = characteristic.getCopy()
        updatedService.characteristics.append(copiedCharacteristic)
        buildServicesData()
    }
    
    private func editCharacteristic(_ characteristic: SILGattConfigurationCharacteristicEntity, inServiceAtIndex index: Int) {
        weak var weakSelf = self
        wireframe.presentEditGattCharacteristicPopup(characteristic: characteristic) { characteristic in
            let updatedService = weakSelf?.gattServices[index]
            if let updatedCharacteristic = updatedService?.characteristics.first(where: { $0.uuid == characteristic.uuid }) {
                updatedCharacteristic.name = characteristic.name
                updatedCharacteristic.cbuuidString = characteristic.cbuuidString
                updatedCharacteristic.properties = characteristic.properties
                updatedCharacteristic.initialValue = characteristic.initialValue
                updatedCharacteristic.initialValueType = characteristic.initialValueType
                updatedCharacteristic.descriptors = characteristic.descriptors
                updatedCharacteristic.fixedVariableLength = characteristic.fixedVariableLength
                updatedCharacteristic._additionalXmlChildren = characteristic._additionalXmlChildren
                updatedCharacteristic._additionalXmlAttributes = characteristic._additionalXmlAttributes
            }
            weakSelf?.buildServicesData()
        }
    }
    
    private func addDescriptor(toCharacteristicAtIndex characteristicIndex: Int, inServiceAtIndex serviceIndex: Int) {
        weak var weakSelf = self
        wireframe.presentCreateGattDescriptorPopup { descriptor in
            weakSelf?.gattServices[serviceIndex].characteristics[characteristicIndex].descriptors.append(descriptor)
            weakSelf?.buildServicesData()
        }
    }
    
    private func deleteDescriptor(_ descriptor: SILGattConfigurationDescriptorEntity, inCharacteristicAtIndex characteristicIndex: Int, inServiceAtIndex serviceIndex: Int) {
        let updatedCharacteristic = gattServices[serviceIndex].characteristics[characteristicIndex]
        if let index = updatedCharacteristic.descriptors.firstIndex(where: { $0.uuid == descriptor.uuid }) {
            updatedCharacteristic.descriptors.remove(at: index)
        }
        buildServicesData()
    }
    
    private func copyDescriptor(_ descriptor: SILGattConfigurationDescriptorEntity, inCharacteristicAtIndex characteristicIndex: Int, inServiceAtIndex serviceIndex: Int) {
        let updatedCharacteristic = gattServices[serviceIndex].characteristics[characteristicIndex]
        let copiedDescriptor = descriptor.getCopy()
        updatedCharacteristic.descriptors.append(copiedDescriptor)
        buildServicesData()
    }
    
    private func editDescriptor(_ descriptor: SILGattConfigurationDescriptorEntity, inCharacteristicAtIndex characteristicIndex: Int, inServiceAtIndex serviceIndex: Int) {
        weak var weakSelf = self
        wireframe.presentEditGattDescriptorPopup(descriptor: descriptor) { descriptor in
            let updatedCharacteristic = weakSelf?.gattServices[serviceIndex].characteristics[characteristicIndex]
            if let updatedDescriptor = updatedCharacteristic?.descriptors.first(where: { $0.uuid == descriptor.uuid }) {
                updatedDescriptor.name = descriptor.name
                updatedDescriptor.cbuuidString = descriptor.cbuuidString
                updatedDescriptor.properties = descriptor.properties
                updatedDescriptor.initialValue = descriptor.initialValue
                updatedDescriptor.initialValueType = descriptor.initialValueType
                updatedDescriptor.fixedVariableLength = descriptor.fixedVariableLength
                updatedDescriptor._additionalXmlChildren = descriptor._additionalXmlChildren
                updatedDescriptor._additionalXmlAttributes = descriptor._additionalXmlAttributes
            }
            weakSelf?.buildServicesData()
        }
    }
}
