//
//  SILRemoveWarningViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 31/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILRemoveWarningViewModel: SILWarningViewModel {
    
    init(wireframe: SILPopupDismissable,
         confirmAction: @escaping () -> (),
         setSettingAction: @escaping (Bool) -> (),
         name: String) {
        super.init(wireframe: wireframe,
                   confirmAction: confirmAction,
                   setSettingAction: setSettingAction,
                   title: "Remove \(name)?",
                   description: "Are you sure you want to delete \(name)?")
    }
    
}
