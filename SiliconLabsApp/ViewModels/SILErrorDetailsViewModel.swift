//
//  SILErrorDetailsViewModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 08/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILErrorDetailsViewModel {
    private let error: NSError
    private let attError: SILAttErrorModel.Error
    
    var errorCode: String {
        return self.attError.code
    }
    
    var errorName: String {
        return self.attError.name
    }
    
    var errorDescription: String {
        return self.attError.description
    }
    
    init(error: NSError) {
        self.error = error
        let attErrorModel = SILAttErrorModel(errorCode: error.code)
        attError = attErrorModel.errorDetails
    }
}
