//
//  Untitled.swift
//  SiliconLabsApp
//
//  Created by Mantosh Kumar on 10/08/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//
import UIKit
import UniformTypeIdentifiers

// MARK:  UIDocumentPickerDelegate
extension SILSmartLockViewController: UIDocumentPickerDelegate {
    
    func showDocumentPickerView() {
        var types: [UTType] = []
        if let p12Type = UTType(filenameExtension: "p12") {
            types = [p12Type]
        }
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        debugPrint("DID PICK")
        self.sendChosenUrl(urls: urls)
    }
    
    func sendChosenUrl(urls: [URL]) {
        if let p12File = urls.first {
            selectedCtrPath = p12File.path
            
            // Clear previous certificate info
            UserDefaults.standard.removeObject(forKey: "certificateId")
            UserDefaults.standard.removeObject(forKey: "certificateArn")
            
            if let filename =  urls.first?.lastPathComponent {
                self.awsCertificateFileTextField.text = filename
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        debugPrint("DID CANCEL")
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITextFieldDelegate

extension SILSmartLockViewController: UITextFieldDelegate, UITextViewDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == awsCertificateFileTextField {
            showDocumentPickerView()
            return false
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == awsCustomCommandTextField {
            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return true }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            awsCustomButton.isEnabled = !updatedText.isEmpty
            updateAwsCustomButtonAppearance()
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func addDoneButtonOnKeyboard() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))
        // Set blue color and bold font for Done button text
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.systemBlue, .font: UIFont.boldSystemFont(ofSize: 15) ]
        doneButton.setTitleTextAttributes(attributes, for: .normal)
        doneButton.setTitleTextAttributes(attributes, for: .highlighted)
        toolbar.items = [flexSpace, doneButton]
        
        awsCustomCommandTextField.inputAccessoryView = toolbar
        // awsCertificateFileTextField.inputAccessoryView = toolbar
        awsCertificatePasswordTextField.inputAccessoryView = toolbar
        pubTextField.inputAccessoryView = toolbar
        subTextField.inputAccessoryView = toolbar
        awsEndPointTextView.inputAccessoryView = toolbar
    }
    
    @objc private func doneButtonAction() {
        self.view.endEditing(true)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height

        if awsEndPointTextView.isFirstResponder || awsCustomCommandTextField.isFirstResponder || pubTextField.isFirstResponder {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardHeight / 2
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        // Restore the view position
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
}
