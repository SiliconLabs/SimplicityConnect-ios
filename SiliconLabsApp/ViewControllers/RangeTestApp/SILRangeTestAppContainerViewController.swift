//
//  SILRangeTestAppContainerViewController.swift
//  SiliconLabsApp
//
//  Created by Michał Lenart on 26/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit
import SVProgressHUD
import CoreBluetooth

struct SILSetTabDeviceName {
    let invoke: (String) -> Void
}

protocol SILRangeTestBluetoothConnectionsHandler: class {
    func addConnectedPeripheral(_ peripheral: CBPeripheral)
    func deviceDidDisconnect()
    func bluetoothIsDisabled()
    var filter: DiscoveredPeripheralFilter { get }
}

class SILRangeTestAppContainerViewController: UIViewController, UITabBarControllerDelegate {
    
    @IBOutlet weak var tabSelection: UISegmentedControl!
    
    var tabController: UITabBarController!
    var connectedPeripherals: [CBPeripheral] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLeftAlignedTitle("Range Test")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.tabBarController?.hideTabBarAndUpdateFrames()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.tabBarController?.showTabBarAndUpdateFrames()
    }
    
    @IBAction func didSelectTab(_ sender: Any) {
        tabController?.selectedIndex = tabSelection.selectedSegmentIndex
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowTabBarController") {
            tabController = (segue.destination as! UITabBarController)

            for i in tabController.viewControllers!.indices {
                if let navigationController = tabController.viewControllers?[i] as? UINavigationController, let selectedDeviceVC = navigationController.viewControllers[0] as? SILRangeTestSelectDeviceViewController {
                    selectedDeviceVC.bluetoothConnectionsHandler = self
                }
                
                let context = SILSetTabDeviceName(invoke: { [weak self] (name: String) in
                    self?.tabSelection.setTitle(name, forSegmentAt: i)
                })
                tabController.viewControllers?[i].sil_provideContext(type: SILSetTabDeviceName.self, value: context)
            }

        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isEqual(navigationController?.interactivePopGestureRecognizer) {
            navigationController?.popViewController(animated: true)
            return true
        }
        return false
    }
}

extension SILRangeTestAppContainerViewController: SILRangeTestBluetoothConnectionsHandler {
    var filter: DiscoveredPeripheralFilter {
        return { discoveredPeripheral in
            guard let discoveredPeripheral = discoveredPeripheral, let peripheral = discoveredPeripheral.peripheral else {
                return false
            }
            
            return discoveredPeripheral.isRangeTest && !self.connectedPeripherals.contains(peripheral)
        }
    }
    
    func bluetoothIsDisabled() {
        let bluetoothDisabledAlert = SILBluetoothDisabledAlert.rangeTest
        self.alertWithOKButton(title: bluetoothDisabledAlert.title,
                               message: bluetoothDisabledAlert.message,
                               completion: { [weak self] _ in self?.navigationController?.popToRootViewController(animated: true)
                               })
    }
    
    func deviceDidDisconnect() {
        SVProgressHUD.showError(withStatus: "Device unexpectedly disconnected.")
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func addConnectedPeripheral(_ peripheral: CBPeripheral) {
        if !connectedPeripherals.contains(peripheral) {
            connectedPeripherals.append(peripheral)
        }
    }
}
