//
//  SILCreateGattServiceViewController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 16/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import UIKit

class SILCreateGattServiceViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var serviceTypePicker: UIView!
    @IBOutlet weak var serviceTypePickerLabel: UILabel!
    @IBOutlet weak var serviceTypePickerCollapseImage: UIImageView!
    @IBOutlet weak var serviceNameField: UITextField!
    @IBOutlet weak var serviceUUIDField: UITextField!
    @IBOutlet weak var mandatoryServicesLabel: UILabel!
    @IBOutlet weak var mandatoryServicesCheckBox: SILCheckBox!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var bluetoothSIGButton: SILPrimaryButton!
    
    var viewModel: SILCreateGattServiceViewModel!
    
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
        setupServiceTypePicker()
        mandatoryServicesCheckBox.isChecked = viewModel.shouldAddMandatoryServiceRequirements
        titleLabel.text = "Add a GATT Service"
    }
    
    func setupServiceTypePicker() {
        serviceTypePicker.layer.borderWidth = 1
        serviceTypePicker.layer.borderColor = UIColor.black.cgColor
        serviceTypePicker.layer.cornerRadius = CornerRadiusForButtons
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(onServiceTypePickerTouch(_:)))
        serviceTypePicker.addGestureRecognizer(recognizer)
    }
    
    func setupLogic() {
        dropDownName = SILDropDown(textField: serviceNameField, values: viewModel.autocompleteValues, delegate: viewModel)
        dropDownUUID = SILDropDown(textField: serviceUUIDField, values: viewModel.autocompleteValues, delegate: viewModel)
        serviceNameField.addTarget(self, action: #selector(onServiceNameChange(_:)), for: .editingChanged)
        serviceUUIDField.addTarget(self, action: #selector(onServiceUUIDChange(_:)), for: .editingChanged)
        [serviceNameField, serviceUUIDField].forEach { $0?.tintColor = UIColor.sil_regularBlue()}
        
        let mandatoryServicesLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(onMandatoryServicesLabelTap(_:)))
        mandatoryServicesLabel.addGestureRecognizer(mandatoryServicesLabelTapGesture)

        weak var weakSelf = self
        
        viewModel.isClearButtonEnabled.observe { enabled in
            weakSelf?.clearButton.isEnabled = enabled
        }.putIn(bag: tokenBag)
        
        viewModel.isSaveButtonEnabled.observe { enabled in
            weakSelf?.saveButton.isEnabled = enabled
            weakSelf?.saveButton.backgroundColor = enabled ? UIColor.systemBlue : UIColor.lightGray
        }.putIn(bag: tokenBag)
        
        viewModel.isSelected16BitService.observe { enabled in
            weakSelf?.mandatoryServicesCheckBox.isEnabled = enabled
            weakSelf?.serviceTypePicker.isUserInteractionEnabled = !enabled
            weakSelf?.serviceTypePickerCollapseImage.isHidden = enabled
            if enabled {
                weakSelf?.viewModel.update(serviceIsPrimary: true)
            }
            weakSelf?.view.setNeedsLayout()
            weakSelf?.view.layoutIfNeeded()
        }.putIn(bag: tokenBag)
    }
    
    @objc func onServiceTypePickerTouch(_ sender: UITapGestureRecognizer) {
        SILContextMenu.present(owner: self, sourceView: serviceTypePicker, alignWithSourceViewWidth: true, options: [
            ContextMenuOption(enabled: true, title: "Primary Service") { [weak self] in
                debugPrint("primary selected")
                self?.viewModel.update(serviceIsPrimary: true)
            },
            ContextMenuOption(enabled: true, title: "Secondary Service") { [weak self] in
                debugPrint("secondary selected")
                self?.viewModel.update(serviceIsPrimary: false)
            },
        ])
    }
    
    @objc func onServiceNameChange(_ textField: UITextField) {
        uncheckMandatoryServicesCheckBoxIfNecessary()
        viewModel.update(serviceName: textField.text)
    }
    
    @objc func onServiceUUIDChange(_ textField: UITextField) {
        uncheckMandatoryServicesCheckBoxIfNecessary()
        viewModel.update(serviceUUID: textField.text)
    }
    
    private func uncheckMandatoryServicesCheckBoxIfNecessary() {
        if mandatoryServicesCheckBox.isChecked {
            mandatoryServicesCheckBox.isChecked = false
            viewModel.toggleMandatoryRequirementsCheckBox(isChecked: mandatoryServicesCheckBox.isChecked)
        }
    }
    
    @IBAction func toggleMandatoryRequirementsCheckBox(_ sender: SILCheckBox) {
        viewModel.toggleMandatoryRequirementsCheckBox(isChecked: sender.isChecked)
    }
    
    @objc func onMandatoryServicesLabelTap(_ sender: UILabel) {
        if mandatoryServicesCheckBox.isEnabled {
            mandatoryServicesCheckBox.isChecked = !mandatoryServicesCheckBox.isChecked
            viewModel.toggleMandatoryRequirementsCheckBox(isChecked: mandatoryServicesCheckBox.isChecked)
        }
    }
    
    @IBAction func onClearTouch(_ sender: UIButton) {
        viewModel.onClear()
        debugPrint("clear")
    }
    
    @IBAction func onCancelTouch(_ sender: UIButton) {
        viewModel.onCancel()
    }
    
    @IBAction func onSaveTouch(_ sender: UIButton) {
        viewModel.onSave()
    }
    
    @IBAction func onBluetoothSIGClick(_ sender: Any) {
        viewModel.openLink()
    }
    
    // MARK: UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        viewModel.uuidTextField(textField, shouldChangeCharactersIn: range, replacementString: string)
    }
}

extension SILCreateGattServiceViewController: SILCreateGattServiceViewModelDelegate {
    
    func clearTextFields() {
        debugPrint("clear")
        serviceNameField.text = nil
        serviceNameField.sendActions(for: .editingChanged)
        serviceUUIDField.text = nil
        serviceUUIDField.sendActions(for: .editingChanged)
    }
    
    func updateServiceTypePicker(type: String) {
        serviceTypePickerLabel.text = type
    }
    
    func updateServiceNameTextField(name: String?) {
        serviceNameField.text = name
        serviceNameField.sendActions(for: .editingChanged)
        serviceNameField.resignFirstResponder()
    }
    
    func updateServiceUUIDField(uuid: String?) {
        serviceUUIDField.text = uuid
        serviceUUIDField.sendActions(for: .editingChanged)
        serviceUUIDField.resignFirstResponder()
    }
}
