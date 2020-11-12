//
//  SILAdvertiserRemoveWarningViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 27/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

class SILAdvertiserRemoveWarningViewModel {
    
    var wireframe: SILAdvertiserHomeWireframe!
    var confirmAction: (() -> ())
    
    init(wireframe: SILAdvertiserHomeWireframe, confirmAction: @escaping () -> ()) {
        self.wireframe = wireframe
        self.confirmAction = confirmAction
    }
    
    func onConfirm(with switchState: Bool) {
        confirmAction()
        SILAdvertiserRemoveSetting.setDisplayAdvertiserRemoveWarning(value: switchState)
        wireframe.dismissPopover()
    }
    
    func onCancel() {
        wireframe.dismissPopover()
    }
    
}
