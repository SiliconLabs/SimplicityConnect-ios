//
//  SILAdvertisingDataButtonCellView.swift
//  BlueGecko
//
//  Created by Michał Lenart on 01/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILAdvertisingDataButtonCellView: UITableViewCell, SILCellView {
    @IBOutlet weak var button: UIButton!
    
    var viewModel: SILAdvertisingDataButtonCellViewModel? {
        didSet {
            updateView()
        }
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = (viewModel as! SILAdvertisingDataButtonCellViewModel)
    }
    
    override func prepareForReuse() {
        viewModel = nil
    }
    
    func updateView() {
        button.setTitle(viewModel?.title, for: UIControl.State.normal)
    }
    
    @IBAction func onButtonTouch(_ sender: Any) {
        viewModel?.click()
    }
}
