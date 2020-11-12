//
//  SILContextMenuPresentationController.swift
//  BlueGecko
//
//  Created by Michał Lenart on 23/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILContextMenuPresentationController: UIPresentationController, UIGestureRecognizerDelegate {
    let sourceView: UIView
    let edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    init(presentedViewController: UIViewController, presenting: UIViewController?, sourceView: UIView) {
        self.sourceView = sourceView

        super.init(presentedViewController: presentedViewController, presenting: presenting)
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let screenSize = UIScreen.main.bounds.size;
        
        let sourceViewOrigin = sourceView.convert(CGPoint.zero, to: nil);
        
        let preferredSize = presentedViewController.preferredContentSize;
        
        let x = clamp(value: sourceViewOrigin.x, from: edgeInsets.left, to: screenSize.width - preferredSize.width - edgeInsets.right)
        var y = max(sourceViewOrigin.y, edgeInsets.top)
        let bottomOfView = sourceViewOrigin.y + preferredSize.height
        if bottomOfView > screenSize.height {
            y -= preferredSize.height
        }
        
        return CGRect(origin: CGPoint(x: x, y: y), size: preferredSize)
    }
    
    override func presentationTransitionWillBegin() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        gestureRecognizer.delegate = self
        self.containerView?.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc private func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        presentedViewController.dismiss(animated: false, completion: nil)
    }
    
    // MARK: UIViewControllerTransitioningDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
    
    // MARK: Utils
    
    private func clamp<T: Comparable>(value: T, from: T, to: T) -> T {
        return max(min(value, to), from)
    }
}
