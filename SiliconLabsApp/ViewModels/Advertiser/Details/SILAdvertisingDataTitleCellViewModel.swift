//
//  SILAdvertisingDataTitleCellViewModel.swift
//  BlueGecko
//
//  Created by Michał Lenart on 01/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILAdvertisingDataTitleCellViewModel: SILCellViewModel {
    let reusableIdentifier: String = "SILAdvertisingDataTitleCellView"

    let title: String
    private let onDelete: () -> Void
    
    init(title: String, onDelete: @escaping () -> Void) {
        self.title = title
        self.onDelete = onDelete
    }
    
    func delete() {
        onDelete()
    }
}
