//
//  SILGattConfiguratorHomeViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 04/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

protocol SILGattConfiguratorHomeViewDelegate: class {
    func updateConfigurations(configurations: [SILGattConfiguratorCellViewModel])
}

class SILGattConfiguratorHomeViewModel {
    private let wireframe: SILGattConfiguratorHomeWireframeType
    private unowned let view: SILGattConfiguratorHomeViewDelegate
    private let repository: SILGattConfigurationRepositoryType
    private let service: SILGattConfiguratorServiceType
    private let settings: SILGattConfiguratorSettingsType
    
    private var configurationsSubscription: (() -> Void)?
    
    var gattConfigurations: [SILGattConfigurationEntity] = []
    var cellViewModels: [SILGattConfiguratorCellViewModel] = []
    
    private let observableTokenBag = SILObservableTokenBag()
    
    init(wireframe: SILGattConfiguratorHomeWireframeType, view: SILGattConfiguratorHomeViewDelegate, service: SILGattConfiguratorServiceType,
         settings: SILGattConfiguratorSettingsType, repository: SILGattConfigurationRepositoryType) {
        self.wireframe = wireframe
        self.view = view
        self.repository = repository
        self.service = service
        self.settings = settings
    }
    
    deinit {
        configurationsSubscription?()
    }
    
    func viewDidLoad() {
        weak var weakSelf = self;
        
        configurationsSubscription = repository.observeConfigurations { configurations in
            weakSelf?.update(configurations: configurations)
        }
        
        service.blutoothEnabled.observe(sendInitial: false) { [weak self] state in
            if state == false {
                self?.wireframe.showBluetoothDisabledDialog()
            }
        }.putIn(bag: observableTokenBag)
    }
    
    func openMenu(sourceView: UIView) {
        wireframe.presentContextMenu(sourceView: sourceView, options: [
            ContextMenuOption(title: "Create new") { [weak self] in
                print("Selected create new")
                self?.createGattConfiguration()
            }
        ])
    }

    func createGattConfiguration() {
        let configuration = SILGattConfigurationEntity()
        configuration.name = "New GATT Server"
        repository.add(configuration: configuration)
    }
    
    private func update(configurations: [SILGattConfigurationEntity]) {
        gattConfigurations = configurations
        rebuildCellViewModels()
    }
    
    private func rebuildCellViewModels() {
        let newViewModels = createNewViewModels(from: gattConfigurations)
        self.cellViewModels = newViewModels
        self.view.updateConfigurations(configurations: newViewModels)
    }
    
    private func createNewViewModels(from configurations: [SILGattConfigurationEntity]) -> [SILGattConfiguratorCellViewModel] {
        return gattConfigurations.map { configuration in
            return SILGattConfiguratorCellViewModel(wireframe: wireframe as! SILGattConfiguratorHomeWireframe, service: service as! SILGattConfiguratorService, repository: repository as! SILGattConfigurationRepository, settings: settings, configuration: configuration)
        }
    }
}
