//
//  SILAWSIoTMotionViewController.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 20/02/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import UIKit

class SILAWSIoTMotionViewController: UIViewController {
    @IBOutlet weak var accelerationXLbl: StyledLabel!
    @IBOutlet weak var accelerationYLbl: StyledLabel!
    @IBOutlet weak var accelerationZLbl: StyledLabel!

    @IBOutlet weak var orientationXLbl: StyledLabel!
    @IBOutlet weak var orientationYLbl: StyledLabel!
    @IBOutlet weak var orientationZLbl: StyledLabel!
    
    private var accelerationXStr: String = ""
    private var accelerationYStr: String = ""
    private var accelerationZStr: String = ""

    private var orientationXStr: String = ""
    private var orientationYStr: String = ""
    private var orientationZStr: String = ""
    var motionData: [String: Any]?
    
    var SILAWSIoTMotionViewModelObject: SILAWSIoTMotionViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        SILAWSIoTMotionViewModelObject = SILAWSIoTMotionViewModel()
        
        // Register to receive notification in your class
        NotificationCenter.default.addObserver(self, selector: #selector(self.showMotionValue(_:)), name: NSNotification.Name(rawValue: notification_motion), object: nil)
        
        if let motionDataTemp = motionData?["value"] as? [String : Any] {
            //arrayFormationForUI(motionVal: motionDataTemp)
            if let motionVal = SILAWSIoTMotionViewModelObject?.arrayFormationForUI(motionVal: motionDataTemp) {
                setMotionValue(motionValue:motionVal)
            }
        }
       
    }

    private func setMotionValue(motionValue:(String, String, String, String, String, String)){
        DispatchQueue.main.async {
            self.orientationXLbl.text = motionValue.3
            self.orientationYLbl.text = motionValue.4
            self.orientationZLbl.text = motionValue.5
            self.accelerationXLbl.text = motionValue.0
            self.accelerationYLbl.text = motionValue.1
            self.accelerationZLbl.text = motionValue.2
        }
    }
    @IBAction func cancelBtn(_ sender: UIButton) {
        self.dismiss(animated: false, completion: nil)
    }

    // handle notification
    // For swift 4.0 and above put @objc attribute in front of function Definition
    @objc func showMotionValue(_ notification: NSNotification) {
        if let notificationVal = notification.userInfo?["mVal"] as? Dictionary<String, Any> {
            // do something with your image
            //print(notificationVal)
            if let motionDataTemp = notificationVal["value"] as? [String : Any] {
                //arrayFormationForUI(motionVal: motionDataTemp)
                if let motionVal = SILAWSIoTMotionViewModelObject?.arrayFormationForUI(motionVal: motionDataTemp) {
                    setMotionValue(motionValue:motionVal)
                }
            }
        }
    }
}
