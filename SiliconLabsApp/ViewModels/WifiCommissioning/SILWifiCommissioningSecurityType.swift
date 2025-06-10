//
//  SILWifiCommissioningSecurityType.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 24/11/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

enum SILWifiCommissioningSecurityType: Int {
    case unknown = -1
    case open = 0
    case wpa = 1
    case wpa2 = 2
    case wep = 3
    case eapWpa = 4
    case eapWpa2 = 5
    case wpaWpa2 = 6
    case wpa3 = 7
    case wpa3Transition = 8
    case wpa3Enterprise = 9
    case wpa3TransitionEnterprise = 10
    
    var name: String {
        get {
            switch self {
            case .open:
                return "OPEN";
            case .wpa:
                return "WPA";
            case .wpa2:
                return "WPA2";
            case .wep:
                return "WEP";
            case .eapWpa:
                return "EAP-WPA";
            case .eapWpa2:
                return "EAP-WPA2";
            case .wpaWpa2:
                return "WPA/WPA2";
            case .wpa3:
                return "WPA3";
            case .wpa3Enterprise:
                return "WPA3 Enterprise";
            case .wpa3Transition:
                return "WPA3 Transition";
            case .wpa3TransitionEnterprise:
                return "WPA3 Transition Enterprise";
            case .unknown:
                return "Unknown Mode";
            }
        }
    }
}
