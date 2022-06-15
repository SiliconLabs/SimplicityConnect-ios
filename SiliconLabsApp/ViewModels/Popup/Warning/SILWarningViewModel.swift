//
//  SILWarningViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 27/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

class SILWarningViewModel {
    
    private(set) var wireframe: SILPopupDismissable!
    private(set) var confirmAction: (() -> ())
    private(set) var setSettingAction: (Bool) -> ()
    private(set) var cancelAction: () -> ()
    let title: String
    let description: String
    let confirmButtonTitle: String
    let cancelButtonTitle: String
    
    init(wireframe: SILPopupDismissable,
         confirmAction: @escaping () -> (),
         cancelAction: @escaping () -> () = { },
         setSettingAction: @escaping (Bool) -> (),
         title: String,
         description: String,
         confirmButtonTitle: String = "OK",
         cancelButtonTitle: String = "Cancel") {
        self.wireframe = wireframe
        self.confirmAction = confirmAction
        self.setSettingAction = setSettingAction
        self.cancelAction = cancelAction
        self.title = title
        self.description = description
        self.confirmButtonTitle = confirmButtonTitle
        self.cancelButtonTitle = cancelButtonTitle
    }
    
    func onConfirm(with switchState: Bool) {
        confirmAction()
        setSettingAction(switchState)
        wireframe.dismissPopover()
    }
    
    func onCancel(with switchState: Bool) {
        cancelAction()
        setSettingAction(switchState)
        wireframe.dismissPopover()
    }
    
}

