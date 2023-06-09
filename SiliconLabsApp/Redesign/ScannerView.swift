//
//  ScannerView.swift
//  BlueGecko
//
//  Created by Anastazja Gradowska on 22/08/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI

struct ScannerView: UIViewControllerRepresentable, PickerTabSubview {
    private var viewController: SILBluetoothBrowserViewController!
    
    init() {
        let storyboard = UIStoryboard(name: "SILAppBluetoothBrowser", bundle: nil)
        viewController = (storyboard.instantiateInitialViewController() as! SILBluetoothBrowserViewController)
    }
    
    func setFloatingButton(settings: FloatingButtonSettings) {
        viewController.setupFloatingButtonSettings(settings)
    }
    
    func floatingButtonAction() {
        print("Floating button in ScannerView")
        viewController.scanningButtonWasTapped()
    }
    
    var buttons : [NavBarButton] {
        [NavBarButton(id: "Mapping button", image: Image( "icon - dictionary - book"), action: {
            print("Mappings button in ScannerView is tapped")
            viewController.mapButtonTapped()
        }),
         NavBarButton(id: "Filter button", image: Image("filterIcon"), action: {
            print("Filter button in ScannerView is tapped")
            viewController.filterButtonTapped()
        }),
         NavBarButton(id: "Sort button", image: Image("sortIcon"), action: {
            print("Sort button in ScannerView is tapped")
            viewController.sortButtonTapped()
        })]
    }
    
    var title: String = "Scanner"
    
    func makeUIViewController(context: Context) -> SILBluetoothBrowserViewController {
        return viewController
    }
        
    func updateUIViewController(_ uiViewController:  SILBluetoothBrowserViewController, context: Context) {
        
    }
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}
