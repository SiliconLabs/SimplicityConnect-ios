//
//  Spinner.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit

@IBDesignable
class Spinner: UIView {

    let colorPathLayer = CAShapeLayer()
    let trackPathLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonSetup()
    }

    override func prepareForInterfaceBuilder() {
        commonSetup()
        self.hidesWhenStopped = false
        colorPathLayer.strokeStart = 0.0
        colorPathLayer.strokeEnd = 0.4
    }
    
    var lineWidth: CGFloat = 4.0 {
        didSet {
            colorPathLayer.lineWidth = lineWidth
            trackPathLayer.lineWidth = lineWidth
        }
    }
    
    var trackColor: UIColor = UIColor.lightGray {
        didSet {
            trackPathLayer.strokeColor = trackColor.cgColor
        }
    }
    
    var lineColor: UIColor = UIColor.blue {
        didSet {
            colorPathLayer.strokeColor = lineColor.cgColor
        }
    }
    
    var hidesWhenStopped: Bool = true {
        didSet {
            if hidesWhenStopped {
                self.isHidden = !self.isAnimating
            }
        }
    }

    fileprivate var isAnimating = false
    func startAnimating(_ duration: TimeInterval) {

        if isAnimating == false {
            isAnimating = true
            
            let strokeEndAnim = CABasicAnimation(keyPath: "strokeEnd")
            strokeEndAnim.toValue = 1.0
            strokeEndAnim.duration = duration
            strokeEndAnim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            strokeEndAnim.repeatCount = HUGE
            strokeEndAnim.isRemovedOnCompletion = false
            
            colorPathLayer.add(strokeEndAnim, forKey: nil)
            self.isHidden = false
        }
    }
    
    func stopAnimating() {
        isAnimating = false
        colorPathLayer.removeAllAnimations()
        self.isHidden = self.hidesWhenStopped
    }
    
    
    //MARK:- Internal
    
    override func layoutSubviews() {
        super.layoutSubviews()

        trackPathLayer.frame = bounds
        trackPathLayer.path = circlePath().cgPath
        
        colorPathLayer.frame = bounds
        colorPathLayer.path = circlePath().cgPath
    }
    
    fileprivate func commonSetup() {
        
        setupTrackPath()
        layer.addSublayer(trackPathLayer)
        
        setupColorPath()
        layer.addSublayer(colorPathLayer)
        
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = false
        self.isHidden = hidesWhenStopped
    }
    
    fileprivate func setupTrackPath() {
        trackPathLayer.frame = bounds
        trackPathLayer.lineWidth = lineWidth
        trackPathLayer.fillColor = UIColor.clear.cgColor
        trackPathLayer.strokeColor = trackColor.cgColor
        trackPathLayer.strokeStart = 0
        trackPathLayer.strokeEnd = 1
    }
    
    fileprivate func setupColorPath() {
        colorPathLayer.frame = bounds
        colorPathLayer.lineWidth = lineWidth
        colorPathLayer.fillColor = UIColor.clear.cgColor
        colorPathLayer.strokeColor = lineColor.cgColor
        colorPathLayer.strokeStart = 0
        colorPathLayer.strokeEnd = 0
        colorPathLayer.lineCap = convertToCAShapeLayerLineCap("butt")
    }
    
    fileprivate func circlePath() -> UIBezierPath {
        return UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
            radius: (bounds.size.width - lineWidth) / 2,
            startAngle: .pi/2,
            endAngle: 5 * .pi/2,
            clockwise: true)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToCAShapeLayerLineCap(_ input: String) -> CAShapeLayerLineCap {
	return CAShapeLayerLineCap(rawValue: input)
}
