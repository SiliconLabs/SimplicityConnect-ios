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

    @objc class func helveticaNeueBold(size: CGFloat) -> UIFont? {
        return UIFont(name: "HelveticaNeue-Bold", size: size)
    }

    @objc class func helveticaNeueThin(size: CGFloat) -> UIFont? {
        return UIFont(name: "HelveticaNeue-Thin", size: size)
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

    // MARK: - Stolzl (Primary / Headline font per Brand Guidelines)

    @objc class func stolzlBold(size: CGFloat) -> UIFont? {
        return UIFont(name: "Stolzl-Bold", size: size)
    }

    @objc class func stolzlMedium(size: CGFloat) -> UIFont? {
        return UIFont(name: "Stolzl-Medium", size: size)
    }

    @objc class func stolzlRegular(size: CGFloat) -> UIFont? {
        return UIFont(name: "Stolzl-Regular", size: size)
    }

    @objc class func stolzlBook(size: CGFloat) -> UIFont? {
        return UIFont(name: "Stolzl-Book", size: size)
    }

    @objc class func stolzlLight(size: CGFloat) -> UIFont? {
        return UIFont(name: "Stolzl-Light", size: size)
    }

    @objc class func stolzlThin(size: CGFloat) -> UIFont? {
        return UIFont(name: "Stolzl-Thin", size: size)
    }

    @objc class func getLargeFontSize() -> CGFloat {
        return UIDevice.current.userInterfaceIdiom == .phone ? CGFloat(SILLargeFontSizeIphones) : CGFloat(SILLargeFontSizeIpads)
    }
    
    @objc class func getMiddleFontSize() -> CGFloat {
        return UIDevice.current.userInterfaceIdiom == .phone ? CGFloat(SILMediumFontSizeIphones) : CGFloat(SILMediumFontSizeIpads)
    }
    
    @objc class func getSmallFontSize() -> CGFloat {
        return UIDevice.current.userInterfaceIdiom == .phone ? CGFloat(SILSmallFontSizeIphones) : CGFloat(SILSmallFontSizeIpads)
    }
}
