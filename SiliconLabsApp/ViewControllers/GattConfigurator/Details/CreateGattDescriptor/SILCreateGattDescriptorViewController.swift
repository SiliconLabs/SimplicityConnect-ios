//
//  SILCreateGattCharacteristicViewController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 29/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import UIKit

class SILCreateGattDescriptorViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptorNameField: UITextField!
    @IBOutlet weak var descriptorUUIDField: UITextField!
    
    @IBOutlet weak var typeValuePicker: UIView!
    @IBOutlet weak var typeValuePickerLabel: UILabel!
    @IBOutlet weak var typeValuePickerCollapseImage: UIImageView!
    @IBOutlet weak var initialTextValueView: UIView!
    @IBOutlet weak var initialTextValueTextField: UITextField!
    @IBOutlet weak var initialHexValueView: UIView!
    @IBOutlet weak var initialHexValueTextField: UITextField!
    @IBOutlet weak var characteristicPresentationFormatInfo: UILabel!
    
    @IBOutlet weak var clearButton: SILPrimaryButton!
    @IBOutlet weak var saveButton: SILPrimaryButton!
    
    var viewModel: SILCreateGattDescriptorViewModel!
    
    private var dropDownName: SILDropDown?
    private var dropDownUUID: SILDropDown?
    private let tokenBag = SILObservableTokenBag()

    override var preferredContentSize: CGSize {
        get {
            return view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
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
        titleLabel.text = viewModel.isEditing ? "Edit the Gatt Descriptor" : "Add a GATT Descriptor"
        [descriptorNameField, descriptorUUIDField, initialTextValueTextField, initialHexValueTextField].forEach { $0?.tintColor = UIColor.sil_regularBlue() }
    }
    
    func setupLogic() {
        dropDownName = SILDropDown(textField: descriptorNameField, values: viewModel.autocompleteValues, delegate: viewModel)
        dropDownUUID = SILDropDown(textField: descriptorUUIDField, values: viewModel.autocompleteValues, delegate: viewModel)
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(onInitialValueTypePickerTouch(_:)))
        typeValuePicker.addGestureRecognizer(recognizer)
        descriptorNameField.addTarget(self, action: #selector(onDescriptorNameChange(_:)), for: .editingChanged)
        descriptorUUIDField.addTarget(self, action: #selector(onDescriptorUUIDChange(_:)), for: .editingChanged)
        initialHexValueTextField.addTarget(self, action: #selector(onDescriptorInitialValueChange(_:)), for: .editingChanged)
        initialTextValueTextField.addTarget(self, action: #selector(onDescriptorInitialValueChange(_:)), for: .editingChanged)

        weak var weakSelf = self
        
        viewModel.isClearButtonEnabled.observe { enabled in
            weakSelf?.clearButton.isEnabled = enabled
        }.putIn(bag: tokenBag)
        
        viewModel.isSaveButtonEnabled.observe { enabled in
            weakSelf?.saveButton.isEnabled = enabled
            weakSelf?.saveButton.backgroundColor = enabled ? UIColor.sil_regularBlue() : UIColor.lightGray
        }.putIn(bag: tokenBag)
        
        viewModel.descriptorTypeObservable.observe { descriptorUuidType in
            switch descriptorUuidType {
            case .uuidCharacteristicPresentationFormat:
                weakSelf?.typeValuePicker.isUserInteractionEnabled = false
                weakSelf?.typeValuePickerCollapseImage.isHidden = true
                weakSelf?.typeValuePickerLabel.text = weakSelf?.viewModel.getDescription(ofTypeValue: .hex)
                weakSelf?.initialHexValueView.isHidden = false
                weakSelf?.initialTextValueView.isHidden = true
                weakSelf?.characteristicPresentationFormatInfo.isHidden = false
            case .uuidCharacteristicUserDescription:
                weakSelf?.typeValuePicker.isUserInteractionEnabled = false
                weakSelf?.typeValuePickerCollapseImage.isHidden = true
                weakSelf?.typeValuePickerLabel.text = weakSelf?.viewModel.getDescription(ofTypeValue: .text)
                weakSelf?.initialHexValueView.isHidden = true
                weakSelf?.initialTextValueView.isHidden = false
                weakSelf?.characteristicPresentationFormatInfo.isHidden = true
            case .uuid128bit(let valueType):
                weakSelf?.typeValuePicker.isUserInteractionEnabled = true
                weakSelf?.typeValuePickerCollapseImage.isHidden = false
                weakSelf?.typeValuePickerLabel.text = weakSelf?.viewModel.getDescription(ofTypeValue: valueType)
                weakSelf?.initialHexValueView.isHidden = valueType != .hex
                weakSelf?.initialTextValueView.isHidden = valueType != .text
                weakSelf?.characteristicPresentationFormatInfo.isHidden = true
            }
        }.putIn(bag: tokenBag)
    }
    
    @objc func onInitialValueTypePickerTouch(_ sender: UITapGestureRecognizer) {
        SILContextMenu.present(owner: self, sourceView: typeValuePicker, alignWithSourceViewWidth: true, options: [
            ContextMenuOption(enabled: true, title: viewModel.getDescription(ofTypeValue: .text)) { [weak self] in
                debugPrint("text selected")
                self?.viewModel.update(descriptorInitialValueType: .text)
            },
            ContextMenuOption(enabled: true, title: viewModel.getDescription(ofTypeValue: .hex), callback: { [weak self] in
                debugPrint("hex selected")
                self?.viewModel.update(descriptorInitialValueType: .hex)
            })
        ])
    }
    
    @objc func onDescriptorNameChange(_ textField: UITextField) {
        viewModel.update(descriptorName: textField.text)
    }
    
    @objc func onDescriptorUUIDChange(_ textField: UITextField) {
        viewModel.update(descriptorUUID: textField.text)
    }
    
    @objc func onDescriptorInitialValueChange(_ textField: UITextField) {
        viewModel.update(descriptorInitialValue: textField.text)
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
        if textField.isEqual(descriptorUUIDField) {
            return viewModel.uuidTextField(textField, shouldChangeCharactersIn: range, replacementString: string)
        } else {
            return viewModel.initialHexValueTextField(textField, shouldChangeCharactersIn: range, replacementString: string)
        }
    }
}

extension SILCreateGattDescriptorViewController: SILCreateGattDescriptorViewModelDelegate {
    
    func clearTextFields() {
        debugPrint("clear")
        descriptorNameField.text = nil
        descriptorNameField.sendActions(for: .editingChanged)
        descriptorUUIDField.text = nil
        descriptorUUIDField.sendActions(for: .editingChanged)
        initialHexValueTextField.text = nil
        initialHexValueTextField.sendActions(for: .editingChanged)
        initialTextValueTextField.text = nil
        initialTextValueTextField.sendActions(for: .editingChanged)
    }
    
    func updateServiceNameTextField(name: String?) {
        descriptorNameField.text = name
        descriptorNameField.sendActions(for: .editingChanged)
        descriptorNameField.resignFirstResponder()
    }
    
    func updateServiceUUIDField(uuid: String?) {
        descriptorUUIDField.text = uuid
        descriptorUUIDField.sendActions(for: .editingChanged)
        descriptorUUIDField.resignFirstResponder()
    }
    
    func updateDescriptorInitialTextTextField(value: String?) {
        initialTextValueTextField.text = value
        initialTextValueTextField.sendActions(for: .editingChanged)
        initialTextValueTextField.resignFirstResponder()
    }
    
    func updateDescriptorInitialHexTextField(value: String?) {
        initialHexValueTextField.text = value
        initialHexValueTextField.sendActions(for: .editingChanged)
        initialHexValueTextField.resignFirstResponder()
    }
}

