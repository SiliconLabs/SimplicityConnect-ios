//
//  Style.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit

extension UIColor {
    class func tb_hex(_ hex: Int) -> UIColor {
        return UIColor(
            red:    CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green:  CGFloat((hex & 0x00FF00) >> 8)  / 255.0,
            blue:   CGFloat((hex & 0x0000FF) >> 0)  / 255.0,
            alpha:  1.0)
    }
}

extension UILabel {
    func tb_setText(_ text: String, style: StyleText) {
        self.attributedText = style.attributedString(text)
    }
}

extension String {
    static func tb_placeholderText() -> String {
        return "--"
    }
}

class StyleColor {
    
    class var darkGray: UIColor {
        get { return UIColor.tb_hex(0x333333) }
    }
    
    class var footerGray: UIColor {
        get { return UIColor.tb_hex(0x464646) }
    }
    
    class var siliconGray: UIColor {
        get { return UIColor.tb_hex(0x555555) }
    }
    
    class var mediumGray: UIColor {
        get { return UIColor.tb_hex(0x797777) }
    }
    
    class var gray: UIColor {
        get { return UIColor.tb_hex(0xd4d4d4) }
    }
    
    class var lightGray: UIColor {
        get { return UIColor.tb_hex(0xeeeeee) }
    }
    
    class var yellow: UIColor {
        get { return UIColor.tb_hex(0xffcc00) }
    }
    
    class var gold: UIColor {
        get { return UIColor.tb_hex(0xf0b323) }
    }
    
    class var bromineOrange: UIColor {
        get { return UIColor.tb_hex(0xff7100) }
    }
    
    class var red: UIColor {
        get { return UIColor.tb_hex(0xfb2f3c) }
    }
    
    class var redOrange: UIColor {
        get { return UIColor.tb_hex(0xe65100) }
    }
    
    class var pink: UIColor {
        get { return UIColor.tb_hex(0xff7469) }
    }
    
    class var yellowOrange: UIColor {
        get { return UIColor.tb_hex(0xffa200) }
    }
    
    class var blue: UIColor {
        get { return UIColor.tb_hex(0x00aeff) }
    }
    
    class var darkViolet: UIColor {
        get { return UIColor.tb_hex(0x857cff) }
    }
    
    class var violet: UIColor {
        get { return UIColor.tb_hex(0x9196ff) }
    }
    
    class var lightViolet: UIColor {
        get { return UIColor.tb_hex(0xc3caf8) }
    }
    
    class var whiteViolet: UIColor {
        get { return UIColor.tb_hex(0xe9e3ff) }
    }
    
    class var lightPeach: UIColor {
        get { return UIColor.tb_hex(0xfff4f1) }
    }
    
    class var pinkyPeach: UIColor {
        get { return UIColor.tb_hex(0xffae9d) }
    }
    
    class var peachGold: UIColor {
        get { return UIColor.tb_hex(0xffe7cf) }
    }
    
    class var lightBlue: UIColor {
        get { return UIColor.tb_hex(0x78d6ff) }
    }
    
    class var brightGreen: UIColor {
        get { return UIColor.tb_hex(0xcaf200) }
    }
    
    class var terbiumGreen: UIColor {
        get { return UIColor.tb_hex(0xa1b92e) }
    }
    
    class var mediumGreen: UIColor {
        get { return UIColor.tb_hex(0x87a10d) }
    }
    
    class var darkGreen: UIColor {
        get { return UIColor.tb_hex(0x0b8000) }
    }
    
    class var white: UIColor {
        get { return UIColor.white }
    }
    
    class var vileRed: UIColor {
        get { return UIColor.tb_hex(0xD91E2A) }
    }
}

class StyleText {
    
    class var demoTitle: StyleText {
        get { return StyleText(fontName: .OpenSansLight, size: 29, color: StyleColor.darkGray, kerning: 25) }
    }
    
    class var demoStatus: StyleText {
        get {
            let styleText = StyleText(fontName: .OpenSansLight, size: 17, color: StyleColor.siliconGray, kerning: 25)
            if UIScreen.main.bounds.size.height <= 568.0 {
                styleText.adjustLineHeightMultiple = true
            }
            return styleText
        }
    }
    
    class var deviceName: StyleText {
        get { return StyleText(fontName: .OpenSansLight, size: 19, color: StyleColor.siliconGray, kerning: nil) }
    }
    
    class var deviceName2: StyleText {
        get { return StyleText(fontName: .OpenSansBold, size: 15, color: StyleColor.siliconGray, kerning: nil) }
    }
    
    class var deviceName3: StyleText {
        get { return StyleText(fontName: .OpenSansLight, size: 19, color: StyleColor.gray, kerning: 25) }
    }
    
    class var deviceListStatus: StyleText {
        get { return StyleText(fontName: .OpenSansLight, size: 19, color: StyleColor.white, kerning: 25) }
    }
    
    class var header: StyleText {
        get { return StyleText(fontName: .OpenSansRegular, size: 12, color: StyleColor.siliconGray, kerning: 25) }
    }
    
    class var header2: StyleText {
        get { return StyleText(fontName: .OpenSansLight, size: 12, color: StyleColor.mediumGray, kerning: 25) }
    }
    
    class var headerActive: StyleText {
        get { return StyleText(fontName: .OpenSansBold, size: 12, color: StyleColor.siliconGray, kerning: 25) }
    }
    
    class var main1: StyleText {
        get { return StyleText(fontName: .OpenSansLight, size: 15, color: StyleColor.siliconGray, kerning: nil) }
    }
    
    class var navBarTitle: StyleText {
        get { return StyleText(fontName: .OpenSansRegular, size: 17, color: StyleColor.white, kerning: nil) }
    }
    
    class var numbers1: StyleText {
        get { return StyleText(fontName: .OpenSansBold, size: 12, color: StyleColor.siliconGray, kerning: 25) }
    }
    
    class var streamingLabel: StyleText {
        get { return StyleText(fontName: .OpenSansBold, size: 13, color: StyleColor.white, kerning: 25) }
    }
    
    class var subtitle1: StyleText {
        get { return StyleText(fontName: .OpenSansLight, size: 12, color: StyleColor.mediumGray, kerning: 25) }
    }
    
    class var subtitle2: StyleText {
        get { return StyleText(fontName: .OpenSansBold, size: 10, color: StyleColor.mediumGray, kerning: 25) }
    }
    
    class var demoValue: StyleText {
        get { return StyleText(fontName: .OpenSansLight, size: 24, color: StyleColor.siliconGray, kerning: 75) }
    }
    
    class var buttonLabel: StyleText {
        get { return StyleText(fontName: .OpenSansBold, size: 13, color: StyleColor.gray, kerning: nil) }
    }
    
    class var powered_by: StyleText {
        get { return StyleText(fontName: .OpenSansRegular, size: 15, color: StyleColor.white, kerning: nil) }
    }
    
    class var note: StyleText {
        get { return StyleText(fontName: .OpenSansLight, size: 12, color: StyleColor.mediumGray, kerning: 25) }
    }

    //MARK:-
    
    var font: UIFont
    var color: UIColor
    var kerning: CGFloat?
    var adjustLineHeightMultiple = false
    
    init(fontName: FontName, size: CGFloat, color: UIColor, kerning: CGFloat?) {
        // TODO: it only temporary solution - we need to unify with EFR
        self.font = UIFont.systemFont(ofSize: size)
        self.color = color
        self.kerning = kerning
    }
    
    func attributedString(_ text: String) -> NSAttributedString {
        var attributes: [String : Any] = [
            convertFromNSAttributedStringKey(NSAttributedString.Key.font) : self.font,
            convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor) : self.color
        ]
        
        if adjustLineHeightMultiple {
            let style = NSMutableParagraphStyle()
            style.lineHeightMultiple = 0.75
            style.alignment = .center
            attributes[convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle)] = style
        }
        
        if let kerning = self.kerning {
            let kerningAdjustment: CGFloat = 20.0
            attributes[convertFromNSAttributedStringKey(NSAttributedString.Key.kern)] = (kerning / kerningAdjustment)
        }
        
        let attributedString = NSAttributedString(string: text, attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes))
        return attributedString
    }
    
    func tweakColor(color newColor: UIColor) -> StyleText {
        self.color = newColor
        return self
    }
    
    func tweakColorAlpha(_ alpha: CGFloat) -> StyleText {
        self.color = self.color.withAlphaComponent(alpha)
        return self
    }
    
    enum FontName: String {
        case OpenSansLight              = "OpenSans-Light"
        case OpenSansBold               = "OpenSans-Bold"
        case OpenSansRegular            = "OpenSans"
    }
}

class StyleAnimations {
    
    class var spinnerDuration: TimeInterval {
        get { return 1.5 }
    }
}

extension UIColor {
    class func colorForTemperature(_ temp: Temperature) -> UIColor {
        let inf = Temperature.infinity
        switch temp {
        case 37.7 ..< inf:
            return StyleColor.red
        case 32.2 ..< 37.7:
            return StyleColor.redOrange
        case 26.6 ..< 32.2:
            return StyleColor.pink
        case 21.1 ..< 26.6:
            return StyleColor.yellowOrange
        case 15.5 ..< 21.1:
            return StyleColor.yellow
        case 10 ..< 15.5:
            return StyleColor.brightGreen
        case 4.4 ..< 10:
            return StyleColor.terbiumGreen
        case -1.1 ..< 4.4:
            return StyleColor.mediumGreen
        case -6.6 ..< -1.1:
            return StyleColor.lightBlue
        case -12.2 ..< -6.6:
            return StyleColor.blue
        case -17.7 ..< -12.2:
            return StyleColor.darkViolet
        case -23.3 ..< -17.7:
            return StyleColor.violet
        case -28.8 ..< -23.3:
            return StyleColor.darkGray
        case (-inf) ..< -28.8: fallthrough
        default:
            return StyleColor.gray
        }
    }
    
    class func colorForHumidity(_ humidity: Humidity) -> UIColor {
        let inf = Humidity.infinity
        switch humidity {
        case 65 ..< inf:
            return StyleColor.redOrange
        case 61 ..< 65:
            return StyleColor.bromineOrange
        case 56 ..< 61:
            return StyleColor.yellowOrange
        case 51 ..< 56:
            return StyleColor.yellow
        case 46 ..< 51:
            return StyleColor.terbiumGreen
        case (-inf) ..< 46: fallthrough
        default:
            return StyleColor.blue
        }
    }
    
    class func colorForIlluminance(_ lx: Lux) -> UIColor {
        let inf = Lux.infinity
        switch lx {
        case (-inf) ..< 41:
            return StyleColor.darkViolet
        case 41 ..< 81:
            return StyleColor.violet
        case 81 ..< 120:
            return StyleColor.lightViolet
        case 120 ..< 161:
            return StyleColor.whiteViolet
        case 161 ..< 201:
            return StyleColor.lightPeach
        case 201 ..< 301:
            return StyleColor.peachGold
        case 301 ..< 501:
            return StyleColor.pinkyPeach
        case 501 ..< 1001:
            return StyleColor.pink
        case 1001 ..< 10001:
            return StyleColor.bromineOrange
        case 10001 ..< inf: fallthrough
        default:
            return StyleColor.yellowOrange
        }
    }
    
    class func colorForUVIndex(_ uv: UVIndex) -> UIColor {
        let inf = UVIndex.infinity
        switch uv {
        case (-inf) ..< 3:
            return StyleColor.terbiumGreen
        case 3 ..< 6:
            return StyleColor.yellow
        case 6 ..< 8:
            return StyleColor.yellowOrange
        case 8 ..< 11:
            return StyleColor.redOrange
        case 11 ..< inf: fallthrough
        default:
            return StyleColor.violet
        }
    }
    
    class func colorForCO2(_ ppm: AirQualityCO2) -> UIColor {
        let inf = AirQualityCO2.infinity
        switch ppm {
        case (-inf) ..< 1000:
            return StyleColor.terbiumGreen
        case 1000 ..< 1200:
            return StyleColor.yellow
        case 1200 ..< 5000:
            return StyleColor.redOrange
        case 5000 ..< inf: fallthrough
        default:
            return StyleColor.darkGray
        }
    }
    
    class func colorForVOC(_ ppb: AirQualityVOC) -> UIColor {
        let inf = AirQualityVOC.infinity
        switch ppb {
        case (-inf) ..< 100:
            return StyleColor.terbiumGreen
        case 100 ..< 1000:
            return StyleColor.yellow
        case 1000 ..< inf: fallthrough
        default:
            return StyleColor.redOrange
        }
    }
    
    class func colorForAtmosphericPressure(_ pressure: AtmosphericPressure) -> UIColor {
        // current design utilizes the same color for all values
        return StyleColor.terbiumGreen
    }
    
    class func colorForSoundLevel(_ level: SoundLevel) -> UIColor {
        let inf = SoundLevel.infinity
        switch level {
        case (-inf) ..< 30:
            return StyleColor.blue
        case 30 ..< 60:
            return StyleColor.terbiumGreen
        case 60 ..< 90:
            return StyleColor.yellow
        case 90 ..< 120:
            return StyleColor.yellowOrange
        case 120 ..< inf: fallthrough
        default:
            return StyleColor.redOrange
        }
    }

    class func colorForHallEffectState(_ state: HallEffectState) -> UIColor {
        switch state {
        case .closed:
            return StyleColor.blue
        case .open:
            return StyleColor.siliconGray
        case .tamper:
            return StyleColor.red
        }
    }

    class func colorForHallEffectFieldStrength(mT microTesla: MagneticFieldStrength) -> UIColor {
        return StyleColor.violet
    }
}

extension UIImage {
    class func imageNameForHallEffectState(_ state: HallEffectState) -> String {
        switch state {
        case .closed:
            return "icn_demo_hall_effect_closed"
        case .open:
            return "icn_demo_hall_effect_opened"
        case .tamper:
            return "icn_demo_hall_effect_tampered"
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
