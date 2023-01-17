//
//  SILSwitch.swift
//  BlueGecko
//
//  Created by Michał Lenart on 30/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

@IBDesignable
class SILSwitch: UIControl {
    
    @IBInspectable
    public var onColor: UIColor = UIColor.sil_regularBlue()
    
    @IBInspectable
    public var offColor: UIColor = UIColor.lightGray
    
    @IBInspectable
    public var isOn: Bool = true {
        didSet {
            updateSwitchState()
        }
    }
    
    private var switchView: UIView!
    
    private var leftConstraint: NSLayoutConstraint!
    private var rightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        initView()
    }
    
    override func prepareForInterfaceBuilder() {
        initView()
    }
    
    override func layoutSubviews() {
        updateSwitchState()
    }
    
    private func initView() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(sender:))))
        
        layer.cornerRadius = 12
        
        switchView = UIView()
        switchView.translatesAutoresizingMaskIntoConstraints = false
        switchView.layer.cornerRadius = 10
        switchView.backgroundColor = UIColor.white

        addSubview(switchView)
        
        leftConstraint = NSLayoutConstraint(item: switchView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 2)
        
        addConstraints([
            NSLayoutConstraint(item: switchView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: -4),
            NSLayoutConstraint(item: switchView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: -4),
            NSLayoutConstraint(item: switchView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0),

            leftConstraint,
        ])
        leftConstraint.isActive = true
        updateSwitchState()
    }
    
    @objc private func onTap(sender: UITapGestureRecognizer) {
        isOn = !isOn
        sendActions(for: .valueChanged)
    }
    
    private func updateSwitchState() {
        if (self.isOn) {
            self.leftConstraint?.constant = -2 + self.bounds.height
        } else {
            self.leftConstraint?.constant = 2
        }
        UIView.animate(withDuration: 0.2, animations: {
            self.backgroundColor = self.isOn ? self.onColor : self.offColor
            self.layoutIfNeeded()
        })

    }
}
