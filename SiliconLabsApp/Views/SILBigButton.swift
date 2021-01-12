//
//  SILBigButton.swift
//  SiliconLabsApp
//
//  Created by Michał Lenart on 19/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@IBDesignable
class SILBigButton: UIButton {
    @IBInspectable var extendLeft: CGFloat = 0
    @IBInspectable var extendTop: CGFloat = 0
    @IBInspectable var extendRight: CGFloat = 0
    @IBInspectable var extendBottom: CGFloat = 0
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let newArea = CGRect(
            x: self.bounds.origin.x - extendLeft,
            y: self.bounds.origin.y - extendTop,
            width: self.bounds.size.width + extendLeft + extendRight,
            height: self.bounds.size.height + extendTop + extendBottom
        )
        
        return newArea.contains(point)
    }
}
