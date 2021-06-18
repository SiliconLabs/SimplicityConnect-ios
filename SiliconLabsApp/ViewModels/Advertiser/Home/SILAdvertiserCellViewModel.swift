//
//  SILAdvertiserViewModel.swift
//  BlueGecko
//
//  Created by Michał Lenart on 24/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILAdvertiserCellViewModel: SILCellViewModel {
    var reusableIdentifier: String = "SILAdvertiserCellView"
    
    struct State {
        var isOn: Bool
        var name: String
        var isExpanded: Bool
    }
    
    let state: SILObservable<State>
    
    private let wireframe: SILAdvertiserHomeWireframe
    private let service: SILAdvertiserService
    private let repository: SILAdvertisingSetRepository
    private let settings: SILAdvertiserSettings
    let advertiser: SILAdvertisingSetEntity
    
    var advertiserAdTypes: [SILAdvertiserAdTypeCellViewModel] = []
    
    private var runningAdvertisersToken: SILObservableToken?
    
    init(wireframe: SILAdvertiserHomeWireframe, service: SILAdvertiserService, repository: SILAdvertisingSetRepository, settings: SILAdvertiserSettings, advertiser: SILAdvertisingSetEntity) {
        self.wireframe = wireframe
        self.service = service
        self.repository = repository
        self.settings = settings
        self.advertiser = advertiser
        
        self.state = SILObservable(initialValue: State(isOn: false, name: advertiser.name, isExpanded: false))
        
        subscribeToService()
    }
    
    private func subscribeToService() {
        weak var weakSelf = self

        runningAdvertisersToken = service.runningAdvertisers.observe({ runningAdvertisers in
            weakSelf?.updated(runningAdvertisers: runningAdvertisers)
        })
    }
    
    private func updated(runningAdvertisers: [SILAdvertisingSetEntity]) {
        var newState = state.value
        newState.isOn = Self.isRunning(runningAdvertisers: runningAdvertisers, advertiser: advertiser)
        self.state.value = newState
    }
    
    func editAdvertiser() {
        service.stopAllAdvertisers()
        wireframe.showAdvertiserDetails(advertiser)
    }
    
    func toggleEnableSwitch(isOn: Bool) {
        if (isOn) {
            service.start(advertiser: advertiser)
        } else {
            service.stop(advertiser: advertiser)
        }
    }
    
    func removeAdvertiser() {
        if SILAdvertiserRemoveSetting.shouldDisplayAdvertiserRemoveWarning() {
            wireframe.showAdvertiserRemoveWarning {
                self.stopAndRemoveAdvertiser()
            }
        } else {
            stopAndRemoveAdvertiser()
        }
    }
    
    private func stopAndRemoveAdvertiser() {
        service.stop(advertiser: advertiser)
        repository.remove(advertiser: advertiser)
    }
    
    func copyAdvertiserSet() {
        repository.add(advertiser: advertiser.getCopy())
    }
    
    func updateSection(completion: @escaping () -> ()) {
        self.state.value.isExpanded = !self.state.value.isExpanded
        if self.state.value.isExpanded {
            advertiserAdTypes = calculateAdvertiserAdTypes()
        } else {
            advertiserAdTypes = []
        }
        completion()
    }
    
    private func calculateAdvertiserAdTypes() -> [SILAdvertiserAdTypeCellViewModel] {
        var advertiserTypes = [SILAdvertiserAdTypeCellViewModel]()
        
        
        if let completeList16 = advertiser.completeList16 {
            let servicesRepository = SILGattAssignedNumbersRepository()
            let value = completeList16.map({ uuid in
                let serviceName = servicesRepository.getService(byUuid: uuid)?.name ?? "Unknown service"
                return "0x\(uuid) - \(serviceName)"
            }).joined(separator: "\n")
            
            advertiserTypes.append(SILAdvertiserAdTypeCellViewModel(title: "Complete List of 16-bit Service Class UUIDs", value: value))
        }
        if let completeList128 = advertiser.completeList128 {
            let value = completeList128.joined(separator: "\n")
            advertiserTypes.append(SILAdvertiserAdTypeCellViewModel(title: "Complete List of 128-bit Service Class UUIDs", value: value))
        }
        if advertiser.isCompleteLocalName {
            advertiserTypes.append(SILAdvertiserAdTypeCellViewModel(title: "Complete Local Name", value: settings.completeLocalName))
        }
        
        return advertiserTypes
    }
    
    private static func isRunning(runningAdvertisers: [SILAdvertisingSetEntity], advertiser: SILAdvertisingSetEntity) -> Bool {
        return runningAdvertisers.contains { value in
            return advertiser.uuid == value.uuid
        }
    }
}
