//
//  ButtonSpinner.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit

public let π = Double.pi

class ButtonAnimationTrackLayer: CALayer, CAAnimationDelegate {
    
    fileprivate let trackLayer = CAShapeLayer()
    
    override init() {
        super.init()
        commonSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonSetup()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    var lineWidth: CGFloat = 1.0 {
        didSet {
            trackLayer.lineWidth = lineWidth
        }
    }
    
    var trackColor: UIColor = UIColor.red {
        didSet {
            setupTrack()
        }
    }
    
    var beginning: CGFloat = CGFloat(π) {
        didSet {
            setupTrack()
        }
    }
    
    var ending: CGFloat = CGFloat(π) {
        didSet {
            setupTrack()
        }
    }
    
    var delayDuration: Double = 0.5
    var fillDuration: Double = 1
    var reverseDuration: Double = 1
    var rotationDuration: Double = 2
    
    enum AnimationDirection {
        case clockwise
        case counterclockwise
    }
    var direction: AnimationDirection = .clockwise
    
    fileprivate var animating = false
    fileprivate var filling = false
    fileprivate var starting = false
    fileprivate var stopping = false
    
    var currentAngle : CGFloat?
    var currentPath : UIBezierPath?
    
    func startAnimating() {
        if (animating && stopping) {
            stopping = false
            return
        }
        
        setupTrack()
        starting = true
        stopping = false
        animating = true
        start()
    }
    
    func stopAnimating() {
        stopping = true
    }
    
    func start() {
        setupPath(false)
        
        trackLayer.removeAnimation(forKey: "stroke")
        
        let strokeEndAnim = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnim.fromValue = 1.0
        strokeEndAnim.toValue = 0.02
        strokeEndAnim.duration = 0.7
        strokeEndAnim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        strokeEndAnim.isRemovedOnCompletion = false
        strokeEndAnim.delegate = self
        
        trackLayer.strokeEnd = 0.02
        trackLayer.add(strokeEndAnim, forKey: "stroke")
    }
    
    func stop() {
        trackLayer.removeAnimation(forKey: "stroke")

        let strokeEndAnim = CABasicAnimation(keyPath: "strokeColor")
        strokeEndAnim.fromValue = trackColor.cgColor
        strokeEndAnim.toValue = StyleColor.gray.cgColor
        strokeEndAnim.duration = 0.5
        strokeEndAnim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        strokeEndAnim.isRemovedOnCompletion = false
        strokeEndAnim.delegate = self
        
        trackLayer.strokeColor = StyleColor.gray.cgColor
        trackLayer.add(strokeEndAnim, forKey: "stroke")
    }
    
    func rotate() {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        
        animation.duration = rotationDuration
        animation.fromValue = 0.0
        animation.toValue = 2.0 * π
        animation.repeatCount = HUGE
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.isRemovedOnCompletion = false
        
        self.add(animation, forKey: "rotation")
    }
    
    func fill() {
        filling = true
        
        setupPath(true)
        
        trackLayer.removeAnimation(forKey: "stroke")
        
        let strokeEndAnim = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnim.fromValue = 0.02
        strokeEndAnim.toValue = 1.0
        strokeEndAnim.duration = fillDuration
        strokeEndAnim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        strokeEndAnim.isRemovedOnCompletion = false
        strokeEndAnim.delegate = self
        
        trackLayer.strokeEnd = 1.0
        trackLayer.add(strokeEndAnim, forKey: "stroke")
    }
    
    func reverse() {
        filling = false
        
        setupPath(false)
        
        trackLayer.removeAnimation(forKey: "stroke")
        
        let strokeEndAnim = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnim.fromValue = 1.0
        strokeEndAnim.toValue = 0.02
        strokeEndAnim.duration = reverseDuration
        strokeEndAnim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        strokeEndAnim.isRemovedOnCompletion = false
        strokeEndAnim.delegate = self
        
        trackLayer.strokeEnd = 0.02
        trackLayer.add(strokeEndAnim, forKey: "stroke")
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if starting {
            animating = true
            starting = false
            setupTrack()
            fill()
            rotate()
            return
        }
        
        if stopping {
            animating = false
            stopping = false
            fill()
            stop()
            return
        }
        
        if !animating {
            self.removeAllAnimations()
            return
        }
        
        if filling {
            reverse()
        } else {
            delay(delayDuration) {
                self.fill()
            }
        }
    }
    
    fileprivate func commonSetup() {
        self.addSublayer(trackLayer)
        setupTrack()
    }
    
    fileprivate func setupTrack() {
        trackLayer.frame = bounds
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = convertToCAShapeLayerLineCap("round")
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.strokeStart = 0.0
        trackLayer.strokeEnd = 1.0
        
        if (animating == false) {
            trackLayer.strokeColor = StyleColor.gray.cgColor
        }
    }
    
    fileprivate func setupPath(_ clockwise : Bool) {
        
        if (clockwise == false) {
            if let path = currentPath {
                trackLayer.path = path.reversing().cgPath
                return
            }
        }
        
        var startAngle = beginning
        
        if let start = currentAngle {
            startAngle = start
        }
        
        if (startAngle > CGFloat(2 * π)) {
            startAngle = startAngle - CGFloat(2 * π)
        }
        
        let endAngle = startAngle + ending
        
        currentAngle = endAngle
        
        let bezierPath : UIBezierPath = {
            return UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                radius: (self.bounds.size.width - lineWidth) / 2,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: clockwise)
            }()
        
        currentPath = bezierPath
        
        trackLayer.path = bezierPath.cgPath
    }
    
    override var frame: CGRect {
        get { return super.frame }
        set (value) { super.frame = value
            setupPath(true)
        }
    }
}

class ButtonSpinner: UIView {
    
    fileprivate let tracks = [
        ButtonAnimationTrackLayer(),
        ButtonAnimationTrackLayer(),
        ButtonAnimationTrackLayer(),
        ButtonAnimationTrackLayer()
    ]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonSetup()
    }
    
    fileprivate var isAnimating = false
    
    func startAnimating() {
        if isAnimating == false {
            isAnimating = true
            tracks.forEach({ $0.startAnimating() })
        }
    }
    
    func stopAnimating() {
        if isAnimating {
            isAnimating = false
            tracks.forEach({ $0.stopAnimating() })
        }
    }
    
    //MARK:- Internal
    
    override func layoutSubviews() {
        super.layoutSubviews()
        for (index, track) in tracks.enumerated() {
            let inset = 16 + (10 * index)
            track.frame = self.bounds.insetBy(dx: CGFloat(inset), dy: CGFloat(inset))
            track.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        }
    }
    
    fileprivate func commonSetup() {
        
        let trackColors = [
            StyleColor.brightGreen,
            StyleColor.terbiumGreen,
            StyleColor.mediumGreen,
            StyleColor.darkGreen
        ]
        
        let start = -π / 2.0
        let end = 2 * π
        let widths = [ 3.0, 2.5, 2.0, 1.5 ]
        let endings = [ end, end, end, end ]
        
        let delayTimings = [ 0.5, 0.2, 0.1, 0.0 ]
        let fillTimings = [ 1.0, 1.2, 1.4, 1.3 ]
        let reverseTimings = [ 0.5, 0.6, 0.5, 0.7 ]
        let rotationTimings = [ 1.0, 1.0 + 1.0 / 3.0, 2.0, 4.0 ]
        
        for (index, track) in tracks.enumerated() {
            track.delayDuration = delayTimings[index]
            track.fillDuration = fillTimings[index]
            track.reverseDuration = reverseTimings[index]
            track.rotationDuration = rotationTimings[index]
            track.beginning = CGFloat(start)
            track.ending = CGFloat(endings[index])
            track.lineWidth = CGFloat(widths[index])
            track.trackColor = trackColors[index]
            
            self.layer.addSublayer(track)
        }
        
        self.backgroundColor = UIColor.clear
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToCAShapeLayerLineCap(_ input: String) -> CAShapeLayerLineCap {
	return CAShapeLayerLineCap(rawValue: input)
}
