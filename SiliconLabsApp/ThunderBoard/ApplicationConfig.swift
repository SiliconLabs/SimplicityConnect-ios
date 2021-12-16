//
//  UIApplication+EnvironmentConfiguration.swift
//  ThunderBoard
//
//  Copyright © 2015 Silicon Labs. All rights reserved.
//

import UIKit

class ApplicationConfig {
    
    // URL used for microsite links (sent in demo emails)
    class var ProductMicroSiteUrl: String {
        get { return "http://www.silabs.com" }
    }

    // Firebase IO Host ("your-application-0001.firebaseio.com")
    class var FirebaseIoHost: String {
        get { return "smoldering-ember-2016.firebaseio.com" }
    }
    
    // Firebase web app host ("your-application-0001.firebaseapp.com")
    class var FirebaseDemoHost: String {
        get { return "smoldering-ember-2016.firebaseio.com" }
    }

    // Firebase token (40 character string from your Firebase account)
    class var FirebaseToken: String {
        get { return "AIzaSyBchrm2wi0gxIhloko-KTQahaui8v29zXw" }
    }
}
