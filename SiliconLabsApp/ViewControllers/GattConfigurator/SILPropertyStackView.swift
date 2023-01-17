//
//  SILPropertyStackView.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 29/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import UIKit

class SILPropertyStackView: UIStackView {
    
    @IBOutlet weak var writeButton: UIButton!
    @IBOutlet weak var readButton: UIButton!
    @IBOutlet weak var indicateButton: UIButton!
    @IBOutlet weak var notifyButton: UIButton!
    
    @IBOutlet weak var writeLabel: UILabel!
    @IBOutlet weak var readLabel: UILabel!
    @IBOutlet weak var indicateLabel: UILabel!
    @IBOutlet weak var notifyLabel: UILabel!
    
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet var labels: [UILabel]!
    
    var propertyColor: UIColor = UIColor.sil_regularBlue() {
        didSet {
            for button in buttons {
                button.setTitleColor(propertyColor, for: .normal)
                button.setTitleShadowColor(propertyColor, for: .normal)
                button.imageView?.tintColor = propertyColor
            }
            setNeedsLayout()
            layoutSubviews()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupButtonsAppearance()
        hideLabelsAndButtons()
    }
    
    private func setupButtonsAppearance() {
        for button in buttons {
            let image = button.currentImage?.withRenderingMode(.alwaysTemplate)
            button.setImage(image, for: .normal)
            button.imageView?.tintColor = propertyColor
            button.contentVerticalAlignment = .fill
        }
    }
    
    private func hideLabelsAndButtons() {
        for button in buttons {
            button.isHidden = true
        }
        
        for label in labels {
            label.isHidden = true
        }
    }
    
    func updateProperties(_ properties: [SILGattConfigurationProperty]) {
        hideLabelsAndButtons()
        for property in properties {
            switch property.type {
            case .read:
                readButton.isHidden = false
                readLabel.isHidden = false
            case .write, .writeWithoutResponse:
                writeButton.isHidden = false
                writeLabel.isHidden = false
            case .indicate:
                indicateButton.isHidden = false
                indicateLabel.isHidden = false
            case .notify:
                notifyButton.isHidden = false
                notifyLabel.isHidden = false
            }
        }
    }
}
