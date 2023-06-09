//
//  SILESLDemoTagDetailViewModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 27.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation

class SILESLDemoTagDetailViewModel: SILCellViewModel {
    let reusableIdentifier: String = "TagDetailCell"
    let tagDetailName: String
    let tagDetailValue: String
    
    init(tagDetailName: String, tagDetailValue: String) {
        self.tagDetailName = tagDetailName
        self.tagDetailValue = tagDetailValue
    }
}
