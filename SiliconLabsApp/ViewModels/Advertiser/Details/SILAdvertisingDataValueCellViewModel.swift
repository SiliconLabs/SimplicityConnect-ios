//
//  SILAdvertisingDataValueCellViewModel.swift
//  BlueGecko
//
//  Created by Michał Lenart on 01/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILAdvertisingDataValueCellViewModel: SILCellViewModel {
    let reusableIdentifier: String = "SILAdvertisingDataValueCellView"

    let value: String
    var hasDeleteButton: Bool { onDelete != nil }
    private let onDelete: (() -> Void)?
    
    init(value: String, onDelete: (() -> Void)?) {
        self.value = value
        self.onDelete = onDelete
    }
    
    func delete() {
        onDelete?()
    }
}
