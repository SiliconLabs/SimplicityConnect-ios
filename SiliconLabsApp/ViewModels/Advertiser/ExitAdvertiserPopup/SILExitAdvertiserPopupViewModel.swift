//
//  SILExitAdvertiserPopupViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 09/12/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

class SILExitAdvertiserPopupViewModel {
    private let wireframe: SILAdvertiserDetailsWireframe
    private let onYesCallback: (Bool) -> ()
    private let onNoCallback: () -> ()
    
    private var disableWarning: Bool = false
    
    init(wireframe: SILAdvertiserDetailsWireframe, onYesCallback: @escaping (Bool) -> (), onNoCallback: @escaping () -> ()) {
        self.wireframe = wireframe
        self.onYesCallback = onYesCallback
        self.onNoCallback = onNoCallback
    }
    
    func onSwitchChange(disableWarning: Bool) {
        self.disableWarning = disableWarning
    }
    
    func onYes() {
        wireframe.dismissPopover()
        onYesCallback(disableWarning)
    }
    
    func onNo() {
        wireframe.dismissPopover()
        onNoCallback()
    }
}
