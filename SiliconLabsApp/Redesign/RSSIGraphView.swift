//
//  RSSIGraphView.swift
//  BlueGecko
//
//  Created by Anastazja Gradowska on 14/09/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI

struct RSSIGraphView: UIViewControllerRepresentable, PickerTabSubview  {
    
    init() {
        let storyboard = UIStoryboard(name: "SILAppRSSIGraph", bundle: nil)
        viewController = (storyboard.instantiateInitialViewController() as! SILRSSIGraphViewController)
    }
    
    func makeUIViewController(context: Context) -> SILRSSIGraphViewController {
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: SILRSSIGraphViewController, context: Context) {
        
    }
    
    var viewController : UIViewControllerType!
    typealias UIViewControllerType = SILRSSIGraphViewController
    
    func setFloatingButton(settings: FloatingButtonSettings) {
        viewController.setFloatingButton(settings: settings)
    }
    
    func floatingButtonAction() {
        print("Main button in RSSI Graph is tapped")
        viewController.scanningButtonTapped()
    }
    
    var buttons : [NavBarButton] {
        [NavBarButton(id: "Filter button",image: Image("filterIcon"), action: {
            print("Filter button in  RSSI Graph is tapped")
            viewController.filterButtonTapped()
        }),
         NavBarButton(id: "Sort button",image: Image("sortIcon"), action: {
            print("Sort button in RSSI Graph is tapped")
            viewController.sortButtonTapped()
        }),
         NavBarButton(id: "Share button",image: Image( "shareWhite"), action: {
            print("Share button in RSSI Graph is tapped")
            viewController.exportButtonTapped()
        })]
    }
    
    var title: String = "RSSI Graph"
}

struct RSSIGraphView_Previews: PreviewProvider {
    static var previews: some View {
        RSSIGraphView()
    }
}



