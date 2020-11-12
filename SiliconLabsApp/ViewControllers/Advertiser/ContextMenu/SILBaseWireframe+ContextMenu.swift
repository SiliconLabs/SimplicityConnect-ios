//
//  SILBaseWireframe+ContextMenu.swift
//  BlueGecko
//
//  Created by Michał Lenart on 05/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

extension SILBaseWireframe {
    func presentContextMenu(sourceView: UIView, options: [ContextMenuOption]) {
        let storyboard = UIStoryboard(name: "SILContextMenuStoryboard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ContextMenu") as! SILContextMenuViewController
        let transitionDelegate = SILContextMenuTransitioningDelegate(sourceView: sourceView)
        
        vc.options = options

        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = transitionDelegate
        
        viewController.present(vc, animated: false) {
            let _ = transitionDelegate.description
        }
    }
    
    func open(url: String) {
        UIApplication.shared.open(URL(string: url)!)
    }
}
