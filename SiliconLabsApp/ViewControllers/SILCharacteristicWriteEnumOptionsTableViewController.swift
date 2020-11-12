//
//  SILCharacteristicWriteEnumOptionsTableViewController.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 30/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILCharacteristicWriteEnumOptionsTableViewController: UITableViewController {
    var delegate: SILCharacteristicWriteEnumOptionsTableViewControllerDelegate!
    private let enumListCellViewModel: SILCharacteristicWriteEnumListCellViewModel?
    
    override var preferredContentSize: CGSize {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return CGSize(width: 250.0, height: 300.0)
            } else {
                return CGSize(width: 250.0, height: 250.0)
            }
        }
        set {
            super.preferredContentSize = newValue
        }
    }
       
    init(enumListCellViewModel: SILCharacteristicWriteEnumListCellViewModel) {
        self.enumListCellViewModel = enumListCellViewModel
           
        super.init(nibName: "SILCharacteristicWriteEnumOptionsTableViewController", bundle: nil)
    }
       
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "SILCharacteristicWriteEnumOptionsTableViewCell", bundle: nil),
                                      forCellReuseIdentifier: "characteristicWriteEnumOptions")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return enumListCellViewModel?.allPossibleValues.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "characteristicWriteEnumOptions", for: indexPath) as! SILCharacteristicWriteEnumOptionsTableViewCell
        cell.nameLabel.text = enumListCellViewModel?.allPossibleValues[indexPath.row].value
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        enumListCellViewModel?.currentValue = indexPath.row
        delegate!.shouldCloseEnumOptionsTableViewController(self)
    }
}
