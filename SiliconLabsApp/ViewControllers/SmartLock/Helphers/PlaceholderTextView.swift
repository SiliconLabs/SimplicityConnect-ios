//
//  PlaceholderTextView.swift
//  SiliconLabsApp
//
//  Created by Mantosh Kumar on 09/08/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import UIKit

@IBDesignable
class PlaceholderTextView: UITextView {

    @IBInspectable var placeholder: String = "" {
        didSet { setNeedsDisplay() }
    }
    @IBInspectable var placeholderColor: UIColor = UIColor.lightGray {
        didSet { setNeedsDisplay() }
    }

    override var text: String! {
        didSet { setNeedsDisplay() }
    }

    override var font: UIFont? {
        didSet { setNeedsDisplay() }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: UITextView.textDidChangeNotification, object: self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func textDidChange() {
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if text.isEmpty && !placeholder.isEmpty {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = self.textAlignment
            let attributes: [NSAttributedString.Key: Any] = [
                .font: self.font ?? UIFont.systemFont(ofSize: 12),
                .foregroundColor: placeholderColor,
                .paragraphStyle: paragraphStyle
            ]
            let insetRect = rect.inset(by: self.textContainerInset)
            (placeholder as NSString).draw(in: insetRect, withAttributes: attributes)
        }
    }
}
