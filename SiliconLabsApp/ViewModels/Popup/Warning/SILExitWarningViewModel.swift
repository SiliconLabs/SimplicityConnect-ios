//
//  SILExitWarningViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 31/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILExitWarningViewModel: SILWarningViewModel {
    
    init(wireframe: SILPopupDismissable,
         confirmAction: @escaping () -> (),
         cancelAction: @escaping () -> (),
         setSettingAction: @escaping (Bool) -> ()) {
        super.init(wireframe: wireframe,
                   confirmAction: confirmAction,
                   cancelAction: cancelAction,
                   setSettingAction: setSettingAction,
                   title: "Unsaved changes",
                   description: "Your GATT Server has unsaved changes. Do you wish to save them?",
                   confirmButtonTitle: "Yes",
                   cancelButtonTitle: "No")
    }
    
}
