//
//  SILScanResponseViewModelBuilder.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 04/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILScanResponseViewModelBuilder {
    private var data: [SILCellViewModel] = []
    
    init() { }
    
    func add(completeLocalName: String?, onRemove: @escaping () -> Void) {
        guard let name = completeLocalName else {
            return
        }
        
        data.append(SILScanResponseTitleCellViewModel(title: "0x09 Complete Local Name", onDelete: {
            onRemove()
        }))
        
        data.append(SILScanResponseValueCellViewModel(value: name))
    }
    
    func build() -> [SILCellViewModel] {
        return data
    }
}
