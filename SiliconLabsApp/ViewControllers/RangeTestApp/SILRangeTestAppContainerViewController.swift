//
//  SILRangeTestAppContainerViewController.swift
//  SiliconLabsApp
//
//  Created by Michał Lenart on 26/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

struct SILSetTabDeviceName {
    let invoke: (String) -> Void
}

class SILRangeTestAppContainerViewController: UIViewController, UITabBarControllerDelegate, UIGestureRecognizerDelegate {
    @IBOutlet weak var navigationBar: UIView!
    @IBOutlet weak var tabSelection: UISegmentedControl!
    
    var tabController: UITabBarController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.addShadow()
        navigationBar.superview?.bringSubviewToFront(navigationBar)
        observeForBluetoothDisabledNotification()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.SILCentralManagerBluetoothDisabled, object: nil)
    }
    
    func observeForBluetoothDisabledNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(bluetoothIsDisabled(_:)), name: NSNotification.Name.SILCentralManagerBluetoothDisabled, object: nil)
    }
    
    @objc func bluetoothIsDisabled(_ notification: Notification) {
        let bluetoothDisabledAlert = SILBluetoothDisabledAlert.rangeTest
        self.alertWithOKButton(title: bluetoothDisabledAlert.title,
                               message: bluetoothDisabledAlert.message,
                               completion: { [weak self] _ in self?.navigationController?.popToRootViewController(animated: true)
                               })
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func didSelectTab(_ sender: Any) {
        tabController?.selectedIndex = tabSelection.selectedSegmentIndex
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowTabBarController") {
            tabController = (segue.destination as! UITabBarController)

            for i in tabController.viewControllers!.indices {
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
