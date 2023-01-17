//
//  SILThroughputGaugeView.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 14.5.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import UIKit
 
@IBDesignable
class SILThroughputGaugeView: UIView {
    private let startColor = (red: 0.0, green: 134.0, blue: 217.0)
    private let middleColor = (red: 146.0, green: 16.0, blue: 132.0)
    private let endColor = (red: 217.0, green: 30.0, blue: 42.0)
    
    private let inactiveSegmentColor = UIColor.lightGray
    private let numberOfSegments = 270
    private let labels = ["0",
                          "250kbps",
                          "500kbps",
                          "750kbps",
                          "1Mbit",
                          "1.25Mbit",
                          "1.5Mbit",
                          "1.75Mbit",
                          "2Mbit"]
    
    private let borderWidth: CGFloat = 24
    
    private let startAngle = CGFloat(3/4 * Double.pi)
    private let endAngle = CGFloat((2 + 1/4) * Double.pi)
    
    private var totalAngle: CGFloat = 270
    private var handStartAngle: CGFloat = 135
    
    private var animateGaugeLayer: CAShapeLayer!
    private var handImageView: UIImageView!
    private var lastStroke: CGFloat = 0
    private var currentHandRotationAngle: Double = -135
    
    private var valueLabel: UILabel!
    private var directionImageView: UIImageView!
    private let directionPhoneEFRImage: UIImage! = UIImage(named: "arrowUp")
    private let directionEFRPhoneImage: UIImage! = UIImage(named: "arrowDown")
    private var throughputUnitLabel: UILabel!
    
    private var numberOfSelectedSegments: Int = 0 {
        didSet {
            var toStroke = 1 - CGFloat(Double(numberOfSelectedSegments) / Double(numberOfSegments))
            if toStroke > 1 {
                toStroke = 1
            }
            if toStroke < 0 {
                toStroke = 0
            }
            
            self.animateGaugeLayer(duration: 0.2, toValue: toStroke)
        }
    }
    private let MaxThroughput = 2_000_000.0
       
    // MARK: - Drawing a gauge view
    
    override func draw(_ rect: CGRect) {
        clearsContextBeforeDrawing = true
        backgroundColor = UIColor.sil_background()
        
        let center = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        let radius = CGFloat(self.frame.width / 2 - borderWidth)
        
        drawSegments(center: center, radius: radius)
        drawAnimateGaugePath(center: center, radius: radius)
        drawLabels(center: center, radius: radius - borderWidth)
        if UIDevice.current.userInterfaceIdiom == .pad {
            drawHand(center: center, height: 80, width: 25)
        } else {
            drawHand(center: center, height: 60, width: 25)
        }
        drawResultView(center: center, height: 81, width: 100)
        setInitialValue()
    }
    
    private func drawSegments(center: CGPoint, radius: CGFloat) {
        let segmentAngle = (endAngle - startAngle) / CGFloat(numberOfSegments)
        
        for index in 0..<numberOfSegments {
            let start = CGFloat(index) * segmentAngle + startAngle
            let segment = colorForNextSegment(index: index)
            segment.set()
            let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: start, endAngle: start + segmentAngle, clockwise: true)
            path.lineWidth = borderWidth
            path.stroke()
        }
    }
    
    fileprivate func colorForNextSegment(index: Int) -> UIColor {
        let middleIndex = numberOfSegments / 2
        if index < middleIndex {
            let newValueRed = floor(((middleColor.red - startColor.red) / Double(middleIndex)) * Double(index)) + startColor.red
            let newValueGreen = floor(((middleColor.green - startColor.green) / Double(middleIndex)) * Double(index)) + startColor.green
            let newValueBlue = floor(((middleColor.blue - startColor.blue) / Double(middleIndex)) * Double(index)) + startColor.blue
            return UIColor(red: CGFloat(newValueRed / 255.0), green: CGFloat(newValueGreen / 255.0), blue: CGFloat(newValueBlue / 255.0), alpha:1.0)
        } else {
            let newValueRed = floor(((endColor.red - middleColor.red) / Double(middleIndex)) * Double(index - middleIndex)) + middleColor.red
            let newValueGreen = floor(((endColor.green - middleColor.green) / Double(middleIndex)) * Double(index - middleIndex)) + middleColor.green
            let newValueBlue = floor(((endColor.blue - middleColor.blue) / Double(middleIndex)) * Double(index - middleIndex)) + middleColor.blue
            return UIColor(red: CGFloat(newValueRed / 255.0), green: CGFloat(newValueGreen / 255.0), blue: CGFloat(newValueBlue / 255.0), alpha: 1.0)
        }
    }
    
    private func drawLabels(center: CGPoint, radius: CGFloat) {
        let segmentAngle = (endAngle - startAngle) / CGFloat(labels.count - 1)
        
        for index in 0..<labels.count {
            if index == 0 {
                let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: startAngle, clockwise: true)
                addText(string: labels[0], frame: CGRect(x: path.currentPoint.x, y: path.currentPoint.y, width: 75, height: 20), layer: animateGaugeLayer)
            } else {
                let start = CGFloat(index - 1) * segmentAngle + startAngle
                let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: start, endAngle: start + segmentAngle, clockwise: true)
                if index < 4 {
                    addText(string: labels[index], frame: CGRect(x: path.currentPoint.x - 4, y: path.currentPoint.y, width: 75, height: 20), layer: animateGaugeLayer)
                } else if index == 4 {
                    addText(string: labels[index], frame: CGRect(x: path.currentPoint.x - 16, y: path.currentPoint.y, width: 75, height: 20), layer: animateGaugeLayer)
                } else if index == 7 {
                    addText(string: labels[index], frame: CGRect(x: path.currentPoint.x - 50, y: path.currentPoint.y, width: 75, height: 20), layer: animateGaugeLayer)
                } else if index == 8 {
                    addText(string: labels[index], frame: CGRect(x: path.currentPoint.x - 30, y: path.currentPoint.y, width: 75, height: 20), layer: animateGaugeLayer)
                } else {
                    addText(string: labels[index], frame: CGRect(x: path.currentPoint.x - 40, y: path.currentPoint.y, width: 75, height: 20), layer: animateGaugeLayer)
                }
            }
        }
    }
    
    private func addText(string: String, frame: CGRect, layer: CALayer) {
        let textLayer = CATextLayer()
        textLayer.frame = frame
        textLayer.fontSize = 14
        textLayer.string = string
        textLayer.foregroundColor = UIColor.black.cgColor
        textLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(textLayer)
    }
    
    private func drawAnimateGaugePath(center: CGPoint, radius: CGFloat) {
        let pathToAnimate = UIBezierPath(arcCenter: center, radius: radius, startAngle: endAngle, endAngle: startAngle, clockwise: false)
        animateGaugeLayer = CAShapeLayer()
        animateGaugeLayer.path = pathToAnimate.cgPath
        animateGaugeLayer.fillColor = nil
        animateGaugeLayer.strokeColor = inactiveSegmentColor.cgColor
        animateGaugeLayer.lineWidth = borderWidth
        animateGaugeLayer.strokeEnd = 0.0
        
        layer.addSublayer(animateGaugeLayer)
    }
    
    private func drawHand(center: CGPoint, height: CGFloat, width: CGFloat) {
        let image = UIImage(named: "hand")
        let largerImage = UIImage(image: image, scaledTo: CGSize(width: width, height: height))
        handImageView = UIImageView(image: largerImage)
        handImageView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.95)
        handImageView.center = center
        handImageView.backgroundColor = UIColor.sil_background()
        addSubview(handImageView)
    }
    
    private func drawResultView(center: CGPoint, height: CGFloat, width: CGFloat) {
        let resultView = UIView(frame: CGRect(origin: CGPoint(x: center.x - (width / 2) - 8, y: self.frame.maxY - 100 - 8), size: CGSize(width: width, height: height)))
        resultView.backgroundColor = UIColor.sil_background()
        
        addSubview(resultView)
        
        valueLabel = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: width, height: 40)))
        valueLabel.font = UIFont.robotoRegular(size: 34)
        valueLabel.textColor = UIColor.sil_primaryText()
        valueLabel.text = "0.0"
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.textAlignment = .center

        let separatorView = UIView()
        separatorView.backgroundColor = .lightGray
        
        let imageViewHost = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 30, height: 40)))
        
        directionImageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: 25, height: 25)))
        directionImageView.image = directionEFRPhoneImage
        directionImageView.center = CGPoint(x: imageViewHost.frame.size.width / 2, y: imageViewHost.frame.size.height / 2)
        
        imageViewHost.addSubview(directionImageView)
                
        throughputUnitLabel = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 70, height: 40)))
        throughputUnitLabel.font = UIFont.robotoRegular(size: 25)
        throughputUnitLabel.textColor = UIColor.sil_primaryText()
        throughputUnitLabel.text = "kbps"
        throughputUnitLabel.translatesAutoresizingMaskIntoConstraints = false
        throughputUnitLabel.textAlignment = .center
        
        let detailsStackView = UIStackView(arrangedSubviews: [imageViewHost, throughputUnitLabel])
        detailsStackView.axis = .horizontal
        detailsStackView.distribution = .fill
        
        let generalStackView = UIStackView(arrangedSubviews: [valueLabel, separatorView, detailsStackView])
        generalStackView.axis = .vertical
        generalStackView.distribution = .fill

        resultView.addSubview(generalStackView)

        generalStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            valueLabel.heightAnchor.constraint(equalToConstant: 40.0),
            separatorView.heightAnchor.constraint(equalToConstant: 1.0),
            generalStackView.topAnchor.constraint(equalTo: resultView.topAnchor),
            generalStackView.leftAnchor.constraint(equalTo: resultView.leftAnchor),
            generalStackView.rightAnchor.constraint(equalTo: resultView.rightAnchor),
            generalStackView.heightAnchor.constraint(equalToConstant: height),
            imageViewHost.widthAnchor.constraint(equalTo: detailsStackView.widthAnchor, multiplier: 0.3)
        ])
    }
    
    // MARK: - Updating a gauge view
    
    func updateView(throughputResult: SILThroughputResult) {
        let percent = Double(throughputResult.valueInBits) / MaxThroughput
        updateResultView(throughputResult: throughputResult)
        numberOfSelectedSegments = Int(percent * Double(numberOfSegments))
    }

    private func updateResultView(throughputResult: SILThroughputResult) {
        var throughputInProperUnit = Double(throughputResult.valueInBits) / 1000.0
        
        if throughputInProperUnit > 1000.0 {
            throughputInProperUnit = throughputInProperUnit / 1000.0
            let value = NSString(format: "%.2f", throughputInProperUnit)
            valueLabel.text = "\(value)"
            throughputUnitLabel.text = "Mbps"
        } else {
            let value = NSString(format: "%.1f", throughputInProperUnit)
            valueLabel.text = "\(value)"
            throughputUnitLabel.text = "kbps"
        }
        
        switch throughputResult.sender {
        case .EFRToPhone:
            directionImageView.image = directionEFRPhoneImage
        
        case .phoneToEFR:
            directionImageView.image = directionPhoneEFRImage
            
        case .none:
            directionImageView.image = nil
            debugPrint("NONE CASE!")
        }
    }
    
    private func animateGaugeLayer(duration: TimeInterval, toValue value: CGFloat) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        animation.fromValue = lastStroke
        animation.toValue = value
        lastStroke = value
        animateGaugeLayer.strokeEnd = value
        animateGaugeLayer.add(animation, forKey: "animateCircle")
        
        currentHandRotationAngle = Double(handStartAngle - (totalAngle * value))
        UIView.animate(withDuration: duration) {
            self.handImageView.transform = CGAffineTransform(rotationAngle: CGFloat(self.deg2rad(CGFloat(self.currentHandRotationAngle))))
        }
        
        CATransaction.commit()
    }
    
    private func setInitialValue() {
        numberOfSelectedSegments = 0
    }
    
    // MARK: - Helpers
    
    fileprivate func deg2rad(_ number: CGFloat) -> CGFloat {
        return number * .pi / 180
    }
}
