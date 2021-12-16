//
//  SILConnectionParameterLabel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 14.5.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import UIKit

@IBDesignable
class SILConnectionParameterLabel: UILabel {
    var boldFont: UIFont = UIFont.robotoBold(size: 17.0)!
    var normalFont: UIFont = UIFont.robotoRegular(size: 17.0)!
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let text = text else {
            return
        }
        
        let words = text.components(separatedBy: ":")
        
        let attributedText = NSMutableAttributedString()
        if words.count >= 1 {
            attributedText.append(normal(String(words[0]).appending(":")))
        }
        
        if words.count == 2 {
            attributedText.append(bold(String(words[1])))
        }
        
        self.attributedText = attributedText
    }
    
    private func bold(_ value: String) -> NSAttributedString {
        let attributes:[NSAttributedString.Key : Any] = [
            .font : boldFont,
            .foregroundColor : UIColor.sil_primaryText()
        ]
        
        return NSAttributedString(string: value, attributes: attributes)
    }
    
    private func normal(_ value:String) -> NSAttributedString {
        let attributes:[NSAttributedString.Key : Any] = [
            .font : normalFont,
            .foregroundColor : UIColor.sil_subtleText()
        ]
        
        return NSAttributedString(string: value, attributes: attributes)
    }
}
