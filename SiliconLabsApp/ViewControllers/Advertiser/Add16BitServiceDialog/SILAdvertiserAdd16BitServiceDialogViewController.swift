//
//  SILAdvertiserAdd16BitServiceDialogViewController.swift
//  BlueGecko
//
//  Created by Michał Lenart on 12/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILAdvertiserAdd16BitServiceDialogViewController: UIViewController, SILAdvertiserAdd16BitServiceDialogViewDelegate {
    @IBOutlet weak var serviceNameTextField: SILTextField!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    var viewModel: SILAdvertiserAdd16BitServiceDialogViewModel!
        
    private var window: UIWindow?
    private var dropDown: SILDropDown?
    private var tokenBag = SILObservableTokenBag()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLogic()
    }
    
    private func setupLogic() {
        dropDown = SILDropDown(textField: serviceNameTextField, values: viewModel.autocompleteValues)
        serviceNameTextField.addTarget(self, action: #selector(onServiceNameChange(_:)), for: .editingChanged)
        
        weak var weakSelf = self
        
        viewModel.isClearButtonEnabled.observe { enabled in
            weakSelf?.clearButton.isEnabled = enabled
        }.putIn(bag: tokenBag)
        
        viewModel.isSaveButtonEnabled.observe { enabled in
            weakSelf?.saveButton.isEnabled = enabled
            weakSelf?.saveButton.backgroundColor = enabled ? UIColor.sil_regularBlue() : UIColor.lightGray
        }.putIn(bag: tokenBag)
    }
    
    override var preferredContentSize: CGSize {
        get {
            return view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    @objc func onServiceNameChange(_ textField: UITextField) {
        viewModel.update(serviceName: textField.text)
    }
    
    @IBAction func onInfo(_ sender: UIButton) {
        viewModel.onInfo()
    }
    
    @IBAction func onClear(_ sender: UIButton) {
        viewModel.onClear()
    }
    
    @IBAction func onCancel(_ sender: UIButton) {
        viewModel.onCancel()
    }
    
    @IBAction func onSave(_ sender: UIButton) {
        viewModel.onSave()
    }
    
    // MARK: SILAdvertiserAdd16BitServiceDialogViewDelegate
    
    func clearServiceName() {
        serviceNameTextField.text = nil
        serviceNameTextField.sendActions(for: .editingChanged)
    }
}
