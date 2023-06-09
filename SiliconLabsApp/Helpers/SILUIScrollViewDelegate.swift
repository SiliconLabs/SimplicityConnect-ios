//
//  SILUIScrollViewDelegate.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 14.2.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation
import UIKit

@objc class SILUIScrollViewDelegate: NSObject {
    private var currentY: CGFloat!
    private let hideUIElements: () -> Void
    private let showUIElements: () -> Void
    
    @objc init(onHideUIElements: @escaping () -> Void, onShowUIElements: @escaping () -> Void) {
        self.hideUIElements = onHideUIElements
        self.showUIElements = onShowUIElements
        super.init()
    }
    
    @objc func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        currentY = scrollView.contentOffset.y
    }
    
    @objc func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > currentY {
            hideUIElements()
        } else if scrollView.contentOffset.y < currentY {
            showUIElements()
        }
    }
}
