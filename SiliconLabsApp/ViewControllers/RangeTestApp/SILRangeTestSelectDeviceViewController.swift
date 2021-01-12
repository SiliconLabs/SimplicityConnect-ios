//
//  SILRangeTestSelectDeviceViewController.swift
//  SiliconLabsApp
//
//  Created by Michał Lenart on 26/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILRangeTestSelectDeviceViewController: UIViewController, SILDeviceSelectionViewControllerDelegate, WYPopoverControllerDelegate, SILRangeTestModeSelectionViewControllerDelegate {
    @IBOutlet weak var connectButton: SILPrimaryButton!
    
    private let app = SILApp.rangeTest()!
    private let centralManager = SILCentralManagerBuilder.buildCentralManager(with: SILAppType.typeRangeTest)!
    
    private var popoverController: WYPopoverController?

    override func viewDidLoad() {
        super.viewDidLoad()
        connectButton.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        connect()
    }
    
    @IBAction func didTapConnect(_ sender: Any) {
        connect()
    }
    
    private func connect() {
        connectButton.isEnabled = false
        self.popoverController?.dismissPopover(animated: false)
        
        let viewModel = SILDeviceSelectionViewModel(appType: app)
        viewModel?.filter = { discoveredPeripheral in
            return discoveredPeripheral?.isRangeTest ?? false
        }
        
        let selectionViewController = SILDeviceSelectionViewController(deviceSelectionViewModel: viewModel)!
        
        selectionViewController.centralManager = centralManager
        selectionViewController.delegate = self

        self.popoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: selectionViewController, presenting: self, delegate: self, animated: true)
    }
    
    // MARK: SILDeviceSelectionViewControllerDelegate
    
    func deviceSelectionViewController(_ viewController: SILDeviceSelectionViewController!, didSelect peripheral: CBPeripheral!) {
        self.popoverController?.dismissPopover(animated: true) {
            let storyboard = UIStoryboard(name: "SILAppTypeRangeTest", bundle: nil)
            let selectionViewController = storyboard.instantiateViewController(withIdentifier: "SILRangeTestModeSelectionViewController") as! SILRangeTestModeSelectionViewController
            
            selectionViewController.app = self.app;
            selectionViewController.delegate = self
            selectionViewController.peripheral = SILRangeTestPeripheral(withPeripheral: peripheral, andCentralManager: self.centralManager)
            
            self.popoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: selectionViewController, presenting: self, delegate: self, animated: true)
        }
    }
    
    func didDismissDeviceSelectionViewController() {
        popoverController = nil
        connectButton.isEnabled = true
    }
    
    // MARK: SILRangeTestModeSelectionViewControllerDelegate
    
    func didRangeTestModeSelected(forApp app: SILApp?,
                                  peripheral: SILRangeTestPeripheral?,
                                  andBoardInfo boardInfo: SILRangeTestBoardInfo?,
                                  selectedMode mode: SILRangeTestMode) {
        self.popoverController?.dismissPopover(animated: true) {
            let storyboard = UIStoryboard(name: "SILAppTypeRangeTest", bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: "SILRangeTestAppViewController") as! SILRangeTestAppViewController
            let viewModel = SILRangeTestAppViewModel(withMode: mode, peripheral: peripheral!, andBoardInfo: boardInfo!)
                
            viewController.app = app;
            viewController.viewModel = viewModel;

            self.navigationController?.pushViewController(viewController, animated: true)
            self.connectButton.isEnabled = true
        }
    }
    
    func didDismissRangeTestModeSelectionViewController() {
        popoverController = nil
        connectButton.isEnabled = true
    }
    
    // MARK: WYPopoverControllerDelegate
    
    func popoverControllerDidDismissPopover(_ popoverController: WYPopoverController!) {
        self.popoverController = nil
    }
}
