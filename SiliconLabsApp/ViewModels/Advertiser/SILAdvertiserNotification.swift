//
//  SILAdvertiserNotification.swift
//  BlueGecko
//
//  Created by Michał Lenart on 05/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILAdvertiserNotification: NSObject, UNUserNotificationCenterDelegate {
    private static let NotificationIdentifier = "SILAdvertiserNotification"
    
    private let advertiserService: SILAdvertiserService
    
    private let userNotificationCenter = UNUserNotificationCenter.current()
    private let notificationCenter = NotificationCenter.default
    private weak var application = UIApplication.shared
    
    private let tokenBag = SILObservableTokenBag()
    
    private var isAppInBackground: Bool
    private var runningAdvertisers: [SILAdvertisingSetEntity] = []
    
    init(advertiserService: SILAdvertiserService) {
        self.isAppInBackground = application?.applicationState == .background
        self.advertiserService = advertiserService
        
        super.init()
        
        advertiserService.runningAdvertisers.observe { [weak self] advertisers in
            self?.runningAdvertisers = advertisers
            self?.updateNotification()
        }.putIn(bag: tokenBag)
        
        notificationCenter.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(willTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
        clearNotification()
    }
    
    func askForPermission() {
        userNotificationCenter.requestAuthorization(options: [.alert, .badge]) { (didAllow, error) in
            
        }
    }

    func showNotification() {
        userNotificationCenter.getNotificationSettings { (settings) in
            guard settings.authorizationStatus == .authorized else {
                return
            }
                        
            let content = UNMutableNotificationContent()
            content.title = "EFR Connect"
            content.body = "Advertiser is running..."
            content.badge = self.runningAdvertisers.count.number
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            let request = UNNotificationRequest(identifier: Self.NotificationIdentifier, content: content, trigger: trigger)
            self.userNotificationCenter.add(request)
        }
    }
    
    func clearNotification() {
        let application = self.application
        let userNotificationCenter = self.userNotificationCenter
        
        DispatchQueue.main.async {
            application?.applicationIconBadgeNumber = 0
            userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [Self.NotificationIdentifier])
            userNotificationCenter.removeDeliveredNotifications(withIdentifiers: [Self.NotificationIdentifier])
        }
    }
    
    private func updateNotification() {
        if isAppInBackground == true && !runningAdvertisers.isEmpty {
            showNotification()
        } else {
            clearNotification()
        }
    }
    
    // MARK: Application Lifecycle
    
    @objc func willEnterForeground() {
        isAppInBackground = false
        updateNotification()
    }
    
    @objc func didEnterBackground() {
        isAppInBackground = true
        updateNotification()
    }
    
    @objc func willTerminate() {
        clearNotification()
    }
}
