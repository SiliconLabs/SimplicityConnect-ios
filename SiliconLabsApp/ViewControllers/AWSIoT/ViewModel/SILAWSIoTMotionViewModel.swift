//
//  SILAWSIoTMotionViewModel.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 12/03/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import UIKit

class SILAWSIoTMotionViewModel: NSObject {
    
    private var accelerationXStr: String = ""
    private var accelerationYStr: String = ""
    private var accelerationZStr: String = ""

    private var orientationXStr: String = ""
    private var orientationYStr: String = ""
    private var orientationZStr: String = ""
    
    func arrayFormationForUI(motionVal: [String: Any]) -> (accelerationXStr: String, accelerationYStr: String, accelerationZStr: String, orientationXStr: String, orientationYStr: String, orientationZStr: String){
        let degrees = " °"
        let gravity = " g"
            orientationXStr = "\((motionVal["gyroscope"] as! [String : Any])["x"] ?? "0.0")"
            orientationYStr = "\((motionVal["gyroscope"] as! [String : Any])["y"] ?? "0.0")"
            orientationZStr = "\((motionVal["gyroscope"] as! [String : Any])["z"] ?? "0.0")"
            
            accelerationXStr = "\((motionVal["accelerometer"] as! [String : Any])["x"] ?? "0.0")"
            accelerationYStr = "\((motionVal["accelerometer"] as! [String : Any])["y"] ?? "0.0")"
            accelerationZStr = "\((motionVal["accelerometer"] as! [String : Any])["z"] ?? "0.0")"
            
            //let motionData = ["gyroscope": ["x": orientationXStr, "y": orientationYStr, "z": orientationZStr], "accelerometer": ["x": accelerationXStr, "y": accelerationYStr, "z": accelerationZStr]]
        
        return (accelerationXStr: "\(accelerationXStr)\(gravity)", accelerationYStr: "\(accelerationYStr)\(gravity)", accelerationZStr: "\(accelerationZStr)\(gravity)", orientationXStr: "\(orientationXStr)\(degrees)", orientationYStr: "\(orientationYStr)\(degrees)", orientationZStr: "\(orientationZStr)\(degrees)")
    }

}
