//
//  File.swift
//  BlueGecko
//
//  Created by Michał Lenart on 23/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILAdvertiserHomeViewDelegate: class {
    func updateAdvertisers(advertisers: [SILAdvertiserCellViewModel])
}

class SILAdvertiserHomeViewModel {
    private let wireframe: SILAdvertiserHomeWireframe
    private unowned let view: SILAdvertiserHomeViewDelegate
    private let service: SILAdvertiserService
    private let repository: SILAdvertisingSetRepository
    private let settings: SILAdvertiserSettings
    
    private var advertisersSubscription: (() -> Void)?
    private var observableTokenBag = SILObservableTokenBag()
    
    private var advertisers: [SILAdvertisingSetEntity] = []
    private var runningAdvertisers: [SILAdvertisingSetEntity] = []
    
    var cellViewModels: [SILAdvertiserCellViewModel] = []
    
    private let advertiserNotification: SILAdvertiserNotification
    
    init(wireframe: SILAdvertiserHomeWireframe, view: SILAdvertiserHomeViewDelegate, service: SILAdvertiserService, repository: SILAdvertisingSetRepository, settings: SILAdvertiserSettings) {
        self.wireframe = wireframe
        self.view = view
        self.service = service
        self.repository = repository
        self.settings = settings
        self.advertiserNotification = SILAdvertiserNotification(advertiserService: service)
    }
    
    deinit {
        advertisersSubscription?()
    }
    
    func viewDidLoad() {
        weak var weakSelf = self;
        
        advertisersSubscription = repository.observeAdvertisers { advertisers in
            weakSelf?.update(advertisers: advertisers)
        }
        
        service.runningAdvertisers.observe { [weak self] (runningAdvertisers) in
            self?.runningAdvertisers = runningAdvertisers
        }.putIn(bag: observableTokenBag)
        
        service.blutoothEnabled.observe(sendInitial: false) { [weak self] state in
            if state == false {
                self?.wireframe.showBluetoothDisabledDialog()
            }
        }.putIn(bag: observableTokenBag)
        
        advertiserNotification.askForPermission()
    }
    
    func setLocalName() {
        weak var weakSelf = self

        wireframe.showLocalNameSettingPopup(onSave: {
            weakSelf?.rebuildCellViewModels()
        })
    }
    
    func createAdvertiser() {
        let advertiser = SILAdvertisingSetEntity()
        advertiser.name = "New Advertiser"
        repository.add(advertiser: advertiser)
    }
    
    func enable(advertiser: SILAdvertisingSetEntity) {
        service.start(advertiser: advertiser)
    }
    
    func switchAllOff() {
        service.stopAllAdvertisers()
    }
    
    private func update(advertisers: [SILAdvertisingSetEntity]) {
        self.advertisers = advertisers
        rebuildCellViewModels()
    }
    
    private func rebuildCellViewModels() {
        let newViewModels = createNewViewModels(from: advertisers)
        createAdTypesViewModelsIfNeeded(for: newViewModels)
        self.cellViewModels = newViewModels
        self.view.updateAdvertisers(advertisers: newViewModels)
    }
    
    private func createNewViewModels(from advertisers: [SILAdvertisingSetEntity]) -> [SILAdvertiserCellViewModel] {
        return advertisers.map({ advertiser in
            return SILAdvertiserCellViewModel(wireframe: wireframe, service: service, repository: repository, settings: settings, advertiser: advertiser)
        })
    }
    
    private func createAdTypesViewModelsIfNeeded(for newViewModels: [SILAdvertiserCellViewModel]) {
         let filteredViewModels = self.cellViewModels.filter{ viewModel in
            newViewModels.contains(where: {
                newViewModel in viewModel.advertiser.uuid == newViewModel.advertiser.uuid
            })
        }
        
        for newViewModel in newViewModels {
            if let oldViewModel = filteredViewModels.first(where: { oldViewModel in oldViewModel.advertiser.uuid == newViewModel.advertiser.uuid }),
               oldViewModel.state.value.isExpanded {
                newViewModel.updateSection{ }
            }
        }
    }
}
