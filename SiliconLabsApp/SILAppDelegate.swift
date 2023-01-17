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


class SILAppDelegate : UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        SILAppearance.setupAppearance()
        Fabric.with([Crashlytics.sharedInstance()])
        SILRealmConfiguration.updateRealmConfigurationIfNeeded()
        SILBluetoothModelManager.shared().populateModels()
        SILBrowserConnectionsViewModel.sharedInstance().centralManager = SILCentralManager(serviceUUIDs: [])
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIHostingController(rootView: MainNavigationView())
        window?.makeKeyAndVisible()
        return true
    }
}
