//
//  SILRemoveServiceListWarningDialogViewModel.swift
//  BlueGecko
//
//  Created by Michał Lenart on 29/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILRemoveServiceListWarningDialogViewModel {
    private let wireframe: SILAdvertiserDetailsWireframe
    private let onYes: (Bool) -> Void
    
    private var disableWarning: Bool = false
    
    init(wireframe: SILAdvertiserDetailsWireframe, onYes: @escaping (Bool) -> Void) {
        self.onYes = onYes
        self.wireframe = wireframe
    }
    
    func onSwitchChange(disableWarning: Bool) {
        self.disableWarning = disableWarning
    }
    
    func onYesCallback() {
        wireframe.dismissPopover()
        onYes(disableWarning)
    }
    
    func onNoCallback() {
        wireframe.dismissPopover()
    }
}
