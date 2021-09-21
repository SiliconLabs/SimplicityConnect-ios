//
//  SILGattConfiguratorDetailsWireframe.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 11/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILGattConfiguratorDetailsWireframeType: SILBaseWireframeType {
    init(service: SILGattConfiguratorService, repository: SILGattConfigurationRepository, settings: SILGattConfiguratorSettingsType, gattConfiguration: SILGattConfigurationEntity, gattAssignedRepository: SILGattAssignedNumbersRepository)
    func popPage()
    func dismissPopover()
    func presentCreateGattServicePopup(onSave: @escaping (SILGattConfigurationServiceEntity) -> ())
}

class SILGattConfiguratorDetailsWireframe: SILBaseWireframe, SILGattConfiguratorDetailsWireframeType, WYPopoverControllerDelegate, SILPopupDismissable {
    
    private let storyboard = UIStoryboard(name: "SILAppGATTConfigurator", bundle: nil)
    private var gattAssignedRepository: SILGattAssignedNumbersRepository?
    private var popover: WYPopoverController?
    
    required init(service: SILGattConfiguratorService, repository: SILGattConfigurationRepository, settings: SILGattConfiguratorSettingsType, gattConfiguration: SILGattConfigurationEntity, gattAssignedRepository: SILGattAssignedNumbersRepository) {
        let vc = storyboard.instantiateViewController(withIdentifier: "GattConfiguratorDetails") as! SILGattConfiguratorDetailsViewController
        self.gattAssignedRepository = gattAssignedRepository
        
        super.init(viewController: vc)
        
        vc.viewModel = SILGattConfiguratorDetailsViewModel(wireframe: self, service: service, repository: repository, settings: settings, gattConfiguration: gattConfiguration)
    }
    
    required init(viewController: UIViewController) {
        super.init(viewController: viewController)
    }
    
    func popPage() {
        navigationController?.popViewController(animated: true)
    }
    
    func dismissPopover() {
        popover?.dismissPopover(animated: true)
    }
    
    func presentCreateGattServicePopup(onSave: @escaping (SILGattConfigurationServiceEntity) -> ()) {
        let vc = SILCreateGattServiceViewController()
        let viewModel = SILCreateGattServiceViewModel(wireframe: self, repository: gattAssignedRepository!, onSave: onSave)
        viewModel.viewDelegate = vc
        vc.viewModel = viewModel
        popover = WYPopoverController.sil_presentCenterPopover(withContentViewController: vc, presenting: viewController, delegate: self, animated: true)
    }
    
    func presentCreateGattCharacteristicPopup(onSave: @escaping (SILGattConfigurationCharacteristicEntity) -> ()) {
        let vc = SILCreateGattCharacteristicViewController()
        let viewModel = SILCreateGattCharacteristicViewModel(wireframe: self, repository: gattAssignedRepository!, onSave: onSave)
        viewModel.viewDelegate = vc
        vc.viewModel = viewModel
        popover = WYPopoverController.sil_presentCenterPopover(withContentViewController: vc, presenting: viewController, delegate: self, animated: true)
    }
    
    func presentEditGattCharacteristicPopup(characteristic: SILGattConfigurationCharacteristicEntity, onSave: @escaping (SILGattConfigurationCharacteristicEntity) -> ()) {
        let vc = SILCreateGattCharacteristicViewController()
        let viewModel = SILCreateGattCharacteristicViewModel(wireframe: self, repository: gattAssignedRepository!, characteristic: characteristic, onSave: onSave)
        viewModel.viewDelegate = vc
        vc.viewModel = viewModel
        popover = WYPopoverController.sil_presentCenterPopover(withContentViewController: vc, presenting: viewController, delegate: self, animated: true)
    }
    
    func presentCreateGattDescriptorPopup(onSave: @escaping (SILGattConfigurationDescriptorEntity) -> ()) {
        let vc = SILCreateGattDescriptorViewController()
        let viewModel = SILCreateGattDescriptorViewModel(wireframe: self, repository: gattAssignedRepository!, onSave: onSave)
        viewModel.viewDelegate = vc
        vc.viewModel = viewModel
        popover = WYPopoverController.sil_presentCenterPopover(withContentViewController: vc, presenting: viewController, delegate: self, animated: true)
    }
    
    func presentEditGattDescriptorPopup(descriptor: SILGattConfigurationDescriptorEntity, onSave: @escaping (SILGattConfigurationDescriptorEntity) -> ()) {
        let vc = SILCreateGattDescriptorViewController()
        let viewModel = SILCreateGattDescriptorViewModel(wireframe: self, repository: gattAssignedRepository!, descriptor: descriptor, onSave: onSave)
        viewModel.viewDelegate = vc
        vc.viewModel = viewModel
        popover = WYPopoverController.sil_presentCenterPopover(withContentViewController: vc, presenting: viewController, delegate: self, animated: true)
    }
    
    func presentNonSaveChangesExitWarningPopup(_ onYes: @escaping () -> (), onNo: @escaping () -> (), settingAction: @escaping (Bool) -> ()) {
        let gattConfiguratorExitWarning = SILWarningViewController()
        gattConfiguratorExitWarning.viewModel = SILExitWarningViewModel(wireframe: self, confirmAction: onYes, cancelAction: onNo, setSettingAction: settingAction)
        popover = WYPopoverController.sil_presentCenterPopover(withContentViewController: gattConfiguratorExitWarning,
                                                                      presenting: viewController,
                                                                      delegate: self,
                                                                      animated: true)
    }
    
    // MARK: WYPopoverControllerDelegate
    
    func popoverControllerDidDismissPopover(_ popoverController: WYPopoverController!) {
        popover = nil
    }
}
