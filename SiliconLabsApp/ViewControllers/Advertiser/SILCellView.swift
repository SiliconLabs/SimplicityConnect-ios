//
//  SILCellView.swift
//  BlueGecko
//
//  Created by Michał Lenart on 01/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILCellView {
    func setViewModel(_ viewModel: SILCellViewModel)
}

protocol SILAdvertiserHomeCellView : SILCell, SILCellView { }
