//
//  SILAdvertiserHomeWireframe.swift
//  BlueGecko
//
//  Created by Michał Lenart on 29/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILAdvertiserHomeWireframeType : SILBaseWireframeType {
    init()
    func showAdvertiserDetails(_ advertiser: SILAdvertisingSetEntity)
    func showLocalNameSettingPopup(onSave: @escaping () -> Void)
    func showAdvertiserRemoveWarning(_ confirmAction: @escaping () -> ())
    func showBluetoothDisabledDialog()
    func dismissPopover()
}

protocol SILPopupDismissable {
    func dismissPopover()
}

final class SILAdvertiserHomeWireframe: SILBaseWireframe, SILAdvertiserHomeWireframeType, WYPopoverControllerDelegate, SILPopupDismissable {
    private let storyboard = UIStoryboard(name: "SILAppAdvertiser", bundle: nil)
    
    lazy private var settings = { SILAdvertiserSettings.shared }()
    lazy private var service = { SILAdvertiserService.shared }()
    lazy private var repository = { SILAdvertisingSetRepository() }()
    
    private var popoverController: WYPopoverController?
    
    init() {
        let vc = (storyboard.instantiateInitialViewController() as! SILAdvertiserHomeViewController)
        
        super.init(viewController: vc)
        
        vc.viewModel = SILAdvertiserHomeViewModel(wireframe: self,
                                                  view: vc,
                                                  service: service,
                                                  repository: repository,
                                                  settings: settings)
    }
    
    required init(viewController: UIViewController) {
        super.init(viewController: viewController)
    }
    
    func showAdvertiserDetails(_ advertiser: SILAdvertisingSetEntity) {
        let wireframe = SILAdvertiserDetailsWireframe(repository: repository, service: service, settings: settings, advertiser: advertiser)
        navigationController?.pushWireframe(wireframe)
    }
    
    func showLocalNameSettingPopup(onSave: @escaping () -> Void) {
        let localNameSettingVC = SILLocalNameSettingViewController()
        localNameSettingVC.viewModel = SILLocalNameSettingViewModel(wireframe: self, settings: settings, onSave: onSave)
        self.popoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: localNameSettingVC, presenting: viewController, delegate: self, animated: true)
    }
    
    func showAdvertiserRemoveWarning(_ confirmAction: @escaping () -> ()) {
        let advertiserRemoveWarning = SILWarningViewController()
        let settingAction: (Bool) -> () = { SILAdvertiserRemoveSetting.setDisplayAdvertiserRemoveWarning(value: $0) }
        advertiserRemoveWarning.viewModel = SILRemoveWarningViewModel(wireframe: self, confirmAction: confirmAction, setSettingAction: settingAction, name: "Advertiser")
        self.popoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: advertiserRemoveWarning,
                                                                      presenting: viewController,
                                                                      delegate: self,
                                                                      animated: true)
    }
    
    func showBluetoothDisabledDialog() {
        let bluetoothDisabledAlert = SILBluetoothDisabledAlert.advertiser
        viewController.alertWithOKButton(title: bluetoothDisabledAlert.title,
                                         message: bluetoothDisabledAlert.message)
    }
    
    func dismissPopover() {
        popoverController?.dismissPopover(animated: true)
    }
    
    // MARK: WYPopoverControllerDelegate
    
    func popoverControllerDidDismissPopover(_ popoverController: WYPopoverController!) {
        self.popoverController = nil
    }
}
