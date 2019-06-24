//
//  DebugDeviceFilterViewController.swift
//  SiliconLabsApp
//
//  Created by Max Litteral on 7/25/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

import UIKit

@objc(SILDebugDeviceFilterViewControllerDelegate)
protocol DebugDeviceFilterViewControllerDelegate: class {
    func debugDeviceFilterViewControllerDidCancel(_ viewController: DebugDeviceFilterViewController)
    func debugDeviceFilterViewControllerDidApplyFilter(name: String?, rssi: NSNumber?, viewController: DebugDeviceFilterViewController)
}

@objc(SILDebugDeviceFilterViewController)
@objcMembers
final class DebugDeviceFilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TextFieldTableViewCellDelegate, RSSISliderTableViewCellDelegate {

    // MARK: - Properties

    weak var delegate: DebugDeviceFilterViewControllerDelegate? = nil

    private let viewModel = DebugDeviceFilterViewModel()

    @IBOutlet private weak var tableView: UITableView!

    override var preferredContentSize: CGSize {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return CGSize(width: 540, height: 274)
            } else {
                return CGSize(width: UIScreen.main.bounds.width - 24, height: 250)
            }
        }
        set { }
    }

    // MARK: - Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @objc init(query: String?, rssi: NSNumber?) {
        super.init(nibName: nil, bundle: nil)

        if let query = query {
            viewModel.applyFilter(.name(containing: query))
        }

        if let rssi = rssi?.intValue {
            viewModel.applyFilter(.rssi(greaterThan: rssi))
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    // MARK: - Actions

    @IBAction func cancelButtonTapped() {
        delegate?.debugDeviceFilterViewControllerDidCancel(self)
    }

    @IBAction func applyButtonTapped() {
        for cell in tableView.visibleCells {
            if let cell = cell as? TextFieldTableViewCell {
                _ = cell.resignFirstResponder()
            }
        }
        delegate?.debugDeviceFilterViewControllerDidApplyFilter(name: viewModel.nameQuery,
                                                                rssi: viewModel.rssi?.number,
                                                                viewController: self)
    }

    @IBAction private func resetButtonTapped() {
        viewModel.resetFilter()
        tableView.reloadData()
    }

    // MARK: Setup

    private func setup() {
        setupTableView()
    }

    private func setupTableView() {
        tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: TextFieldTableViewCell.cellIdentifier)
        tableView.register(RSSISliderTableViewCell.self, forCellReuseIdentifier: RSSISliderTableViewCell.cellIdentifier)

        tableView.separatorInset = .zero
        tableView.separatorStyle = .none
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfFiltersAvailable
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: TextFieldTableViewCell.cellIdentifier, for: indexPath) as! TextFieldTableViewCell
            cell.placeholder = "Search by Name"
            cell.textFieldText = viewModel.nameQuery
            cell.delegate = self
            cell.selectionStyle = .none
            return cell
        } else if indexPath.row >= 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: RSSISliderTableViewCell.cellIdentifier, for: indexPath) as! RSSISliderTableViewCell
            cell.initialValue = viewModel.rssi
            cell.delegate = self
            return cell
        } else {
            fatalError("Invalid table row")
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 64
        } else if indexPath.row == 1 {
            return 92
        }

        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let cell = tableView.cellForRow(at: indexPath) as? TextFieldTableViewCell {
            _ = cell.becomeFirstResponder()
        }
    }

    // MARK: - TextFieldTableViewCellDelegate

    func textFieldDidEndEditing(_ textField: UITextField) {
        if let query = textField.text, !query.isEmpty {
            viewModel.applyFilter(.name(containing: query))
        } else {
            viewModel.removeFilter(of: .name)
        }
    }

    // MARK: - RSSISliderTableViewCellDelegate

    func rssiValueDidChange(_ newValue: Int) {
        viewModel.applyFilter(.rssi(greaterThan: newValue))
    }
}
