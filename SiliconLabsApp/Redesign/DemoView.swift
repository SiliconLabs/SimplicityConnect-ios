//
//  DemoView.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 23/06/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI

struct DemoView: UIViewControllerRepresentable {
    private var viewController: SILAppSelectionViewController!
    
    init() {
        let storyboard = UIStoryboard(name: "DemoAppSelection", bundle: nil)
        viewController = (storyboard.instantiateInitialViewController() as! SILAppSelectionViewController)
    }
    
    func makeUIViewController(context: Context) -> SILAppSelectionViewController {
        return viewController
    }
        
    func updateUIViewController(_ uiViewController:  SILAppSelectionViewController, context: Context) {
        
    }
}

struct DemoView_Previews: PreviewProvider {
    static var previews: some View {
        DemoView()
    }
}
