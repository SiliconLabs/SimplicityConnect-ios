//
//  IOPView.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 05/10/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI

struct IOPView: UIViewControllerRepresentable, PickerTabSubview {
    var viewController : SILIOPTestDeviceSelectorController!
    
    init(){
        let storyboard = UIStoryboard(name: "SILIOPTest", bundle: nil)
        viewController = (storyboard.instantiateViewController(withIdentifier: "SILIOPTestDeviceSelector") as! SILIOPTestDeviceSelectorController)
    }
    
    func makeUIViewController(context: Context) -> SILIOPTestDeviceSelectorController {
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: SILIOPTestDeviceSelectorController, context: Context) {
        
    }
    
    func floatingButtonAction() {
    }
    
    func setFloatingButton(settings: FloatingButtonSettings) {
        settings.setPresented(false)
    }
    
    var buttons : [NavBarButton] {
        [NavBarButton(id: "Info button", image: Image(systemName: "questionmark.circle"), action: {
            print("Second button iop")
            viewController.presentInfoPopup(animated: true)
        })]
    }
    
    var title: String = "Interoperability Test"
}

struct IOPView_Previews: PreviewProvider {
    static var previews: some View {
        IOPView()
    }
}
