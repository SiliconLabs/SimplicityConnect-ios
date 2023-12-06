//
//  UIView+Style.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit

extension UIView {
    
    func tb_applyCommonRoundedCornerWithShadowStyle() {
        self.tb_applyRoundedCorner(3)
        self.tb_applyShadow(UIColor.black, offset: CGSize(width: 0, height: 2), opacity: 0.1, radius: 2)
    }
    
    func tb_applyCommonDropShadow() {
        self.tb_applyShadow(UIColor.black, offset: CGSize(width: 0, height: 2), opacity: 0.1, radius: 2)
    }
    
    func tb_applyCommonRoundedCornerWithShadowStyle(radiusValue: Float) {
        self.tb_applyRoundedCorner(radiusValue)
        self.tb_applyShadow(UIColor.black, offset: CGSize(width: 0, height: 2), opacity: 0.1, radius: 2)
    }
    
    func tb_applyRoundedCorner(_ radius: Float) {
        self.layer.cornerRadius = CGFloat(radius)
    }
    
    func tb_applyShadow(_ color: UIColor, offset: CGSize, opacity: Float, radius: Float) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOffset = offset
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = CGFloat(radius)
    }
    
    func tb_removeShadow() {
        self.layer.masksToBounds = true
    }
    
}
