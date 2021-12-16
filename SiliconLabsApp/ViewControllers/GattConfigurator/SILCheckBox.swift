//
//  SILCheckBox.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 29/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import UIKit

@IBDesignable
open class SILCheckBox: UIControl {
    public enum Style {
        
        /// ■
        case square
        /// ●
        case circle
        /// x
        case cross
        /// ✓
        case tick
    }
    
    public enum BorderStyle {
        /// ▢
        case square
        /// ■
        case roundedSquare(radius: CGFloat)
        /// ◯
        case rounded
    }
    
    var style: Style = .tick
    var borderStyle: BorderStyle = .square
    
    @IBInspectable
    var borderWidth: CGFloat = 1.75
    
    var checkmarkSize: CGFloat = 0.5
    
    @IBInspectable
    var uncheckedBorderColor: UIColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
    
    @IBInspectable
    var checkedBorderColor: UIColor = #colorLiteral(red: 0, green: 0.3285208941, blue: 0.5748849511, alpha: 1)
    
    @IBInspectable
    var checkmarkColor: UIColor = #colorLiteral(red: 0, green: 0.3285208941, blue: 0.5748849511, alpha: 1)
    
    @IBInspectable
    var disabledColor: UIColor = .systemGray
    
    @IBInspectable
    var checkboxUnselectedBackgroundColor: UIColor! = .clear
    
    @IBInspectable
    var checkboxSelectedBackgroundColor: UIColor! = UIColor.systemBlue
    
    //Used to increase the touchable are for the component
    var increasedTouchRadius: CGFloat = 5
    
    let animationDuration = 0.2
    
    @IBInspectable
    var isChecked: Bool = false {
        didSet{
            self.setNeedsDisplay()
            self.layoutIfNeeded()
        }
    }
    
    override open var isEnabled: Bool {
        didSet {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
    
    //MARK: Intialisers
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    private func setupViews() {
        
        self.backgroundColor = .clear
        
    }
    
    //On touches ended,
    //change the selected state of the component, and changing *isChecked* property, draw methos will be called
    //So components appearance will be changed accordingly
    //Hence the state change occures here, we also sent notification for value changed event for this component.
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.isChecked = !isChecked
        self.sendActions(for: .valueChanged)
    }
    
    open override func draw(_ rect: CGRect) {
        //Draw the outlined component
        let newRect = rect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
        
        let context = UIGraphicsGetCurrentContext()!
        context.setStrokeColor(!self.isEnabled ? disabledColor.cgColor : self.isChecked ? checkedBorderColor.cgColor : uncheckedBorderColor.cgColor)
        context.setFillColor(!self.isEnabled ? UIColor.clear.cgColor : self.isChecked ? checkboxSelectedBackgroundColor.cgColor : checkboxUnselectedBackgroundColor.cgColor)
        context.fill(newRect)
        context.setLineWidth(borderWidth)
        
        var shapePath: UIBezierPath!
        switch self.borderStyle {
        case .square:
            shapePath = UIBezierPath(rect: newRect)
        case .roundedSquare(let radius):
            shapePath = UIBezierPath(roundedRect: newRect, cornerRadius: radius)
        case .rounded:
            shapePath = UIBezierPath.init(ovalIn: newRect)
        }
        
        context.addPath(shapePath.cgPath)
        context.strokePath()
        context.fillPath()
        
        animateCheckBox(frame: newRect)
        
        //When it is selected, depends on the style
        //By using helper methods, draw the inner part of the component UI.
        if isChecked {
            
            switch self.style {
            case .square:
                self.drawInnerSquare(frame: newRect)
            case .circle:
                self.drawCircle(frame: newRect)
            case .cross:
                self.drawCross(frame: newRect)
            case .tick:
                self.drawCheckMark(frame: newRect)
            }
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.setNeedsDisplay()
    }
    
    //we override the following method,
    //To increase the hit frame for this component
    //Usaully check boxes are small in our app's UI, so we need more touchable area for its interaction
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        let relativeFrame = self.bounds
        let hitTestEdgeInsets = UIEdgeInsets(top: -increasedTouchRadius, left: -increasedTouchRadius, bottom: -increasedTouchRadius, right: -increasedTouchRadius)
        let hitFrame = relativeFrame.inset(by: hitTestEdgeInsets)
        return hitFrame.contains(point)
    }
    
    //Draws tick inside the component
    func drawCheckMark(frame: CGRect) {
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration, execute: {
            self.animateCheckMark(frame: frame)
        })
    }
    
    private func getCheckMarkPath(frame: CGRect) -> UIBezierPath {
        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: frame.minX + 0.26000 * frame.width, y: frame.minY + 0.50000 * frame.height))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 0.42000 * frame.width, y: frame.minY + 0.62000 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.38000 * frame.width, y: frame.minY + 0.60000 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.42000 * frame.width, y: frame.minY + 0.62000 * frame.height))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 0.70000 * frame.width, y: frame.minY + 0.24000 * frame.height))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 0.78000 * frame.width, y: frame.minY + 0.30000 * frame.height))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 0.44000 * frame.width, y: frame.minY + 0.76000 * frame.height))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 0.20000 * frame.width, y: frame.minY + 0.58000 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.44000 * frame.width, y: frame.minY + 0.76000 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.26000 * frame.width, y: frame.minY + 0.62000 * frame.height))
        
        return bezierPath
    }
    
    func animateCheckMark(frame: CGRect) {
        let layer = CAShapeLayer()
        
        layer.lineWidth = 2
        layer.fillColor = UIColor.white.cgColor
        
        let bezierPath = getCheckMarkPath(frame: frame)
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = animationDuration
        
        layer.path = bezierPath.cgPath
        layer.add(animation, forKey: "Line")
        
        self.layer.addSublayer(layer)
    }
    
    func animateCheckBox(frame: CGRect) {
        let newRect = frame.insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
        let layer = CAShapeLayer()
        
        layer.lineWidth = 0
        
        if isChecked {
            layer.fillColor = checkboxSelectedBackgroundColor.cgColor
        } else {
            layer.fillColor = UIColor.white.cgColor
        }
        
        let bezierPath = UIBezierPath(rect: newRect)
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = animationDuration
        
        layer.path = bezierPath.cgPath
        layer.add(animation, forKey: "Line")
        
        self.layer.addSublayer(layer)
    }
 
    //Draws circle inside the component
    func drawCircle(frame: CGRect) {
        //// General Declarations
        // This non-generic function dramatically improves compilation times of complex expressions.
        func fastFloor(_ x: CGFloat) -> CGFloat { return floor(x) }
        
        //// Oval Drawing
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: frame.minX + fastFloor(frame.width * 0.22000 + 0.5), y: frame.minY + fastFloor(frame.height * 0.22000 + 0.5), width: fastFloor(frame.width * 0.76000 + 0.5) - fastFloor(frame.width * 0.22000 + 0.5), height: fastFloor(frame.height * 0.78000 + 0.5) - fastFloor(frame.height * 0.22000 + 0.5)))
        if isEnabled {
            checkmarkColor.setFill()
        } else {
            disabledColor.setFill()
        }
        ovalPath.fill()
    }

    //Draws square inside the component
    func drawInnerSquare(frame: CGRect) {
        //// General Declarations
        // This non-generic function dramatically improves compilation times of complex expressions.
        func fastFloor(_ x: CGFloat) -> CGFloat { return floor(x) }
        
        //// Rectangle Drawing
        let padding = self.bounds.width * 0.3
        let innerRect = frame.inset(by: .init(top: padding, left: padding, bottom: padding, right: padding))
        let rectanglePath = UIBezierPath.init(roundedRect: innerRect, cornerRadius: 3)
        
        //        let rectanglePath = UIBezierPath(rect: CGRect(x: frame.minX + fastFloor(frame.width * 0.22000 + 0.15), y: frame.minY + fastFloor(frame.height * 0.26000 + 0.15), width: fastFloor(frame.width * 0.76000 + 0.15) - fastFloor(frame.width * 0.22000 + 0.15), height: fastFloor(frame.height * 0.76000 + 0.15) - fastFloor(frame.height * 0.26000 + 0.15)))
        if isEnabled {
            checkmarkColor.setFill()
        } else {
            disabledColor.setFill()
        }
        rectanglePath.fill()
    }
    
    //Draws cross inside the component
    func drawCross(frame: CGRect) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        // This non-generic function dramatically improves compilation times of complex expressions.
        func fastFloor(_ x: CGFloat) -> CGFloat { return floor(x) }
        
        //// Subframes
        let group: CGRect = CGRect(x: frame.minX + fastFloor((frame.width - 17.37) * 0.49035 + 0.5), y: frame.minY + fastFloor((frame.height - 23.02) * 0.51819 - 0.48) + 0.98, width: 17.37, height: 23.02)
        
        //// Group
        //// Rectangle Drawing
        context.saveGState()
        context.translateBy(x: group.minX + 14.91, y: group.minY)
        context.rotate(by: 35 * CGFloat.pi/180)
        
        let rectanglePath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 3, height: 26))
        if isEnabled {
            checkmarkColor.setFill()
        } else {
            disabledColor.setFill()
        }
        rectanglePath.fill()
        
        context.restoreGState()
        
        //// Rectangle 2 Drawing
        context.saveGState()
        context.translateBy(x: group.minX, y: group.minY + 1.72)
        context.rotate(by: -35 * CGFloat.pi/180)
        
        let rectangle2Path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 3, height: 26))
        if isEnabled {
            checkmarkColor.setFill()
        } else {
            disabledColor.setFill()
        }
        rectangle2Path.fill()
        
        context.restoreGState()
    }
}
