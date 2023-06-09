//
//  SILESLDisplayImagePopupViewModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 30.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation

class SILESLDisplayImagePopupViewModel {
    let maxImageIndex: UInt
    let imageSlot0: URL?
    let imageSlot1: URL?
    let onCancel: () -> ()
    let onDisplayImage: (UInt) -> ()
    var selectedImageIndex: UInt = 0
    
    init(maxImageIndex: UInt,
         imageSlot0: URL?,
         imageSlot1: URL?,
         onCancel: @escaping () -> (),
         onDisplayImage: @escaping (UInt) -> ()) {
        self.maxImageIndex = maxImageIndex
        self.imageSlot0 = imageSlot0
        self.imageSlot1 = imageSlot1
        self.onCancel = onCancel
        self.onDisplayImage = onDisplayImage
    }
}
