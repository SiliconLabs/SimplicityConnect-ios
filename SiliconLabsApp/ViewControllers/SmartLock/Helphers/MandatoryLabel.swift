//
//  MandatoryLabel.swift
//  SiliconLabsApp
//
//  Created by Mantosh Kumar on 09/08/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import UIKit

@IBDesignable
class MandatoryLabel: UILabel {
    @IBInspectable var isMandatory: Bool = false {
        didSet { updateText() }
    }

    override var text: String? {
        didSet { updateText() }
    }

    private func updateText() {
        guard let baseText = super.text else { return }
        let fullText = "\(baseText) *"
        let attributed = NSMutableAttributedString(string: fullText)
        // Set base text color
        attributed.addAttribute(.foregroundColor, value: self.textColor ?? UIColor.label, range: NSRange(location: 0, length: baseText.count))
        // Set asterisk color to red (last character)
        attributed.addAttribute(.foregroundColor, value: UIColor.red, range: NSRange(location: fullText.count - 1, length: 1))
        super.attributedText = attributed
    }
}
