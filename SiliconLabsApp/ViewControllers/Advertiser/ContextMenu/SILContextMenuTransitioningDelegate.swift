//
//  SILContextMenuTransitioningDelegate.swift
//  BlueGecko
//
//  Created by Michał Lenart on 23/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILContextMenuTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    let sourceView: UIView
    
    init(sourceView: UIView) {
        self.sourceView = sourceView
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return SILContextMenuPresentationController(presentedViewController: presented, presenting: presenting, sourceView: sourceView)
    }
}
