//
//  SILDropDown.swift
//  BlueGecko
//
//  Created by Michał Lenart on 21/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

@objcMembers
class SILDropDown: NSObject, SILDropDownViewControllerDelegate {
    let textField: UITextField
    let values: [String]
    
    var viewController: SILDropDownViewController
    var window: UIWindow
    
    private var isEditing: Bool {
        return textField.isEditing
    }
    
    private var inputText: String {
        return textField.text ?? ""
    }
    
    init(textField: UITextField, values: [String]) {
        self.textField = textField
        self.values = values
        
        viewController = (UIStoryboard(name: "SILDropDown", bundle: nil).instantiateViewController(withIdentifier: "SILDropDownViewController") as! SILDropDownViewController)
        window = UIWindow(frame: UIScreen.main.bounds)

        super.init()
        
        viewController.delegate = self
        viewController.sourceView = self.textField
        viewController.passthroughViews.append(self.textField)
        
        window.windowLevel = UIWindow.Level.alert + 1
        window.screen = UIScreen.main
        window.rootViewController = viewController
        
        textField.addTarget(self, action: #selector(textFieldDidBeginEditing(_:)), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(textFieldDidChangedEditing(_:)), for: .editingChanged)
        textField.addTarget(self, action: #selector(textFieldDidEndEditing(_:)), for: .editingDidEnd)
    }
    
    deinit {
        textField.removeTarget(self, action: #selector(textFieldDidBeginEditing(_:)), for: .editingDidBegin)
        textField.removeTarget(self, action: #selector(textFieldDidChangedEditing(_:)), for: .editingChanged)
        textField.removeTarget(self, action: #selector(textFieldDidEndEditing(_:)), for: .editingDidEnd)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        DispatchQueue.main.async {
            self.updateDropDown()
        }
    }
    
    func textFieldDidChangedEditing(_ textField: UITextField) {
        updateDropDown()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateDropDown()
    }
    
    private func updateDropDown() {
        if isEditing == false {
            hideDropDown()
        } else {
            let matchingValues = findMatchingValues()
            viewController.update(values: matchingValues)
            
            if matchingValues.count == 0 {
                hideDropDown()
            } else if matchingValues.count == 1 && matchingValues.first! == inputText {
                hideDropDown()
            } else {
                showDropDown()
            }
        }
    }
    
    private func findMatchingValues() -> [String] {
        let input = inputText.lowercased()
        
        return values.filter({ value in
            return value.lowercased().contains(input) || input == ""
        })
    }
    
    private func showDropDown() {
        if window.isHidden {
            viewController.updatePosition()
            window.isHidden = false
        }
    }
    
    private func hideDropDown() {
        if !window.isHidden {
            window.isHidden = true
        }
    }

    // MARK: SILDropDownViewControllerDelegate
    
    func dropDownDidSelect(value: String) {
        textField.text = value
        textField.sendActions(for: .editingChanged)
        textField.resignFirstResponder()
    }
    
    func dropDownBackgroundTapped() {
        textField.resignFirstResponder()
    }
}
