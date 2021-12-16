//
//  SettingsViewCell.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit

class SettingsViewCell : UITableViewCell {
    
    var drawBottomSeparator: Bool = false
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if drawBottomSeparator {
            let path = UIBezierPath()
            let lineWidth: CGFloat = 1.0
            path.move(to: CGPoint(x: 15, y: rect.size.height - lineWidth))
            path.addLine(to: CGPoint(x: rect.width, y: rect.size.height - lineWidth))
            path.lineWidth = lineWidth
            
            StyleColor.lightGray.setStroke()
            path.stroke()
        }
    }
    
}
