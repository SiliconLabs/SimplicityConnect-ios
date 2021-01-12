//
//  SILContextMenu.swift
//  BlueGecko
//
//  Created by Michal Lenart on 17/12/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILContextMenu {
    public static func present(owner: UIViewController, sourceView: UIView, options: [ContextMenuOption]) {
        let storyboard = UIStoryboard(name: "SILContextMenuStoryboard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ContextMenu") as! SILContextMenuViewController
        let transitionDelegate = SILContextMenuTransitioningDelegate(sourceView: sourceView)
        
        vc.options = options

        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = transitionDelegate
        
        owner.present(vc, animated: false) {
            let _ = transitionDelegate.description
        }
    }
}
