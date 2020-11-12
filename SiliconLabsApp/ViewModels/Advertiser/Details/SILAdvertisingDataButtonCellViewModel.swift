//
//  SILAdvertisingDataButtonCellViewModel.swift
//  BlueGecko
//
//  Created by Michał Lenart on 01/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILAdvertisingDataButtonCellViewModel: SILCellViewModel {
    let reusableIdentifier: String = "SILAdvertisingDataButtonCellView"
    
    let title: String
    private let onClick: () -> Void
    
    init(title: String, onClick: @escaping () -> Void) {
        self.title = title
        self.onClick = onClick
    }
    
    func click() {
        onClick()
    }
}
