//
//  UIFont+Extensions.swift
//  SiliconLabsApp
//
//  Created by Max Litteral on 8/3/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

import Foundation

extension UIFont {
    @objc class func helveticaNeue(size: CGFloat) -> UIFont? {
        return UIFont(name: "HelveticaNeue", size: size)
    }

    @objc class func helveticaNeueLight(size: CGFloat) -> UIFont? {
        return UIFont(name: "HelveticaNeue-Light", size: size)
    }

    @objc class func helveticaNeueMedium(size: CGFloat) -> UIFont? {
        return UIFont(name: "HelveticaNeue-Medium", size: size)
    }
}
