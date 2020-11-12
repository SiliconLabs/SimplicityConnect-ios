//
//  SILAdvertiserAdTypeCellViewModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 12/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILAdvertiserAdTypeCellViewModel: SILCellViewModel {
    var reusableIdentifier: String = "SILAdvertiserAdTypeCellView"
    
    let title: String
    let value: String
    
    init(title: String,
         value: String) {
        self.title = title
        self.value = value
    }
}
