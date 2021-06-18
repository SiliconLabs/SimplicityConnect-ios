//
//  SILTabBar.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 11/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

@objcMembers
class SILTabBar: UITabBar {
    var indicatorView: UIView?
    var indicatorCenter: NSLayoutConstraint?
    var indicatorConstant: CGFloat = 0.0
    
    var indicatorConstantFor0: CGFloat = -0.25
    var indicatorConstantFor1: CGFloat = 0.25
    var indicatorConstantIPadFor0: CGFloat = -0.18
    var indicatorConstantIPadFor1: CGFloat = 0.17
    
    @IBInspectable var height: CGFloat = 0.0
    let DefaultHeight: CGFloat = 70.0

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        height = DefaultHeight
        setupIndicatorView()
        addShadow()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let window = UIApplication.shared.windows.first
        let bottomNotchHeight = window?.safeAreaInsets.bottom ?? 0.0
        var sizeThatFits = super.sizeThatFits(size)
        let tabBarHeight = height + bottomNotchHeight
        if tabBarHeight > 0.0 {
            sizeThatFits.height = tabBarHeight
        }
        return sizeThatFits
    }
    
    func setupIndicatorView() {
        indicatorView = UIView(frame: CGRect.zero)
        indicatorView?.translatesAutoresizingMaskIntoConstraints = false
        addSubview(indicatorView!)
        indicatorView?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        indicatorView?.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.07).isActive = true
        indicatorView?.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.15).isActive = true
        indicatorCenter = NSLayoutConstraint(
            item: indicatorView,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerX,
            multiplier: 1,
            constant: 0)
        indicatorView?.backgroundColor = UIColor.sil_strongBlue()
        addConstraint(indicatorCenter!)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        indicatorCenter?.constant = bounds.size.width * indicatorConstant
        addRoundedCornersInIndicator()
        backgroundColor = UIColor.sil_bgWhite()
    }
    
    private func addRoundedCornersInIndicator() {
        let radius = indicatorView!.bounds.size.height
        let bezierPath = UIBezierPath(
            roundedRect: indicatorView!.bounds,
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = bezierPath.cgPath
        indicatorView!.layer.mask = mask
    }

    func setMuliplierForSelectedIndex(_ index: Int) {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            if index == 0 {
                indicatorConstant = indicatorConstantIPadFor0
            } else {
                indicatorConstant = indicatorConstantIPadFor1
            }
        } else {
            if index == 0 {
                indicatorConstant = indicatorConstantFor0
            } else {
                indicatorConstant = indicatorConstantFor1
            }
        }
        indicatorCenter?.constant = bounds.size.width * indicatorConstant
        setNeedsLayout()
        UIView.animate(withDuration: 0.2, animations: { [self] in
            layoutIfNeeded()
        })
    }
    
}
