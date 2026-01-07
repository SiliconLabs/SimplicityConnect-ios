//
//  SmartLockConstants.swift
//  SiliconLabsApp
//
//  Created by Mantosh Kumar on 08/07/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import Foundation

struct SmartLockConstants {
    static let unlockFromMQTT = "SmartLock in Unlocked state" //"Unlock from MQTT"
    static let unlockFromMQTTUpper = "UNLOCK from MQTT"
    static let lockFromMQTT = "SmartLock in Locked state" //"lock from MQTT"
    static let lockFromMQTTUpper = "LOCK from MQTT"
    static let smartLockActiveNow = "SmartLock is Active Now"
    static let lockFromButton = "LOCK from BUTTON"
    static let unlockFromButton = "UNLOCK from BUTTON"
    
    static let msgSubscribed = "Message subscribed"
    static let msgPublished =  "Message published"
    
    static let awslockedStatus = "Status via AWS: Locked"
    static let awsUnlockedStatus = "Status via AWS: Unlocked"
    static let blelockedStatus = "Status via BLE: Locked"
    static let bleUnlockedStatus = "Status via BLE: Unlocked"
    static let loadingData = "Loading data…"
    static let loadingAwsCurrentStatus = "Loading current lock status"

    static let bleStatus = "Status via BLE"
    static let awsStatus = "Status via AWS"
    
    static let wakeupQuery = "query"
    static let unlockCommand = "unlock"
    static let lockCommand = "lock"
    
    static let bleSetupStarted = "BLE setup Started..."
    static let lockImage = "lockClose_icon"
    static let unlockImage = "lockOpen_icon"
    
    static let internetSlowText = "Please check your internet connection. It appears to be slow or unstable. Kindly try again."
    static let internetNotAvailable = "Internet not available. Kindly check your internet connection on your phone. Thank you!"
    static let connectMsg = "The device is connected to the internet."
    
    static let shouldNotEmpty = "TextField should not be empty."
    static let configureWarning = "Please configure your AWS Smart Lock first. You can do this by clicking the settings button in the top-right corner."
    static let pubSubEmptyWarning = "Subscribe and publish topics should not be empty."
    static let allFieldsRequired = "All fields are required."
    static let alreayConfigured = "Smart Lock is already configured. Would you like to reconfigure it? Reconfiguring will disconnect the existing connection."
    static let endPointValidationError = "Please enter a valid AWS endpoint URL."
    static let unkownErrorText = "Unknown or no response from the server. Please try again."
    static let notConnectedText = "* AWS Certificate and endpoints are not configured. To setup it, click the settings icon located in the top-right corner."
    static let connectedToAWS = "Connected to AWS Smart Lock"

}
