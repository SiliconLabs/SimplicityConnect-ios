//
//  MotionDemoViewController.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit
import SceneKit

class MotionDemoViewController : DemoViewController, MotionDemoInteractionOutput, SILThunderboardConnectedDeviceBar, ConnectedDeviceDelegate {
    
    var connectedDeviceView: ConnectedDeviceBarView?
    var connectedDeviceBarHeight: CGFloat = 70.0
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableLeftInset: NSLayoutConstraint!
    @IBOutlet weak var tableRightInset: NSLayoutConstraint!
    
    @IBOutlet var navigationBar: UIView!
    
    let tableInset: CGFloat = 16.0
    
    var motionDemoView: MotionDemoView?
    
    var motionView: MotionDemoView! {
        if let view: MotionDemoView = self.motionDemoView {
            return view
        } else {
            if let cell: MotionCell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? MotionCell {
                self.motionDemoView = cell.motionView
                return self.motionDemoView
            }
        }
        return nil
    }
    
    var interaction: MotionDemoInteraction!
    var deviceConnector: DeviceConnection?
    var ledMaterials: [SCNMaterial] = []
    
    fileprivate var calibrationAlert: UIAlertController?
    
    fileprivate let calibrationTitle    = "Calibrating"
    fileprivate let calibrationMessage  = "Please ensure the Thunderboard is stationary during calibration"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.setupModel()
        }
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.setupWheel()
            self.updateModelOrientation(ThunderboardInclination(x: 0, y: 0, z: 0), animated: false)
            self.interaction.updateView()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        deviceConnector?.disconnectAllDevices()
    }
    
    func dispatchSetup() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.setupModel()
            self.tableView.reloadData()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.setupWheel()
            self.updateModelOrientation(ThunderboardInclination(x: 0, y: 0, z: 0), animated: false)
            self.interaction.updateView()
            self.tableView.reloadData()
        }
    }
    
    func setupModel() {
        // no-op - implemented in subclasses
    }
    
    func setupTableView() {
        if #available(iOS 13, *) {
            tableView.separatorStyle = .none;
        } else {
            tableLeftInset.constant = tableInset;
            tableRightInset.constant = tableInset;
        }
    }
    
    func modelTranformMatrixForOrientation(_ orientation: ThunderboardInclination) -> SCNMatrix4 {
        // no-op - implemented in subclasses to account for model orientation deltas
        return motionView.modelIdentity
    }

    //MARK: - MotionDemoInteractionOutput
    
    func updateOrientation(_ orientation: ThunderboardInclination) {
        let degrees = " °"
        motionView.orientationXValue?.text = orientation.x.tb_toString(0)! + degrees
        motionView.orientationYValue?.text = orientation.y.tb_toString(0)! + degrees
        motionView.orientationZValue?.text = orientation.z.tb_toString(0)! + degrees
        
        updateModelOrientation(orientation, animated: true)
    }
    
    func updateAcceleration(_ vector: ThunderboardVector) {
        let gravity = " g"
        
        motionView.accelerationXValue?.text = vector.x.tb_toString(2, minimumDecimalPlaces: 2)!
        motionView.accelerationXValue?.text = vector.x.tb_toString(2, minimumDecimalPlaces: 2)! + gravity
        motionView.accelerationYValue?.text = vector.y.tb_toString(2, minimumDecimalPlaces: 2)! + gravity
        motionView.accelerationZValue?.text = vector.z.tb_toString(2, minimumDecimalPlaces: 2)! + gravity
    }
    
    func updateWheel(_ diameter: Meters) {
        let settings = ThunderboardSettings()
        switch settings.measurement {
        case .metric:
            let diameterInCentimeters: Centimeters = diameter * 100
            motionView.wheelDiameterValue?.text = diameterInCentimeters.tb_toString(2)! + " cm"
        case .imperial:
            let diameterInInches = diameter.tb_toInches()
            motionView.wheelDiameterValue?.text = diameterInInches.tb_toString(2)! + "\""
        }
    }
    
    func updateLocation(_ distance: Float, speed: Float, rpm: Float, totalRpm: UInt) {
        let settings = ThunderboardSettings()
        switch settings.measurement {
        case .metric:
            motionView.distanceValue?.text = distance.tb_toString(1)
            motionView.speedValue?.text = speed.tb_toString(1)
        case .imperial:
            motionView.distanceValue?.text = distance.tb_toFeet().tb_toString(1)
            motionView.speedValue?.text = speed.tb_toFeet().tb_toString(1)
        }
        motionView.rpmValue?.text = rpm.tb_toString(0)
        motionView.totalRpmValue?.text = String(totalRpm)
    }
    
    func updateLedColor(_ on: Bool, color: LedRgb) {
        updateModelLedColor(on ? color.uiColor : StyleColor.mediumGray)
    }
    
    func deviceCalibrating(_ isCalibrating: Bool) {
        if isCalibrating {
            if calibrationAlert == nil {
                calibrationAlert = UIAlertController(title: calibrationTitle, message: calibrationMessage, preferredStyle: .alert)
                calibrationAlert?.view.tintColor = StyleColor.vileRed
                present(self.calibrationAlert!, animated: true, completion: nil)
            }
        } else {
            guard calibrationAlert != nil else { return }
            
            // Call dismiss on self because calling it on UIAlertController does not produce a completion call
            dismiss(animated: true, completion: {
                let alertController = UIAlertController(title: "Calibration successful", message: nil, preferredStyle: .alert)

                let cancelAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
                alertController.addAction(cancelAction)

                self.present(alertController, animated: true, completion: nil)
            })
            calibrationAlert = nil
        }
    }
    
    //MARK: - Actions
    
    @IBAction func calibrateButtonPressed(_ sender: AnyObject) {
        interaction.calibrate()
    }
    
    @IBAction func backButton() {
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - Private
    
    fileprivate func setupUnitsLabels() {
        let settings = ThunderboardSettings()
        
        switch settings.measurement {
        case .metric:
            motionView.distanceValueLabel?.text = "m"
            motionView.speedValueLabel?.text = "m/s"
        case .imperial:
            motionView.distanceValueLabel?.text = "ft"
            motionView.speedValueLabel?.text = "ft/s"
        }
        
        motionView.rpmValueLabel?.text = "rpm"
        motionView.totalRpmValueLabel?.text = "total revolutions"
    }

    fileprivate func setupWheel() {
        let diameter = interaction.wheelDiameter()
        updateWheel(diameter)
    }
    
    fileprivate func updateModelOrientation(_ orientation : ThunderboardInclination, animated: Bool) {
        let finalTransform = modelTranformMatrixForOrientation(orientation)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = animated ? 0.1 : 0.0
        motionView.scene.rootNode.childNodes.first?.transform = finalTransform
        SCNTransaction.commit()
    }
    
    fileprivate func updateModelLedColor(_ color: UIColor) {
        ledMaterials.forEach { (material) in
            material.diffuse.contents = color
            material.emission.contents = color
        }
    }
}

extension MotionDemoViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MotionCell = tableView.dequeueReusableCell(withIdentifier: "MotionCell") as! MotionCell
        motionDemoView = cell.motionView
        setupModel()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        SILTableViewWithShadowCells.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
    }
}

extension MotionDemoViewController: UITableViewDelegate {
    
}
