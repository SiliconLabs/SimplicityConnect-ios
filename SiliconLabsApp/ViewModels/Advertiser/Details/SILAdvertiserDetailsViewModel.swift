//
//  SILAdvertiserDetailsViewModel.swift
//  BlueGecko
//
//  Created by Michał Lenart on 29/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILAdvertiserDetailsViewModel {
    private var wireframe: SILAdvertiserDetailsWireframe
    private var repository: SILAdvertisingSetRepository
    private var serviceRepository: SILAdvertisingServiceRepository
    private var service: SILAdvertiserService
    private var settings: SILAdvertiserSettings
    private var advertiser: SILAdvertisingSetEntity
    
    var advertisingSetName: String
    let advertisingData: SILObservable<[SILCellViewModel]>
    let advertisingDataBytesAvailable: SILObservable<Int>
    let scanResponseData: SILObservable<[SILCellViewModel]>
    let scanResponseBytesAvailable: SILObservable<Int>
    private var completeLocalName: String?
    private var completeList16: [String]?
    private var completeList128: [String]?
    private var isCompleteLocalName: Bool
    private var currentState: SILTimeLimitRadioButtonState
    private var isExecutionTime: Bool
    private var executionTime: Double
    private var executionTimeString: String
    
    init(wireframe: SILAdvertiserDetailsWireframe, repository: SILAdvertisingSetRepository, serviceRepository: SILAdvertisingServiceRepository, service: SILAdvertiserService, settings: SILAdvertiserSettings, advertiser: SILAdvertisingSetEntity) {
        self.wireframe = wireframe
        self.repository = repository
        self.serviceRepository = serviceRepository
        self.service = service
        self.settings = settings
        self.advertiser = advertiser
        
        self.advertisingSetName = advertiser.name
        self.completeLocalName = settings.completeLocalName
        self.completeList16 = advertiser.completeList16
        self.completeList128 = advertiser.completeList128
        self.isCompleteLocalName = advertiser.isCompleteLocalName
        self.currentState = advertiser.isExecutionTime ? .withLimit : .noLimit
        self.isExecutionTime = advertiser.isExecutionTime
        self.executionTime = advertiser.executionTime
        self.executionTimeString = String(Int(advertiser.executionTime * 1000))
        
        self.advertisingData = SILObservable(initialValue: [])
        self.advertisingDataBytesAvailable = SILObservable(initialValue: 28)
        self.scanResponseData = SILObservable(initialValue: [])
        self.scanResponseBytesAvailable = SILObservable(initialValue: 28)
        self.updateAdvertisingDataAvailableBytesCount()
        self.updateScanResponseAvailableBytesCount()
        self.buildAdvertisingData()
        self.buildScanResponseData()
    }
    
    func update(advertisingSetName: String?) {
        self.advertisingSetName = advertisingSetName ?? "";
    }
    
    func updateExecutionTimeString(_ timeString: String?) {
        self.executionTimeString = timeString ?? ""
    }
    
    func updateExecutionTimeState(isExecutionTime: Bool) {
        if (isExecutionTime) {
            self.isExecutionTime = true
            currentState = .withLimit
        } else {
            self.isExecutionTime = false
            currentState = .noLimit
        }
    }
    
    func updateRadioButtons(completion: @escaping (SILTimeLimitRadioButtonState) -> (Void)) {
        completion(currentState)
    }
    
    func validateExecutionTime(fromString timeString: String?) -> Bool {
        if !isExecutionTime {
            return true
        }
        if let timeInt = Int(timeString ?? "") {
            if timeInt < 10 || timeInt > 655350 {
                return false
            }
            executionTime = Double(timeInt) / 1000.0
            return true
        } else {
            return false
        }
    }
    
    func getExecutionTimeString() -> String {
        let value = executionTime
        let intValue = Int(value * 1000)
        return String(intValue)
    }
    
    func addDataType(sourceView: UIView) {
        wireframe.presentContextMenu(sourceView: sourceView, options: [
            ContextMenuOption(enabled: completeList16 == nil, title: "0x03 Complete List of 16-bit Service Class UUIDs") { [weak self] in
                self?.addCompleteList16()
            },
            ContextMenuOption(enabled: completeList128 == nil, title: "0x07 Complete List of 128-bit Service Class UUIDs") { [weak self] in
                self?.addCompleteList128()
            },
        ])
    }
    
    func addScanResponseDataType(sourceView: UIView) {
        wireframe.presentContextMenu(sourceView: sourceView, options: [
            ContextMenuOption(enabled: !isCompleteLocalName, title: "0x09 Complete Local Name") { [weak self] in
                self?.addCompleteLocalName()
            }
        ])
    }
    
    private func addCompleteLocalName() {
        isCompleteLocalName = true
        buildScanResponseData()
    }
    
    private func addCompleteList16() {
        completeList16 = []
        buildAdvertisingData()
    }
    
    private func addCompleteList128() {
        completeList128 = []
        buildAdvertisingData()
    }
    
    private func buildAdvertisingData() {
        weak var weakSelf = self
        let builder = SILAdvertisingDataViewModelBuilder(serviceRepository: serviceRepository)
        
        builder.add(completeList16: completeList16, addService: {
            weakSelf?.add16BitService()
        }, removeService: { index in
            weakSelf?.remove16BitService(at: index)
        }, removeList: {
            weakSelf?.removeCompleteList16()
        })
        
        builder.add(completeList128: completeList128, addService: {
            weakSelf?.add128BitService()
        }, removeService: { index in
            weakSelf?.remove128BitService(at: index)
        }) {
            weakSelf?.removeCompleteList128()
        }
        
        updateAdvertisingDataAvailableBytesCount()
        
        advertisingData.value = builder.build()
    }
    
    private func buildScanResponseData() {
        weak var weakSelf = self
        let builder = SILScanResponseViewModelBuilder()
        
        if isCompleteLocalName {
            completeLocalName = settings.completeLocalName
            builder.add(completeLocalName: completeLocalName, onRemove: {
                weakSelf?.removeCompleteLocalName()
            })
        }
        
        updateScanResponseAvailableBytesCount()
        
        scanResponseData.value = builder.build()
    }
    
    private func removeCompleteLocalName() {
        isCompleteLocalName = false
        completeLocalName = nil
        buildScanResponseData()
    }
    
    private func add16BitService() {
        weak var weakSelf = self
        
        wireframe.presentAdd16BitServiceDialog(onSave: { service in
            weakSelf?.completeList16?.append(service)
            weakSelf?.buildAdvertisingData()
        })
    }
    
    private func remove16BitService(at index: Int) {
        completeList16?.remove(at: index)
        buildAdvertisingData()
    }
    
    private func removeCompleteList16() {
        weak var weakSelf = self

        removeList(list: completeList16, removeAction: {
            weakSelf?.completeList16 = nil
        })
    }
    
    private func add128BitService() {
        weak var weakSelf = self
        
        wireframe.presentAdd128BitServiceDialog(onSave: { service in
            weakSelf?.completeList128?.append(service)
            weakSelf?.buildAdvertisingData()
        })
    }
    
    private func remove128BitService(at index: Int) {
        completeList128?.remove(at: index)
        buildAdvertisingData()
    }
    
    private func removeCompleteList128() {
        weak var weakSelf = self

        removeList(list: completeList128, removeAction: {
            weakSelf?.completeList128 = nil
        })
    }
    
    func backToHome() {
        let popupIsEnabled = !settings.nonSaveChangesExitWarning
        if popupIsEnabled, advertiserWasChanged() {
            wireframe.presentNonSaveChangesExitWarningPopup(
                onYes: { disableWarning in
                self.settings.nonSaveChangesExitWarning = disableWarning
                self.save()
            }, onNo: {
                self.wireframe.popPage()
            })
        } else {
            wireframe.popPage()
        }
    }
    
    private func advertiserWasChanged() -> Bool {
        if self.advertisingSetName != advertiser.name {
            return true
        }
        
        if self.isCompleteLocalName != advertiser.isCompleteLocalName {
            return true
        }
        
        let advertiserCompleteList16 = advertiser.completeList16 ?? []
        let currentCompleteList16 = self.completeList16 ?? []
        if !currentCompleteList16.elementsEqual(advertiserCompleteList16) {
            return true
        }
        
        let advertiserCompleteList128 = advertiser.completeList128 ?? []
        let currentCompleteList128 = self.completeList128 ?? []
        if !currentCompleteList128.elementsEqual(advertiserCompleteList128) {
            return true
        }
        
        let advertiserState: SILTimeLimitRadioButtonState = advertiser.isExecutionTime ? .withLimit : .noLimit
        if self.currentState != advertiserState {
            return true
        }
        
        let advertiserTimeString = String(Int(advertiser.executionTime * 1000))
        if self.executionTimeString != advertiserTimeString {
            return true
        }
                
        return false
    }
    
    func save() {
        let updated = SILAdvertisingSetEntity(value: advertiser)
        
        completeList16 = completeList16 == [] ? nil : completeList16
        completeList128 = completeList128 == [] ? nil : completeList128
        if (!validateExecutionTime(fromString: executionTimeString)) {
            wireframe.presentInvalidTimeToastAlert()
            return
        }
        updated.name = advertisingSetName
        updated.isCompleteLocalName = isCompleteLocalName
        updated.completeList16 = completeList16
        updated.completeList128 = completeList128
        updated.isExecutionTime = isExecutionTime
        updated.executionTime = executionTime
        
        repository.update(advertiser: updated)
        
        wireframe.popPage()
    }
    
    private func removeList(list: [String]?, removeAction: @escaping () -> Void) {
        weak var weakSelf = self

        let listIsNotEmpty = list != nil && list!.count > 0
        let popupIsEnabled = !settings.disableRemoveServiceListWarning
        
        if listIsNotEmpty && popupIsEnabled {
            wireframe.presentRemoveServiceListWarningDialog(onOk: { disableWarning in
                weakSelf?.settings.disableRemoveServiceListWarning = disableWarning
                removeAction()
                weakSelf?.buildAdvertisingData()
            })
        } else {
            removeAction()
            weakSelf?.buildAdvertisingData()
        }
    }
    
    private func updateAdvertisingDataAvailableBytesCount() {
        var completeList16Size = 2 * (completeList16?.count ?? 0)
        if completeList16Size > 0 {
            completeList16Size = completeList16Size + 2
        }
        var completeList128Size = (completeList128?.count ?? 0) * 16
        if completeList128Size > 0 {
            completeList128Size = completeList128Size + 2
        }
        
        self.advertisingDataBytesAvailable.value =  28 - completeList16Size - completeList128Size
    }
    
    private func updateScanResponseAvailableBytesCount() {
        var completeLocalNameSize = 0
        if isCompleteLocalName {
            completeLocalNameSize = (completeLocalName?.count ?? 0) + 2
        }
        
        self.scanResponseBytesAvailable.value = 28 - completeLocalNameSize
    }
}
