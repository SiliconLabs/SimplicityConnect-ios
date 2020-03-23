//
//  SILConnectedDeviceDetailsViewController.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 24/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILConnectedDeviceDetailsViewController: UIViewController {
    
    var peripheral: CBPeripheral?
    var centralManager: SILCentralManager?
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var uuidLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
