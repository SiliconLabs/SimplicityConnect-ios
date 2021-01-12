//
//  SILSortViewController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 10/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@objc
protocol SILSortViewControllerDelegate: class {
    @objc(sortOptionWasSelectedWithOption:)
     func sortOptionWasSelected(with option: SILSortOption)
}

class SILSortViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var sortSettingTable: UITableView!
    
    var viewModel: SILSortViewModel!
    @objc var delegate: SILSortViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = SILSortViewModel.sharedInstance()
        sortSettingTable.dataSource = self
        sortSettingTable.delegate = self
        sortSettingTable.tableFooterView = UIView(frame: .zero)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].modes.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.cellHeight(forIndexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = viewModel.sections[indexPath.section]
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SILSortTypeViewCell", for: indexPath) as! SILSortTypeViewCell
            cell.typeLabel.text = section.type
            cell.isUserInteractionEnabled = false
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SILSortModeViewCell", for: indexPath) as! SILSortModeViewCell
            cell.sortModeLabel.text = section.modes[indexPath.row - 1].modeName
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row != 0, viewModel.isSelected(forIndexPath: indexPath) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row != 0 {
            viewModel.selectOption(forIndexPath: indexPath)
            delegate?.sortOptionWasSelected(with: viewModel.selectedOption)
            self.sortSettingTable.reloadData()
        }
    }
}
