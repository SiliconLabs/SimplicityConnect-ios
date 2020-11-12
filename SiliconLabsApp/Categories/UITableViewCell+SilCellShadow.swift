//
//  UITableViewCell+SilCellShadow.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 15/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

extension UITableViewCell {
    @objc func addShadowWhenAtTop() {
        let topShadowRect = CGRect(x: bounds.origin.x, y: bounds.origin.y + 1,
                                   width: bounds.size.width, height: bounds.size.height - 2);
        addShadow(withOffset: CGSize(width: SILCellShadowOffset.width, height: 0), radius: SILCellShadowRadius)
        let radiusRect = CGSize(width: CornerRadiusStandardValue, height: CornerRadiusStandardValue);
        self.layer.shadowPath = UIBezierPath(roundedRect: topShadowRect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: radiusRect).cgPath
    }
    
    @objc func addShadowWhenInMid() {
        addShadow(withOffset: CGSize(width: SILCellShadowOffset.width, height: -SILCellShadowOffset.height),
                  radius: SILCellShadowRadius)
    }
    
    @objc func addShadowWhenAtBottom() {
        self.layer.shadowPath = nil
        addShadow(withOffset: SILCellShadowOffset, radius: SILCellShadowRadius)
    }
    
    @objc func roundCornersTop() {
        roundCorners([.topLeft, .topRight])
    }
    
    @objc func roundCornersBottom() {
        roundCorners([.bottomLeft, .bottomRight])
    }
    
    @objc func roundCornersAll() {
        roundCorners([.allCorners])
    }
    
    @objc func roundCornersNone() {
        let path = UIBezierPath(rect: self.bounds)
        setMask(path)
    }
    
    private func roundCorners (_ corners: UIRectCorner) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: CornerRadiusStandardValue, height: CornerRadiusStandardValue))
        setMask(path)
    }
    
    private func setMask(_ bezierPath: UIBezierPath) {
        let mask = CAShapeLayer()
        mask.path = bezierPath.cgPath
        self.backgroundColor = .clear
        self.contentView.layer.mask = mask
    }
}
