//
//  SILGattConfiguratorCellViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 09/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILGattConfiguratorCellViewModelType : class {
    var configuration: SILGattConfigurationEntity { get set }
    init(wireframe: SILGattConfiguratorHomeWireframeType, service: SILGattConfiguratorServiceType, repository: SILGattConfigurationRepositoryType,
         settings: SILGattConfiguratorSettingsType, configuration: SILGattConfigurationEntity)
    func editConfiguration()
    func toggleEnableSwitch(isOn: Bool)
    func copyConfiguration()
}

class SILGattConfiguratorCellViewModel: SILCellViewModel, SILGattConfiguratorCellViewModelType {
    var reusableIdentifier: String = "SILGattConfiguratorCellView"
    
    struct State {
        var isOn: Bool
        var name: String
    }
    
    let state: SILObservable<State>
    
    var isExportModeOn: Bool = false
    var isExpanded: Bool = false
    private let wireframe: SILGattConfiguratorHomeWireframeType
    private let service: SILGattConfiguratorServiceType
    private let repository: SILGattConfigurationRepositoryType
    private let settings: SILGattConfiguratorSettingsType
    var configuration: SILGattConfigurationEntity
    
    var serviceCells: [SILCellViewModel] = []
    
    private var runningConfigurationToken: SILObservableToken?
    
    required init(wireframe: SILGattConfiguratorHomeWireframeType, service: SILGattConfiguratorServiceType, repository: SILGattConfigurationRepositoryType,
                  settings: SILGattConfiguratorSettingsType ,configuration: SILGattConfigurationEntity) {
        self.wireframe = wireframe
        self.service = service
        self.repository = repository
        self.settings = settings
        self.configuration = configuration
        
        self.state = SILObservable(initialValue: State(isOn: false, name: configuration.name))
        subscribeToService()
    }
    
    private func subscribeToService() {
        weak var weakSelf = self
        
        runningConfigurationToken = service.runningGattConfiguration.observe { runningConfiguration in
            weakSelf?.updated(runningConfiguration: runningConfiguration)
        }
    }
    
    private func updated(runningConfiguration: SILGattConfigurationEntity?) {
        var newState = state.value
        newState.isOn = self.configuration.uuid == runningConfiguration?.uuid
        self.state.value = newState
    }
    
    func editConfiguration() {
        service.stop()
        wireframe.showGattConfiguratorDetails(gattConfiguration: configuration)
    }
    
    func toggleEnableSwitch(isOn: Bool) {
        if (isOn) {
            service.start(configuration: configuration)
        } else {
            service.stop()
        }
    }
    
    func removeConfiguration() {
        if settings.gattConfiguratorRemoveSetting {
            wireframe.showGattConfiguratorRemoveWarning {
                self.stopAndRemoveConfiguration()
            }
        } else {
            stopAndRemoveConfiguration()
        }
    }
    
    private func stopAndRemoveConfiguration() {
        if service.isRunning(configuration: configuration) {
            service.stop()
        }
        
        repository.remove(configuration: configuration)
    }
    
    func copyConfiguration() {
        repository.add(configuration: configuration.getCopy())
    }
    
    func changeExpand() {
        self.isExpanded.toggle()
        createCharacteristicCells()
    }
    
    private func createCharacteristicCells() {
        var cellModels: [SILCellViewModel] = []
        if isExpanded {
            for service in configuration.services {
                let serviceCell = SILGattConfiguratorServiceInfoCellViewModel(service: service)
                cellModels.append(serviceCell)
            }
        }
        serviceCells = cellModels
    }
}
