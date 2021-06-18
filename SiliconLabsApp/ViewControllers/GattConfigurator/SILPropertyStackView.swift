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
    
    @IBOutlet var buttons: [UIButton]!
    
    var propertyColor: UIColor = UIColor.sil_primaryText() {
        didSet {
            for button in buttons {
                button.setTitleColor(propertyColor, for: .normal)
                button.setTitleShadowColor(propertyColor, for: .normal)
            }
            setNeedsLayout()
            layoutSubviews()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupButtonsAppearance()
        for button in buttons {
            button.isHidden = true
        }
    }
    
    private func setupButtonsAppearance() {
        let writeImage = writeButton.currentImage?.withRenderingMode(.alwaysTemplate)
        writeButton.setImage(writeImage, for: .normal)
        writeButton.contentVerticalAlignment = .fill
        let readImage = readButton.currentImage?.withRenderingMode(.alwaysTemplate)
        readButton.setImage(readImage, for: .normal)
        readButton.contentVerticalAlignment = .fill
        let indicateImage = indicateButton.currentImage?.withRenderingMode(.alwaysTemplate)
        indicateButton.setImage(indicateImage, for: .normal)
        indicateButton.contentVerticalAlignment = .fill
        let notifyImage = notifyButton.currentImage?.withRenderingMode(.alwaysTemplate)
        notifyButton.setImage(notifyImage, for: .normal)
        notifyButton.contentVerticalAlignment = .fill
    }
    
    func updateProperties(_ properties: [SILGattConfigurationProperty]) {
        for button in buttons {
            button.isHidden = true
        }
        for property in properties {
            switch property.type {
            case .read:
                readButton.isHidden = false
            case .write, .writeWithoutResponse:
                writeButton.isHidden = false
            case .indicate:
                indicateButton.isHidden = false
            case .notify:
                notifyButton.isHidden = false
            }
        }
    }
}
