//
//  SILAdvertiserAdd128BitServiceDialogViewController.swift
//  BlueGecko
//
//  Created by Michał Lenart on 13/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILAdvertiserAdd128BitServiceDialogViewController: UIViewController, SILAdvertiserAdd128BitServiceDialogViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var uuidTextField: UITextField!
    @IBOutlet weak var saveButton: SILPrimaryButton!
    
    var viewModel: SILAdvertiserAdd128BitServiceDialogViewModel!
    
    override var preferredContentSize: CGSize {
        get {
            return view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    override func viewDidLoad() {
        uuidTextField.delegate = self
        uuidTextField.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
    }
    
    @IBAction func onClear(_ sender: UIButton) {
        viewModel.onClear()
    }
    
    @IBAction func onCancel(_ sender: UIButton) {
        viewModel.onCancel()
    }
    
    @IBAction func onSave(_ sender: UIButton) {
        viewModel.onSave(serviceName: uuidTextField.text)
    }
    
    // MARK: SILAdvertiserAdd128BitServiceDialogViewDelegate
    
    func clearUUID() {
        uuidTextField.text = nil
    }
    
    // MARK: UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var strText = textField.text
        // Allow deleting
        if range.length > 0 && string.isEmpty {
            // Remove also character before hyphen
            if strText?.last == "-" {
                strText?.removeLast()
                textField.text = strText
            }
            return true
        }
        // All characters entered
        if range.location == 36 {
            return false
        }
        
        if strText == nil {
            strText = ""
        }
        // Paste and write only hexString
        var replaceString = onlyHexString(string)
        // Auto-add hyphen before appending 8, 12, 16 and 20 hex char
        strText = strText?.replacingOccurrences(of: "-", with: "")
        if strText!.count > 1 && [8, 12, 16, 20].contains(strText!.count + 1) && replaceString != "" {
            replaceString.append("-")
         }
        textField.text = "\(textField.text!)\(replaceString)"
        if !replaceString.isEmpty {
            textField.sendActions(for: .editingChanged)
        }
        return false
    }
    
    func onlyHexString(_ string: String) -> String {
        let hexChars = CharacterSet(charactersIn: "0123456789abcdef")
        return String(string.unicodeScalars.filter { hexChars.contains($0) })
    }
    
    @objc func editingChanged(_ textField: UITextField) {
        if let text = textField.text {
            saveButton.isEnabled = isRightFormat(text)
        } else {
            saveButton.isEnabled = false
        }
    }
    
    func isRightFormat(_ string: String) -> Bool {
        let hexRegex = "[0-9a-f]"
        let pattern = "\(hexRegex){8}-\(hexRegex){4}-\(hexRegex){4}-\(hexRegex){4}-\(hexRegex){12}"
        let result = string.range(of: pattern, options: .regularExpression) != nil
        return result
    }
    
    
}
