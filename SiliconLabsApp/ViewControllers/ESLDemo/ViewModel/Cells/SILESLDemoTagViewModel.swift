//
//  SILESLDemoTagViewModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 27.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation

class SILESLDemoTagViewModel: SILCellViewModel {
    let reusableIdentifier: String = "TagCell"
    private var tag: SILESLTag
    
    let onTapLedButton: (SILESLLedState) -> ()
    let onTapImageUpdateButton: (UInt, URL?, Bool) -> ()
    let onTapDisplayImageButton: (UInt) -> ()
    let onTapDeleteButton: () -> ()
    let onTapPingButton: () -> ()
    var isExpanded: Bool = false
    var isOnLed: Bool = false {
        didSet {
            tag.ledState = isOnLed ? .on: .off
        }
    }
    var tagDetailViewModels: [SILESLDemoTagDetailViewModel] = []

    var btAddress: SILBluetoothAddress {
        get {
            return tag.btAddress
        }
    }
    var elsId: SILESLIdAddress {
        get {
            return tag.eslId
        }
    }
    
    var maxImageIndex: UInt {
        get {
            return tag.maxImageIndex
        }
    }
    
    var knownImages: [URL?] {
        get {
            return tag.knownImages
        }
    }
    
    init(tag: SILESLTag,
         onTapLedButton: @escaping (SILESLLedState) -> (),
         onTapImageUpdateButton: @escaping (UInt, URL?, Bool) -> (),
         onTapDisplayImageButton: @escaping (UInt) -> (),
         onTapDeleteButton: @escaping () -> (),
         onTapPingButton: @escaping () -> ()) {
        self.tag = tag
        self.onTapLedButton = onTapLedButton
        self.onTapImageUpdateButton = onTapImageUpdateButton
        self.onTapDisplayImageButton = onTapDisplayImageButton
        self.onTapDeleteButton = onTapDeleteButton
        self.onTapPingButton = onTapPingButton
    }
    
    func updateImage(_ url: URL, at index: Int) {
        tag.knownImages[index] = url
    }
}
