//
//  ActiveConnectionsView.swift
//  BlueGecko
//
//  Created by Anastazja Gradowska on 22/08/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI

struct ActiveConnectionsView: UIViewControllerRepresentable, PickerTabSubview {
    typealias UIViewControllerType = SILBrowserConnectionsViewController
    
    var buttons : [NavBarButton] {
        []
    }
    
    var title: String {
        get {
            "(\(SILBrowserConnectionsViewModel.sharedInstance().peripherals.count)) ACTIVE CONNECTIONS"
        }
    }
    
    var viewController : SILBrowserConnectionsViewController!
    
    init() {
        let storyboard = UIStoryboard(name: SILAppBluetoothBrowserHome, bundle: nil)
        viewController = (storyboard.instantiateViewController(withIdentifier: SILSceneConnections) as! SILBrowserConnectionsViewController)
    }
    
    func makeUIViewController(context: Context) -> SILBrowserConnectionsViewController {
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: SILBrowserConnectionsViewController, context: Context) {
        
    }
    
    func setFloatingButton(settings: FloatingButtonSettings) {
        viewController.setupFloatingButtonSettings(settings)
    }
    
    func floatingButtonAction() {
        print("Disconnect All button in ActiveConnectionsView")
        viewController.disconnectAllTapped()
    }
    
}

struct ActiveConnectionsView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveConnectionsView()
    }
}
