//
//  Constants.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 19/02/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import Foundation
import AWSCore

let CertificateSigningRequestCommonName = "AWS IoT Certificate"
let CertificateSigningRequestCountryName = "US"
let CertificateSigningRequestOrganizationName = "Amazon.com Inc."
let CertificateSigningRequestOrganizationalUnitName = "Amazon Web Services"

//SOVAN
//let POLICY_NAME = "Silab_Mobile_policy"
//SARAVAN
//let POLICY_NAME = "AWS_IOT_S91X_POLICY"

//Silabs
let POLICY_NAME = "AWS_IOT_S91X_POLICY"
// This is the endpoint in your AWS IoT console. eg: https://xxxxxxxxxx.iot.<region>.amazonaws.com

//let AWS_REGION = AWSRegionType.USEast1  // ap-south-1

//Silabs
let AWS_REGION = AWSRegionType.USEast2  // ap-south-1


//For both connecting over websockets and cert, IOT_ENDPOINT should look like
//https://xxxxxxx-ats.iot.REGION.amazonaws.com
// https://a2kx9nh8vhb5oe-ats.iot.ap-south-1.amazonaws.com
//Sovan
// let IOT_ENDPOINT = "https://a3o0fhg7z1y88u-ats.iot.ap-south-1.amazonaws.com"

//SARVAN
//let IOT_ENDPOINT = "https://a2kx9nh8vhb5oe-ats.iot.us-east-1.amazonaws.com"

//Silabs
//endpoint: a2m21kovu9tcsh-ats.iot.us-east-2.amazonaws.com
let IOT_ENDPOINT = "https://a2m21kovu9tcsh-ats.iot.us-east-2.amazonaws.com"


//let IDENTITY_POOL_ID = "ap-south-1:285452c9-0a2b-4518-bf86-585f5dad0078"

let IDENTITY_POOL_ID = "ap-south-1:f11cb5e7-7fd9-4c61-840a-1fce0de6391f"  // Gust(unouth)

//let IDENTITY_POOL_ID = "ap-south-1:285452c9-0a2b-4518-bf86-585f5dad0078"  // Auth

//Used as keys to look up a reference of each manager
let AWS_IOT_DATA_MANAGER_KEY = "MyIotDataManager"
let AWS_IOT_MANAGER_KEY = "MyIotManager"


let notification_motion = "notificationForMotionValue"
let AWStopicUserDefault = UserDefaults.standard
let subcribe_topic_name = "subcribe_topic_name"
let publish_topic_name = "publish_topic_name"

