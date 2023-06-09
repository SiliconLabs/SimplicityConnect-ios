//
//  SILTextField.swift
//  BlueGecko
//
//  Created by Anastazja Gradowska on 11/04/2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation

class SILTextField: UITextField {
    let padding = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    func setup() {
        self.clipsToBounds = true
        self.layer.cornerRadius = CornerRadiusForButtons
        self.borderStyle = .line
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.sil_primaryText().cgColor
    }
}
