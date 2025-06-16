//
//  SILAppDelegate.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 23/06/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Fabric
import Crashlytics
import CoreHaptics
import CocoaLumberjack

class SILAppDelegate : UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    static var supportsHaptics: Bool = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        SILAppearance.setupAppearance()
        
        let hapticCapability = CHHapticEngine.capabilitiesForHardware()
        SILAppDelegate.supportsHaptics = hapticCapability.supportsHaptics
        debugPrint("Device supports haptics? \(SILAppDelegate.supportsHaptics)")
        
        Fabric.with([Crashlytics.sharedInstance()])
        SILRealmConfiguration.updateRealmConfigurationIfNeeded()
        SILBluetoothModelManager.shared().populateModels()
        SILBrowserLogViewModel.sharedInstance().clearLogs()
        SILBrowserConnectionsViewModel.sharedInstance().centralManager = SILCentralManager(serviceUUIDs: [])
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIHostingController(rootView: MainNavigationView())
        window?.makeKeyAndVisible()
        
        setupLogs()
        
        return true
    }
    private func setupLogs() {
        DDLog.add(DDOSLogger.sharedInstance)
        let fileLogger: DDFileLogger = DDFileLogger() // File Logger
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 30
        fileLogger.maximumFileSize = 1024 * 1024 * 10 // 10 MiB
        DDLog.add(fileLogger)
        //SBMLogger.sharedInstance().delegate = self;
    }
}
