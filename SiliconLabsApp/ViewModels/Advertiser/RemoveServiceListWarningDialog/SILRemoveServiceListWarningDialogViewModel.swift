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
    private let onOkCallback: (Bool) -> Void
    
    private var disableWarning: Bool = false
    
    init(wireframe: SILAdvertiserDetailsWireframe, onOk: @escaping (Bool) -> Void) {
        self.onOkCallback = onOk
        self.wireframe = wireframe
    }
    
    func onSwitchChange(disableWarning: Bool) {
        self.disableWarning = disableWarning
    }
    
    func onOk() {
        wireframe.dismissPopover()
        onOkCallback(disableWarning)
    }
    
    func onCancel() {
        wireframe.dismissPopover()
    }
}
