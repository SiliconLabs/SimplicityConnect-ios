//
//  SILAdvertiserHomeWireframe.swift
//  BlueGecko
//
//  Created by Michał Lenart on 29/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

final class SILAdvertiserHomeWireframe: SILBaseWireframe, WYPopoverControllerDelegate {
    private let storyboard = UIStoryboard(name: "SILAppAdvertiser", bundle: nil)
    
    lazy private var settings = { SILAdvertiserSettings() }()
    lazy private var service = { SILAdvertiserService(settings: settings) }()
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
        let adveriserRemoveWarning = SILAdvertiserRemoveWarningViewController()
        adveriserRemoveWarning.viewModel = SILAdvertiserRemoveWarningViewModel(wireframe: self, confirmAction: confirmAction)
        self.popoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: adveriserRemoveWarning,
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
