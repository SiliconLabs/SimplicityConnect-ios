//
//  SILAdvertiserAdd128BitServiceDialogViewDelegate.swift
//  BlueGecko
//
//  Created by Michał Lenart on 13/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILAdvertiserAdd128BitServiceDialogViewDelegate: class {
    func clearUUID()
}

class SILAdvertiserAdd128BitServiceDialogViewModel {
    private let wireframe: SILAdvertiserDetailsWireframe
    private let onSaveCallback: (String) -> Void
    
    weak var viewDelegate: SILAdvertiserAdd128BitServiceDialogViewDelegate?
    
    init(wireframe: SILAdvertiserDetailsWireframe, onSave: @escaping (String) -> Void) {
        self.wireframe = wireframe
        self.onSaveCallback = onSave
    }
    
    func onClear() {
        viewDelegate?.clearUUID()
    }
    
    func onCancel() {
        wireframe.dismissPopover()
    }
    
    func onSave(serviceName: String?) {
        if let serviceName = serviceName {
            onSaveCallback(serviceName)
            wireframe.dismissPopover()
        }
    }
}
