//
//  SILCharacteristicWriteViewController.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 23/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit
import CoreBluetooth

class SILCharacteristicWriteViewController: SILDebugPopoverViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var serviceNameLabel: UILabel!
    @IBOutlet weak var characteristicNameLabel: UILabel!
    @IBOutlet weak var characteristicUUIDLabel: UILabel!
    @IBOutlet weak var fieldsTableView: UITableView!
    @IBOutlet weak var writeRequestView: SILRadioButton!
    @IBOutlet weak var writeCommandView: SILRadioButton!
    private var popoverController: WYPopoverController?
    
    private var viewModel: SILCharacteristicWriteViewModel
    
    override var preferredContentSize: CGSize {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return CGSize(width: 540.0, height: 350.0)
            } else {
                return CGSize(width: 308.0, height: 350.0)
            }
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    @objc init(characteristic: CBCharacteristic,
               delegate: SILCharacteristicEditEnablerDelegate) {
        viewModel = SILCharacteristicWriteViewModel(characteristic: characteristic, delegate: delegate)
        
        super.init(nibName: "SILCharacteristicWriteViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupValuesInHeaderView()
        addGestureRecognizersForRadioButtonsView()
        setupFieldsTableView()
        viewModel.updateRadioButton { [weak self] newState in self?.updateRadioButtons(with: newState) }
    }
    
    private func setupValuesInHeaderView() {
        serviceNameLabel.text = viewModel.assosiatedService.name
        characteristicNameLabel.text = viewModel.characteristic.name
        characteristicUUIDLabel.text = viewModel.characteristic.hexUuidString
    }
    
    private func updateRadioButtons(with newState: SILCharacteristicWriteRadioButtonState) {
        switch newState {
        case .supportOnlyWriteCommand:
            writeRequestView.disable()
            writeCommandView.select()
        case .supportOnlyWriteRequest:
            writeRequestView.select()
            writeCommandView.disable()
        case .writeCommandSelected:
            writeRequestView.deselect()
            writeCommandView.select()
        case .writeRequestSelected:
            writeRequestView.select()
            writeCommandView.deselect()
        case .unknown:
            break
        }
    }
    
    private func addGestureRecognizersForRadioButtonsView() {
        let tapWriteRequestView = UITapGestureRecognizer(target: self, action: #selector(tapWriteRequestView(_:)))
        writeRequestView.addGestureRecognizer(tapWriteRequestView)
        
        let tapWriteResponseView = UITapGestureRecognizer(target: self, action: #selector(tapWriteCommandView(_:)))
        writeCommandView.addGestureRecognizer(tapWriteResponseView)
    }
    
    private func setupFieldsTableView() {
        self.fieldsTableView.delegate = self
        self.fieldsTableView.dataSource = self
        self.fieldsTableView.register(UINib(nibName: "SILCharacteristicWriteFieldTableViewCell", bundle: nil),
                                      forCellReuseIdentifier: "characteristicWriteField")
        self.fieldsTableView.register(UINib(nibName: "SILCharacteristicWriteEnumListTableViewCell", bundle: nil),
                                      forCellReuseIdentifier: "characteristicEnumList")
        self.fieldsTableView.register(UINib(nibName: "SILDebugCharacteristicEncodingFieldEntryCell", bundle: nil),
                                      forCellReuseIdentifier: "characteristicWriteEncoding")
        self.fieldsTableView.tableFooterView = UIView()
    }
    
    @IBAction func exitButtonWasTapped(_ sender: UIButton) {
        closeView()
    }
    
    @objc func tapWriteRequestView(_ sender: UITapGestureRecognizer?) {
        viewModel.updateRadioButton(writeRequestButtonSelected: true,
                                    completion: { [weak self] newState in self?.updateRadioButtons(with: newState) })
    }
    
    @objc func tapWriteCommandView(_ sender: UITapGestureRecognizer?) {
        viewModel.updateRadioButton(writeCommandButtonSelected: true,
                                    completion: { [weak self] newState in self?.updateRadioButtons(with: newState)})
    }
 
    @IBAction func clearButtonWasTapped(_ sender: UIButton) {
        viewModel.clear { [weak self] in self?.fieldsTableView.reloadData() }
    }
    
    @IBAction func sendButtonWasTapped(_ sender: Any) {
        viewModel.send { [weak self] error in
            if let error = error {
                switch error {
                case .parsingError(let description):
                    self?.showToast(message: description ,
                                    toastType: .characteristicError,
                                    completion: {})
                }
            } else {
                self?.closeView()
            }
        }
    }
        
    private func closeView() {
        popoverDelegate?.didClose(self)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellViewModel = viewModel.getCellViewModel(at: indexPath)
        
        if let encodingCellViewModel = cellViewModel as? SILCharacteristicWriteEncodingFieldCellViewModel {
            let cell = tableView.dequeueReusableCell(withIdentifier: "characteristicWriteEncoding", for: indexPath) as! SILDebugCharacteristicEncodingFieldEntryCell
            cell.typeLabel?.text = encodingCellViewModel.titleName
            cell.valueTextField?.text = encodingCellViewModel.currentValue
            cell.index = encodingCellViewModel.index
            cell.delegate = self
            cell.selectionStyle = .none
            return cell
        } else if let fieldCellViewModel = cellViewModel as? SILCharacteristicWriteFieldCellViewModel {
            let cell = tableView.dequeueReusableCell(withIdentifier: "characteristicWriteField", for: indexPath) as! SILCharacteristicWriteFieldTableViewCell
            cell.setupCell(using: fieldCellViewModel)
            cell.selectionStyle = .none
            
            return cell
        } else if let enumListCellViewModel = cellViewModel as? SILCharacteristicWriteEnumListCellViewModel {
            let cell = tableView.dequeueReusableCell(withIdentifier: "characteristicEnumList", for: indexPath) as! SILCharacteristicWriteEnumListTableViewCell
            cell.setupCell(using: enumListCellViewModel)
            cell.selectionStyle = .none
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellViewModel = viewModel.getCellViewModel(at: indexPath)
        if let enumListViewModel = cellViewModel as? SILCharacteristicWriteEnumListCellViewModel {
            let enumListViwController = SILCharacteristicWriteEnumOptionsTableViewController(enumListCellViewModel: enumListViewModel)
            enumListViwController.delegate = self
            self.popoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: enumListViwController, presenting:self, delegate:self as? WYPopoverControllerDelegate, animated:true)
        }
    }
}

extension SILCharacteristicWriteViewController: SILCharacteristicWriteEnumOptionsTableViewControllerDelegate {
    func shouldCloseEnumOptionsTableViewController(_ enumOptionsTableViewController: SILCharacteristicWriteEnumOptionsTableViewController) {
        self.popoverController?.dismissPopover(animated: true) { [weak self] in
            self?.popoverController = nil
            self?.fieldsTableView.reloadData()
        }
    }
}

extension SILCharacteristicWriteViewController: SILDebugCharacteristicEncodingFieldEntryCellDelegate {
    func changeText(_ text: String, in textField: SILEncodingTextField, at index: Int) {
        viewModel.updateEncodings(with: text, at: index) { [weak self] error in
            if index == 2, let _ = error {
                self?.showToast(message: "Value is invalid. You have to input max 3 digits side by side and max value is 255",
                                toastType: .characteristicError,
                                completion: {})
            }
            self?.updateCellsWithoutReloadingTable()
        }
    }
    
    func pasteButtonWasClicked(with textField: SILEncodingTextField, at index: Int) {
        let pasteboard = UIPasteboard.general
        if let copiedString = pasteboard.string {
            viewModel.updateEncodings(with: copiedString, at: index) { [weak self, textField] error in
                if let _ = error {
                    self?.showToast(message: "Incorrect data format",
                                    toastType: .characteristicPasteAlert,
                                    shouldHasSizeOfText: true, completion: {})
                } else {
                    self?.updateCellsWithoutReloadingTable()
                    textField.becomeFirstResponder()
                }
            }
        }
    }
    
    private func updateCellsWithoutReloadingTable() {
        if let hexCell = fieldsTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? SILDebugCharacteristicEncodingFieldEntryCell,
            let hexCellViewModel = viewModel.getCellViewModel(at: IndexPath(row: 0, section: 0)) as? SILCharacteristicWriteEncodingFieldCellViewModel {
            hexCell.valueTextField!.text = hexCellViewModel.currentValue
        }
        if let asciiCell = fieldsTableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? SILDebugCharacteristicEncodingFieldEntryCell,
            let asciiCellViewModel = viewModel.getCellViewModel(at: IndexPath(row: 1, section: 0)) as? SILCharacteristicWriteEncodingFieldCellViewModel {
            asciiCell.valueTextField!.text = asciiCellViewModel.currentValue
        }
        if let decimalCell = fieldsTableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? SILDebugCharacteristicEncodingFieldEntryCell,
            let decimalCellViewModel = viewModel.getCellViewModel(at: IndexPath(row: 2, section: 0)) as? SILCharacteristicWriteEncodingFieldCellViewModel {
            decimalCell.valueTextField!.text = decimalCellViewModel.currentValue
        }
    }
}
