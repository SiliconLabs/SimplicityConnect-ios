//
//  SILMapNameEditorViewController.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 03/03/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@objc
@IBDesignable
class SILMapNameEditorViewController: SILDebugPopoverViewController {
    
    @IBOutlet weak var modelNameLabel: UILabel!
    @IBOutlet weak var modelUuidLabel: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var invalidInputLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var saveButton: SILRoundedButton!
    
    @objc var model: SILGenericAttributeTableModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let serviceModel: SILServiceTableModel = self.model as? SILServiceTableModel {
            modelNameLabel.text = "Change service name"
            modelUuidLabel.text = serviceModel.uuidString()
            nameField.text = serviceModel.name()
        }
        if let characteristicName: SILCharacteristicTableModel = self.model as? SILCharacteristicTableModel {
            modelNameLabel.text = "Change characteristic name"
            modelUuidLabel.text = characteristicName.uuidString()
            nameField.text = characteristicName.name()
        }
    }
    
    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: 300, height: 180);
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    @IBAction func save(_ sender: SILRoundedButton) {
        if let serviceModel: SILServiceTableModel = self.model as? SILServiceTableModel {
            if let name: String = nameField.text {
                if SILServiceMap.add(SILServiceMap.create(with: name, uuid: serviceModel.uuidString())) {
                    self.popoverDelegate.didClose(self)
                }
            }
        }
        if let charModel: SILCharacteristicTableModel = self.model as? SILCharacteristicTableModel {
            if let name: String = nameField.text {
                if SILCharacteristicMap.add(SILCharacteristicMap.create(with: name, uuid: charModel.uuidString())) {
                    self.popoverDelegate.didClose(self)
                }
            }
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.popoverDelegate.didClose(self)
    }
}
