//
//  SILESLImageUpdatePopupViewModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 30.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation

class SILESLImageUpdatePopupViewModel {
    let maxImageIndex: UInt
    var imageSlot0: URL?
    var imageSlot1: URL?
    private let currentTagImageSlot0: URL?
    private let currentTagImageSlot1: URL?
    let onCancel: () -> ()
    let onImageUpdate: (UInt, URL?, Bool) -> ()
    var selectedImageIndex: UInt = 0
    var lastTappedSlot: UInt = 0
    var showImageAfterUpdate = true
    var wasTapContinuation = false
    
    init(maxImageIndex: UInt,
         imageSlot0: URL?,
         imageSlot1: URL?,
         onCancel: @escaping () -> (),
         onImageUpdate: @escaping (UInt, URL?, Bool) -> ()) {
        self.maxImageIndex = maxImageIndex
        self.imageSlot0 = imageSlot0
        self.currentTagImageSlot0 = imageSlot0
        self.imageSlot1 = imageSlot1
        self.currentTagImageSlot1 = imageSlot1
        self.onCancel = onCancel
        self.onImageUpdate = onImageUpdate
    }
    
    func isDifferentImageOnSlot0() -> Bool {
        return imageSlot0 != currentTagImageSlot0
    }
    
    func isDifferentImageOnSlot1() -> Bool {
        return imageSlot1 != currentTagImageSlot1
    }
}
