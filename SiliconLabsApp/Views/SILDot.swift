//
//  SILDot.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 19/11/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

@IBDesignable class SILDot: UIView {

    @IBInspectable var color: UIColor = UIColor.red {
        didSet {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
    
    @IBInspectable var isSelected: Bool = true
    
    override func draw(_ rect: CGRect) {
        let dotPath = UIBezierPath(ovalIn:rect)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = dotPath.cgPath
        shapeLayer.fillColor = color.cgColor
        layer.addSublayer(shapeLayer)
    }
}
