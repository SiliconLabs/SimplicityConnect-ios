//
//  SILScanResponseTitleCellViewModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 04/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILScanResponseTitleCellViewModel: SILCellViewModel {
    let reusableIdentifier: String = "SILScanResponseTitleCellView"

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
