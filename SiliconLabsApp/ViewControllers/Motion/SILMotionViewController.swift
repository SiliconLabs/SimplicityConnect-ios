//
//  MotionVC.swift
//  BlueGecko
//
//  Created by Anastazja Gradowska on 20/09/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation


class SILMotionViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet var navigationBar: UIView!
    private var viewModel: SILMotionViewModel!
    
    @IBOutlet weak var peripheralName: UILabel?
    
    public var centralManager: SILCentralManager!;
    public var connectedPeripheral: CBPeripheral!;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = SILMotionViewModel(centralManager: centralManager!, connectedPeripheral: connectedPeripheral!)
        self.peripheralName?.text = viewModel?.checkPeripheralName()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        viewModel.viewWillDisappear()
    }
    
    @IBAction func backButtonTapped() -> Void {
        self.navigationController?.popViewController(animated: true)
    }
}
