//
//  SILLocalNameSettingViewController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 28/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILLocalNameSettingViewController: UIViewController, SILLocalNameSettingViewDelegate {
    
    @IBOutlet weak var localNameTextField: UITextField!
    @IBOutlet weak var saveButton: SILPrimaryButton!
    
    var viewModel: SILLocalNameSettingViewModel!
    
    override var preferredContentSize: CGSize {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return CGSize(width: 500, height: 170)
            } else {
                return CGSize(width: 350, height: 170)
            }
        }
        set {
            super.preferredContentSize = newValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewDelegate = self
        localNameTextField.addTarget(self, action: #selector(editingChanged(_:)), for: .allEditingEvents)
        localNameTextField.text = viewModel.completeLocalName
        localNameTextField.becomeFirstResponder()
    }

    @IBAction func onClear(_ sender: UIButton) {
        viewModel.onClear()
    }
    
    @IBAction func onCancel(_ sender: UIButton) {
        viewModel.onCancel()
    }
    
    @IBAction func onSave(_ sender: UIButton) {
        viewModel.onSave(localName: localNameTextField.text!)
    }
    
    // MARK: SILLocalNameSettingViewDelegate
    
    func clearLocalName() {
        localNameTextField.text = nil
        localNameTextField.sendActions(for: .editingChanged)
    }
    
    @objc func editingChanged(_ textField: UITextField) {
        saveButton.isEnabled = textField.hasText
    }
    
}
