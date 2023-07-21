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

class SILAppDelegate : UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    static var supportsHaptics: Bool = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        SILAppearance.setupAppearance()
        applicationStart()
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

        return true
    }
    func applicationStart(){
        print("Hello this is my first code.")
        
    }
}
