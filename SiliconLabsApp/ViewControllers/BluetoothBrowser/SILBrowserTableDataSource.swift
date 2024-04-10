//
//  SILBrowserTableDataSource.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 27/12/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

@objc class SILBrowserTableDataSource : NSObject, UITableViewDataSource {
    var browserViewModel : BrowserViewModel
    weak var cellDelegate : SILBrowserDeviceViewCellDelegate?
    
    @objc init(browserViewModel: BrowserViewModel, cellDelegate: SILBrowserDeviceViewCellDelegate? = nil) {
        self.browserViewModel = browserViewModel
        self.cellDelegate = cellDelegate
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionViewModel = self.browserViewModel.peripheralViewModel(at: section) else { return 0 }
        
//        return sectionViewModel.isExpanded ? sectionViewModel.advertisementDataViewModels.count : 1
        // Add one cell count to show Manufacturer data, because cell count start from 1.
        return sectionViewModel.isExpanded ? sectionViewModel.advertisementDataViewModels.count + 1 : 1

    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellType = indexPath.row == 0 ? SILClassBrowserDeviceViewCell : SILClassBrowserServiceViewCell
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellType)!
        
        if indexPath.row == 0 {
            self.setupDeviceCell(cell, at: indexPath)
        } else {
            self.setupAdTypeCell(cell, at: indexPath)
        }
        
        return cell
    }
    
    func setupDeviceCell(_ cell: UITableViewCell, at indexPath : IndexPath) {
        guard let cell = cell as? SILBrowserDeviceViewCell,
              let sectionViewModel = self.browserViewModel.peripheralViewModel(at: indexPath.section)
        else { return }
        
        cell.viewModel = sectionViewModel
        cell.delegate = cellDelegate
        cell.configure()
    }
    
    func setupAdTypeCell(_ cell: UITableViewCell, at indexPath : IndexPath) {
        guard let cell = cell as? SILBrowserDeviceAdTypeViewCell,
              let sectionViewModel = self.browserViewModel.peripheralViewModel(at: indexPath.section)
        else { return }
        
        let viewModel = indexPath.row <= sectionViewModel.advertisementDataViewModels.count ? sectionViewModel.advertisementDataViewModels[indexPath.row - 1] : nil
        
        cell.viewModel = viewModel
        cell.configure()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        self.browserViewModel.discoveredPeripheralsViewModels.count
    }
}
