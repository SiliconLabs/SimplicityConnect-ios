//
//  SILPassthroughView.swift
//  BlueGecko
//
//  Created by Michał Lenart on 21/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILPassthroughView: UIView {
    var passthroughViews: [UIView] = []
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let originalHitView = super.hitTest(point, with: event)
        
        if originalHitView == self {
            for passthroughView in passthroughViews {
                let convertedPoint = self.convert(point, to: passthroughView)
                let hitView = passthroughView.hitTest(convertedPoint, with: event)
                
                if hitView != nil {
                    return hitView
                }
            }
        }
        
        return originalHitView
    }
}
