//
//  UIImage+Color.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit

extension UIImage {
    class func tb_imageWithColor(_ color: UIColor, size: CGSize) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    class func tb_imageNamed(_ name:String, color:UIColor) -> UIImage? {
        guard let image = UIImage(named: name) else {
            log.error("Failed to load image \(name)")
            return nil
        }
        
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: image.size.width, height: image.size.height))
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, image.scale)
        let context = UIGraphicsGetCurrentContext()
        image.draw(in: rect)
        context?.setFillColor(color.cgColor)
        context?.setBlendMode(.sourceAtop)
        context?.fill(rect)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }
}
