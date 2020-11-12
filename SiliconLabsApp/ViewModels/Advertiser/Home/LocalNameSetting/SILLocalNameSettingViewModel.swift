//
//  SILLocalNameSettingViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 28/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

protocol SILLocalNameSettingViewDelegate: class {
    func clearLocalName()
}

class SILLocalNameSettingViewModel {
    private let wireframe: SILAdvertiserHomeWireframe
    private let settings: SILAdvertiserSettings
    private let onSave: () -> Void
    
    weak var viewDelegate: SILLocalNameSettingViewDelegate?
    
    var completeLocalName: String { settings.completeLocalName }
    
    init(wireframe: SILAdvertiserHomeWireframe, settings: SILAdvertiserSettings, onSave: @escaping () -> Void) {
        self.wireframe = wireframe
        self.settings = settings
        self.onSave = onSave
    }
    
    func onClear() {
        viewDelegate?.clearLocalName()
    }
    
    func onCancel() {
        wireframe.dismissPopover()
    }
    
    func onSave(localName: String) {
        settings.completeLocalName = localName
        wireframe.dismissPopover()
        onSave()
    }
}
