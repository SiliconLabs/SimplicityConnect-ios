//
//  SILAdvertiserAdd16BitServiceDialogViewModel.swift
//  BlueGecko
//
//  Created by Michał Lenart on 12/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILAdvertiserAdd16BitServiceDialogViewDelegate: class {
    func clearServiceName()
}

fileprivate struct ServiceInfo {
    let fullName: String
    let uuid: String
    let service: SILAdvertisingServiceEntity
    
    init(service: SILAdvertisingServiceEntity) {
        self.fullName = "\(service.name) (0x\(service.uuid.uppercased()))"
        self.uuid = service.uuid
        self.service = service
    }
}

class SILAdvertiserAdd16BitServiceDialogViewModel {
    private let wireframe: SILAdvertiserDetailsWireframe
    private let repository: SILAdvertisingServiceRepository
    private let onSaveCallback: (String) -> Void
    
    private var serviceName: String = ""

    private lazy var services: [ServiceInfo] = {
        return repository.getServices().map({ ServiceInfo(service: $0) })
    }()
    
    weak var viewDelegate: SILAdvertiserAdd16BitServiceDialogViewDelegate?
    
    var autocompleteValues: [String] {
        return services.map({ $0.fullName }).sorted()
    }
    
    var isClearButtonEnabled: SILObservable<Bool> = SILObservable(initialValue: false)
    var isSaveButtonEnabled: SILObservable<Bool> = SILObservable(initialValue: false)
    
    init(wireframe: SILAdvertiserDetailsWireframe, repository: SILAdvertisingServiceRepository, onSave: @escaping (String) -> Void) {
        self.wireframe = wireframe
        self.repository = repository
        self.onSaveCallback = onSave
    }
    
    func update(serviceName: String?) {
        self.serviceName = serviceName ?? ""
        
        isClearButtonEnabled.value = (self.serviceName.count > 0)
        isSaveButtonEnabled.value = parseServiceUuid(fromText: self.serviceName) != nil
    }
    
    func onInfo() {
        wireframe.open(url: "https://www.bluetooth.com/%20specifications/gatt/services/")
    }
    
    func onClear() {
        viewDelegate?.clearServiceName()
    }
    
    func onCancel() {
        wireframe.dismissPopover()
    }
    
    func onSave() {
        guard let serviceUuid = parseServiceUuid(fromText: serviceName) else {
            return
        }
        
        onSaveCallback(serviceUuid)
        wireframe.dismissPopover()
    }
    
    private func parseServiceUuid(fromText text: String) -> String? {
        let lowercaseText = text.lowercased()
        
        let textRange = NSRange(location: 0, length: lowercaseText.utf16.count)
        let uuidRegex = try! NSRegularExpression(pattern: "^(0x)?[0-9a-f]{4}$")
        
        if uuidRegex.firstMatch(in: lowercaseText, options: [], range: textRange) != nil {
            return lowercaseText.hasPrefix("0x")
                ? lowercaseText.dropFirst(2).uppercased()
                : lowercaseText.uppercased()
        } else {
            let service = services.first { serviceInfo in
                return serviceInfo.fullName.lowercased() == lowercaseText
            }
            
            return service?.uuid
        }
    }
}
