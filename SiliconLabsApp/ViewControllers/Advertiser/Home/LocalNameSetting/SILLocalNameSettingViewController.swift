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
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var viewModel: SILLocalNameSettingViewModel!
    
    override var preferredContentSize: CGSize {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return CGSize(width: 500, height: 210)
            } else {
                return CGSize(width: 350, height: 210)
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
        descriptionLabel.text = "The name will appear in the scan results"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        localNameTextField.becomeFirstResponder()
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
