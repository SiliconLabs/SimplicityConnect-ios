//
//  SILScanResponseValueCellViewModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 04/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILScanResponseValueCellViewModel: SILCellViewModel {
    let reusableIdentifier: String = "SILScanResponseValueCellView"

    let value: String
    
    init(value: String) {
        self.value = value
    }
}
