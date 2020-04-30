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
class SILMapNameEditorViewController: SILDebugPopoverViewController, UITextFieldDelegate {
    @IBOutlet weak var modelNameLabel: UILabel!
    @IBOutlet weak var modelUuidLabel: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var invalidInputLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: SILRoundedButton!
    @objc var model: SILMap!
    private let ErrorParsingModelText = "Error during the parsing model"
        
    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: 300, height: 190)
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFieldsUsingModel()
        setDelegateForNameField()
    }
            
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        hideErrorTextIfNeeded(in: textField)
        return true
    }
        
    @IBAction func save(_ sender: SILRoundedButton) {
        if isValidName() {
            updateModel(with: nameField.text!)
        } else {
            showInvalidInputInfo()
        }
    }
        
    @IBAction func cancel(_ sender: Any) {
        dismissPopover()
    }
    
    private func setupFieldsUsingModel() {
        let ServiceTitleText = "Change service name"
        let CharacteristicTitleText = "Change characteristic name"
                
        switch self.model {
        case is SILServiceMap:
            modelNameLabel.text = ServiceTitleText
        case is SILCharacteristicMap:
            modelNameLabel.text = CharacteristicTitleText
        default:
            return
        }
        
        modelUuidLabel.text = self.model.uuid
        nameField.text = self.model.name
    }
        
    private func setDelegateForNameField() {
        nameField.delegate = self
    }
    
    private func updateModel(with text: String) {
        switch self.model {
        case let serviceModel as SILServiceMap:
            updateServiceModel(serviceModel, with: text)
        case let characteristicModel as SILCharacteristicMap:
            updateCharacteristicModel(characteristicModel, with: text)
        default:
            return
        }
    }

    fileprivate func updateServiceModel(_ serviceModel: SILServiceMap, with text: String) {
        if SILServiceMap.add(SILServiceMap.create(with: text, uuid: serviceModel.uuid)) {
            dismissPopover()
        }
    }
    
    fileprivate func updateCharacteristicModel(_ characteristicModel: SILCharacteristicMap, with text: String) {
        if SILCharacteristicMap.add(SILCharacteristicMap.create(with: text, uuid: characteristicModel.uuid)) {
            dismissPopover()
        }
    }
        
    fileprivate func hideErrorTextIfNeeded(in textField: UITextField) {
        if !self.invalidInputLabel.isHidden && !textField.text!.isEmpty {
             self.invalidInputLabel.isHidden = true
         }
    }
    
    fileprivate func dismissPopover() {
        self.popoverDelegate.didClose(self)
    }
    
    fileprivate func showInvalidInputInfo() {
        self.invalidInputLabel.isHidden = false
    }
    
    fileprivate func isValidName() -> Bool {
        if let name: String = nameField.text, name.count > 0 {
            return true
        } else {
            return false
        }
    }
}
