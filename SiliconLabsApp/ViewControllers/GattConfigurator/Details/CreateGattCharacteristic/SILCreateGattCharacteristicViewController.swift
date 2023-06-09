//
//  SILCreateGattCharacteristicViewController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 29/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import UIKit

class SILCreateGattCharacteristicViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var characteristicNameField: SILTextField!
    @IBOutlet weak var characteristicUUIDField: SILTextField!
    
    @IBOutlet weak var readSwitch: SILSwitch!
    @IBOutlet weak var writeSwitch: SILSwitch!
    @IBOutlet weak var writeWithoutResponseSwitch: SILSwitch!
    @IBOutlet weak var notifySwitch: SILSwitch!
    @IBOutlet weak var indicateSwitch: SILSwitch!
    
    @IBOutlet var switches: [SILSwitch]!
    
    @IBOutlet weak var readCheckBox: SILCheckBox!
    @IBOutlet weak var writeCheckBox: SILCheckBox!
    @IBOutlet weak var notifyIndicateCheckBox: SILCheckBox!
    
    @IBOutlet var checkBoxes: [SILCheckBox]!
    
    @IBOutlet weak var typeValuePicker: UIView!
    @IBOutlet weak var typeValuePickerLabel: UILabel!
    @IBOutlet weak var initialTextValueView: UIView!
    @IBOutlet weak var initialTextValueTextField: UITextField!
    @IBOutlet weak var initialHexValueView: UIView!
    @IBOutlet weak var initialHexValueTextField: UITextField!
    
    @IBOutlet weak var clearButton: SILPrimaryButton!
    @IBOutlet weak var saveButton: SILPrimaryButton!
    
    var viewModel: SILCreateGattCharacteristicViewModel!
    
    private var dropDownName: SILDropDown?
    private var dropDownUUID: SILDropDown?
    private let tokenBag = SILObservableTokenBag()

    override var preferredContentSize: CGSize {
        get {
            let width = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
            return CGSize(width: width, height: 500)
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupLogic()
        viewModel.updateView()
    }
    
    func setupAppearance() {
        typeValuePicker.layer.borderWidth = 1
        typeValuePicker.layer.borderColor = UIColor.sil_masala()?.cgColor
        typeValuePicker.layer.cornerRadius = CornerRadiusForButtons
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(onInitialValueTypePickerTouch(_:)))
        typeValuePicker.addGestureRecognizer(recognizer)
        titleLabel.text = viewModel.isEditing ? "Edit the Gatt Characteristic" : "Add a GATT Characteristic"
        readCheckBox.isChecked = viewModel.characteristicPermissionsMap[.read]! == .bonded
        writeCheckBox.isChecked = viewModel.characteristicPermissionsMap[.write]! == .bonded
    }
    
    func setupLogic() {
        dropDownName = SILDropDown(textField: characteristicNameField, values: viewModel.autocompleteValues, delegate: viewModel)
        dropDownUUID = SILDropDown(textField: characteristicUUIDField, values: viewModel.autocompleteValues, delegate: viewModel)
        characteristicNameField.addTarget(self, action: #selector(onCharacteristicNameChange(_:)), for: .editingChanged)
        characteristicUUIDField.addTarget(self, action: #selector(onCharacteristicUUIDChange(_:)), for: .editingChanged)
        initialHexValueTextField.addTarget(self, action: #selector(onCharacteristicInitialValueChange(_:)), for: .editingChanged)
        initialTextValueTextField.addTarget(self, action: #selector(onCharacteristicInitialValueChange(_:)), for: .editingChanged)
        [characteristicNameField, characteristicUUIDField, initialHexValueTextField, initialTextValueTextField].forEach { $0?.tintColor = UIColor.sil_regularBlue() }
        
        switches.forEach( { _switch in
            _switch.addTarget(self, action: #selector(onSwitchChange(_:)), for: .valueChanged)
        })
        checkBoxes.forEach({ checkBox in
            checkBox.addTarget(self, action: #selector(onCheckBoxChange(_:)), for: .valueChanged)
        })

        weak var weakSelf = self
        
        viewModel.isClearButtonEnabled.observe { enabled in
            weakSelf?.clearButton.isEnabled = enabled
        }.putIn(bag: tokenBag)
        
        viewModel.isSaveButtonEnabled.observe { enabled in
            weakSelf?.saveButton.isEnabled = enabled
            weakSelf?.saveButton.backgroundColor = enabled ? UIColor.sil_regularBlue() : UIColor.lightGray
        }.putIn(bag: tokenBag)
        observeProperties()
        updateCheckboxes()
    }
    
    func observeProperties() {
        weak var weakSelf = self

        viewModel.propertyMap[.read]!.observe { isSet in
            weakSelf?.readSwitch.isOn = isSet
            weakSelf?.readCheckBox.isEnabled = isSet
        }.putIn(bag: tokenBag)
        
        viewModel.propertyMap[.write]!.observe { isSet in
            weakSelf?.writeSwitch.isOn = isSet
            weakSelf?.writeCheckBox.isEnabled = weakSelf?.viewModel.isWriteCheckboxEnabled ?? false
        }.putIn(bag: tokenBag)
        
        viewModel.propertyMap[.writeWithoutResponse]!.observe { isSet in
            weakSelf?.writeWithoutResponseSwitch.isOn = isSet
            weakSelf?.writeCheckBox.isEnabled = weakSelf?.viewModel.isWriteCheckboxEnabled ?? false
        }.putIn(bag: tokenBag)
        
        viewModel.propertyMap[.notify]!.observe { isSet in
            weakSelf?.notifySwitch.isOn = isSet
            weakSelf?.notifyIndicateCheckBox.isEnabled = weakSelf?.viewModel.isNotifyIndicateCheckboxEnabled ?? false
        }.putIn(bag: tokenBag)
        
        viewModel.propertyMap[.indicate]!.observe { isSet in
            weakSelf?.indicateSwitch.isOn = isSet
            weakSelf?.notifyIndicateCheckBox.isEnabled = weakSelf?.viewModel.isNotifyIndicateCheckboxEnabled ?? false
        }.putIn(bag: tokenBag)
    }
    
    private func updateCheckboxes() {
        for property in SILCreateGattCharacteristicViewModel.PermissionType.allCases {
            switch property {
            case .read:
                readCheckBox.isChecked = viewModel.characteristicPermissionsMap[property]! == .bonded
            case .write:
                writeCheckBox.isChecked = viewModel.characteristicPermissionsMap[property]! == .bonded
            case .notifyIndicate:
                notifyIndicateCheckBox.isChecked = viewModel.characteristicPermissionsMap[property]! == .bonded
            }
        }
    }
    
    @objc func onInitialValueTypePickerTouch(_ sender: UITapGestureRecognizer) {
        SILContextMenu.present(owner: self, sourceView: typeValuePicker, alignWithSourceViewWidth: true, options: [
            ContextMenuOption(enabled: true, title: viewModel.getDescription(ofTypeValue: .none)) { [weak self] in
                debugPrint("none selected")
                self?.viewModel.update(characteristicInitialValueType: .none)
                self?.scrollToBottom()
            },
            ContextMenuOption(enabled: true, title: viewModel.getDescription(ofTypeValue: .text)) { [weak self] in
                debugPrint("text selected")
                self?.viewModel.update(characteristicInitialValueType: .text)
                self?.scrollToBottom()
            },
            ContextMenuOption(enabled: true, title: viewModel.getDescription(ofTypeValue: .hex), callback: { [weak self] in
                debugPrint("hex selected")
                self?.viewModel.update(characteristicInitialValueType: .hex)
                self?.scrollToBottom()
            })
        ])
    }
    
    private func scrollToBottom() {
        view.setNeedsLayout()
        view.layoutIfNeeded()
        let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.size.height)
        scrollView.setContentOffset(bottomOffset, animated: true)
    }
    
    @objc func onSwitchChange(_ silSwitch: SILSwitch) {
        switch silSwitch {
        case readSwitch:
            viewModel.update(property: .read, isSet: silSwitch.isOn)
        case writeSwitch:
            viewModel.update(property: .write, isSet: silSwitch.isOn)
        case writeWithoutResponseSwitch:
            viewModel.update(property: .writeWithoutResponse, isSet: silSwitch.isOn)
        case notifySwitch:
            viewModel.update(property: .notify, isSet: silSwitch.isOn)
        case indicateSwitch:
            viewModel.update(property: .indicate, isSet: silSwitch.isOn)
        default:
            break
        }
    }
    
    @objc func onCheckBoxChange(_ checkBox: SILCheckBox) {
        let permission: SILGattConfigurationAttributePermission = checkBox.isChecked ? .bonded : .none
        switch checkBox {
        case readCheckBox:
            viewModel.update(permission: permission, withType: .read)
        case writeCheckBox:
            viewModel.update(permission: permission, withType: .write)
        case notifyIndicateCheckBox:
            viewModel.update(permission: permission, withType: .notifyIndicate)
        default:
            break
        }
    }
    
    
    @objc func onCharacteristicNameChange(_ textField: UITextField) {
        viewModel.update(characteristicName: textField.text)
    }
    
    @objc func onCharacteristicUUIDChange(_ textField: UITextField) {
        viewModel.update(characteristicUUID: textField.text)
    }
    
    @objc func onCharacteristicInitialValueChange(_ textField: UITextField) {
        viewModel.update(characteristicInitialValue: textField.text)
    }
    
    @IBAction func onClearTouch(_ sender: UIButton) {
        viewModel.onClear()
    }
    
    @IBAction func onCancelTouch(_ sender: UIButton) {
        viewModel.onCancel()
    }
    
    @IBAction func onSaveTouch(_ sender: UIButton) {
        viewModel.onSave()
    }
    
    // MARK: UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.isEqual(characteristicUUIDField) {
            return viewModel.uuidTextField(textField, shouldChangeCharactersIn: range, replacementString: string)
        } else {
            return viewModel.initialHexValueTextField(textField, shouldChangeCharactersIn: range, replacementString: string)
        }
    }
}

extension SILCreateGattCharacteristicViewController: SILCreateGattCharacteristicViewModelDelegate {
    
    func clearTextFields() {
        debugPrint("clear")
        characteristicNameField.text = nil
        characteristicNameField.sendActions(for: .editingChanged)
        characteristicUUIDField.text = nil
        characteristicUUIDField.sendActions(for: .editingChanged)
        initialHexValueTextField.text = nil
        initialHexValueTextField.sendActions(for: .editingChanged)
        initialTextValueTextField.text = nil
        initialTextValueTextField.sendActions(for: .editingChanged)
    }
    
    func updateTypeValuePicker(type: SILGattConfigurationValueType) {
        typeValuePickerLabel.text = viewModel.getDescription(ofTypeValue: type)
        switch type {
        case .none:
            initialTextValueView.isHidden = true
            initialHexValueView.isHidden = true
        case .text:
            initialTextValueView.isHidden = false
            initialHexValueView.isHidden = true
        case .hex:
            initialTextValueView.isHidden = true
            initialHexValueView.isHidden = false
        }
    }
    
    func updateServiceNameTextField(name: String?) {
        characteristicNameField.text = name
        characteristicNameField.sendActions(for: .editingChanged)
        characteristicNameField.resignFirstResponder()
    }
    
    func updateServiceUUIDField(uuid: String?) {
        characteristicUUIDField.text = uuid
        characteristicUUIDField.sendActions(for: .editingChanged)
        characteristicUUIDField.resignFirstResponder()
    }
    
    func updateCharacteristicInitialTextTextField(value: String?) {
        initialTextValueTextField.text = value
        initialTextValueTextField.sendActions(for: .editingChanged)
        initialTextValueTextField.resignFirstResponder()
    }
    
    func updateCharacteristicInitialHexTextField(value: String?) {
        initialHexValueTextField.text = value
        initialHexValueTextField.sendActions(for: .editingChanged)
        initialHexValueTextField.resignFirstResponder()
    }
}

