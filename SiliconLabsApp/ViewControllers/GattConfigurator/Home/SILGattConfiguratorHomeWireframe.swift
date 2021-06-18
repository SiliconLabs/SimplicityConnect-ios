//
//  SILGattConfiguratorHomeWireframe.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 01/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

protocol SILGattConfiguratorHomeWireframeType : SILBaseWireframeType {
    init()
    func showGattConfiguratorDetails(gattConfiguration: SILGattConfigurationEntity)
    func showGattConfiguratorRemoveWarning(_ confirmAction: @escaping () -> ())
    func showBluetoothDisabledDialog()
    func dismissPopover()
}

class SILGattConfiguratorHomeWireframe: SILBaseWireframe, WYPopoverControllerDelegate, SILGattConfiguratorHomeWireframeType, SILPopupDismissable {
    private let storyboard = UIStoryboard(name: "SILAppGATTConfigurator", bundle: nil)
    
    lazy private var settings = { SILGattConfiguratorSettings() }()
    lazy private var repository = { SILGattConfigurationRepository.shared }()
    lazy private var service = { SILGattConfiguratorService.shared }()
    
    private var popoverController: WYPopoverController?
    
    required init() {
        let vc = (storyboard.instantiateInitialViewController() as! SILGattConfiguratorHomeViewController)
        
        super.init(viewController: vc)
        
        vc.viewModel = SILGattConfiguratorHomeViewModel(wireframe: self, view: vc, service: service, settings: settings, repository: repository)
    }
    
    required init(viewController: UIViewController) {
        super.init(viewController: viewController)
    }
    
    func showGattConfiguratorDetails(gattConfiguration: SILGattConfigurationEntity) {
        let wireframe = SILGattConfiguratorDetailsWireframe(service: service, repository: repository, settings: settings, gattConfiguration: gattConfiguration)
        navigationController?.pushWireframe(wireframe)
    }
    
    func showGattConfiguratorRemoveWarning(_ confirmAction: @escaping () -> ()) {
        let gattConfiguratorRemoveWarning = SILWarningViewController()
        let settingAction: (Bool) -> () = { self.settings.gattConfiguratorRemoveSetting = $0 }
        gattConfiguratorRemoveWarning.viewModel = SILRemoveWarningViewModel(wireframe: self, confirmAction: confirmAction, setSettingAction: settingAction, name: "GATT Server")
        self.popoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: gattConfiguratorRemoveWarning,
                                                                      presenting: viewController,
                                                                      delegate: self,
                                                                      animated: true)
    }
    
    func showBluetoothDisabledDialog() {
        let bluetoothDisabledAlert = SILBluetoothDisabledAlert.gattConfigurator
        viewController.alertWithOKButton(title: bluetoothDisabledAlert.title,
                                         message: bluetoothDisabledAlert.message)
    }

    
    func dismissPopover() {
        popoverController?.dismissPopover(animated: true)
    }
}
