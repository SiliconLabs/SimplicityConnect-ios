//
//  MotionDemoView.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit
import SceneKit

class MotionDemoView : UIView {
    
    @IBOutlet var scrollView: UIScrollView?
    @IBOutlet var contentView: UIView?
    
    @IBOutlet var carModelView: SCNView?
    
    @IBOutlet var orientationAccelerationContainer: UIView?
    @IBOutlet var orientationLabel: StyledLabel?
    
    @IBOutlet var orientationXLabel: StyledLabel?
    @IBOutlet var orientationYLabel: StyledLabel?
    @IBOutlet var orientationZLabel: StyledLabel?
    
    @IBOutlet var orientationXValue: StyledLabel?
    @IBOutlet var orientationYValue: StyledLabel?
    @IBOutlet var orientationZValue: StyledLabel?
    
    @IBOutlet var accelerationLabel: StyledLabel?
    @IBOutlet var accelerationXLabel: StyledLabel?
    @IBOutlet var accelerationYLabel: StyledLabel?
    @IBOutlet var accelerationZLabel: StyledLabel?
    
    @IBOutlet var accelerationXValue: StyledLabel?
    @IBOutlet var accelerationYValue: StyledLabel?
    @IBOutlet var accelerationZValue: StyledLabel?
    
    @IBOutlet weak var wheelLabel: StyledLabel!
    @IBOutlet weak var wheelDiameterLabel: StyledLabel!
    @IBOutlet weak var wheelDiameterValue: StyledLabel!
    
    @IBOutlet var speedLabel: StyledLabel?
    @IBOutlet var speedContainer: UIView?
    @IBOutlet var speedValue: StyledLabel?
    @IBOutlet var speedValueLabel: StyledLabel?
    @IBOutlet var rpmValue: StyledLabel?
    @IBOutlet var rpmValueLabel: StyledLabel?
    
    @IBOutlet var distanceLabel: StyledLabel?
    @IBOutlet var distanceContainer: UIView?
    @IBOutlet var distanceValue: StyledLabel?
    @IBOutlet var distanceValueLabel: StyledLabel?
    @IBOutlet var totalRpmValue: StyledLabel?
    @IBOutlet var totalRpmValueLabel: StyledLabel?

    var scene: SCNScene!
    var modelIdentity: SCNMatrix4!
    fileprivate let rotationAction = "rotationAction"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    //MARK: - Public
    
    func setModelScene(_ named: String, initialOrientation: SCNMatrix4) {
        scene = SCNScene(named: named)!
        modelIdentity = initialOrientation
        setup3dModel()
    }

    //MARK: - Internal

    fileprivate func setup3dModel() {
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        
        let omniLight = SCNLight()
        omniLight.type = SCNLight.LightType.omni
        
        let omniLightNode = SCNNode()
        omniLightNode.light = omniLight
        omniLightNode.position = SCNVector3(x: 0, y: 0, z: 10)
        scene.rootNode.addChildNode(omniLightNode)
        
        self.carModelView?.scene = scene
        self.carModelView?.allowsCameraControl = false
        carModelView?.layer.cornerRadius = 10
    }
    
    fileprivate func setupOrientation() {
        self.orientationAccelerationContainer?.backgroundColor = UIColor.clear
        self.orientationLabel?.tb_setText("ORIENTATION", style: StyleText.header2)
        self.orientationXLabel?.tb_setText("X:", style: StyleText.numbers1)
        self.orientationYLabel?.tb_setText("Y:", style: StyleText.numbers1)
        self.orientationZLabel?.tb_setText("Z:", style: StyleText.numbers1)
        
        for label in [orientationXValue, orientationYValue, orientationZValue] {
            label?.style = StyleText.subtitle1
            label?.text = String.tb_placeholderText()
        }
    } 
    
    fileprivate func setupAcceleration() {
        self.accelerationLabel?.tb_setText("ACCELERATION", style: StyleText.header2)
        self.accelerationXLabel?.tb_setText("X:", style: StyleText.numbers1)
        self.accelerationYLabel?.tb_setText("Y:", style: StyleText.numbers1)
        self.accelerationZLabel?.tb_setText("Z:", style: StyleText.numbers1)

        for label in [accelerationXValue, accelerationYValue, accelerationZValue] {
            label?.style = StyleText.subtitle1
            label?.text = String.tb_placeholderText()
        }
    }
    
    fileprivate func setupWheel() {
        self.wheelLabel?.tb_setText("WHEEL", style: StyleText.header2)
        self.wheelDiameterLabel?.tb_setText("DIA.:", style: StyleText.numbers1)
        self.wheelDiameterValue?.style = StyleText.subtitle1
        self.wheelDiameterValue?.text  = String.tb_placeholderText() + " cm"
    }
    
    fileprivate func setupSpeed() {
        self.speedLabel?.tb_setText("SPEED", style: StyleText.header2)
        speedContainer?.tb_applyCommonRoundedCornerWithShadowStyle()
        self.speedContainer?.backgroundColor = StyleColor.white
        
        for label in [speedValue, rpmValue] {
            label?.style = StyleText.demoValue;
            label?.text = String.tb_placeholderText()
        }
        
        for label in [speedValueLabel, rpmValueLabel] {
            label?.style = StyleText.numbers1.tweakColorAlpha(0.45)
            label?.text = String.tb_placeholderText()
        }
    }
    
    fileprivate func setupDistance() {
        self.distanceLabel?.tb_setText("DISTANCE", style: StyleText.header2)
        distanceContainer?.tb_applyCommonRoundedCornerWithShadowStyle()
        self.distanceContainer?.backgroundColor = StyleColor.white
        
        for label in [distanceValue, totalRpmValue] {
            label?.style = StyleText.demoValue
            label?.text = String.tb_placeholderText()
        }
        
        for label in [distanceValueLabel, totalRpmValueLabel] {
            label?.style = StyleText.numbers1.tweakColorAlpha(0.45)
            label?.text = String.tb_placeholderText()
        }
    }
    
}

