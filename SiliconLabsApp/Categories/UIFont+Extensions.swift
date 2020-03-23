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
    
    @objc class func robotoMedium(size: CGFloat) -> UIFont? {
        return UIFont(name: "Roboto-Medium", size: size)
    }
    
    @objc class func robotoRegular(size: CGFloat) -> UIFont? {
        return UIFont(name: "Roboto-Regular", size: size)
    }
    
    @objc class func robotoBold(size: CGFloat) -> UIFont? {
        return UIFont(name: "Roboto-Bold", size: size)
    }
    
    @objc class func getLargeFontSize() -> CGFloat {
        return UI_USER_INTERFACE_IDIOM() == .phone ? CGFloat(SILLargeFontSizeIphones) : CGFloat(SILLargeFontSizeIpads)
    }
    
    @objc class func getMiddleFontSize() -> CGFloat {
        return UI_USER_INTERFACE_IDIOM() == .phone ? CGFloat(SILMediumFontSizeIphones) : CGFloat(SILMediumFontSizeIpads)
    }
    
    @objc class func getSmallFontSize() -> CGFloat {
        return UI_USER_INTERFACE_IDIOM() == .phone ? CGFloat(SILSmallFontSizeIphones) : CGFloat(SILSmallFontSizeIpads)
    }
}
