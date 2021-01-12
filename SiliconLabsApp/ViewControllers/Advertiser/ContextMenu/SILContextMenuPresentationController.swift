//
//  SILContextMenuPresentationController.swift
//  BlueGecko
//
//  Created by Michał Lenart on 23/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILContextMenuPresentationController: UIPresentationController, UIGestureRecognizerDelegate {
    private let sourceView: UIView
    
    private lazy var screenSize: CGSize = {
        return UIScreen.main.bounds.size
    }()

    private lazy var edgeInsets: UIEdgeInsets = {
        let safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets ?? UIEdgeInsets.zero

        return UIEdgeInsets(
            top: safeAreaInsets.top + 5,
            left: safeAreaInsets.left + 5,
            bottom: safeAreaInsets.bottom + 5,
            right: safeAreaInsets.right + 5)
    }()
    
    private lazy var sourceViewOrigin: CGPoint = {
        return sourceView.convert(CGPoint.zero, to: nil)
    }()
    
    private lazy var sourceViewSize: CGSize = {
        return sourceView.bounds.size
    }()
    
    private lazy var preferredSize: CGSize = {
        return presentedViewController.preferredContentSize
    }()
    
    init(presentedViewController: UIViewController, presenting: UIViewController?, sourceView: UIView) {
        self.sourceView = sourceView

        super.init(presentedViewController: presentedViewController, presenting: presenting)
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let horizontal = calculateHorizontal()
        let vertical = calculateVertical()
        
        return CGRect(origin: CGPoint(x: horizontal.x, y: vertical.y), size: CGSize(width: horizontal.width, height: vertical.height))
    }
    
    private func calculateHorizontal() -> (x: CGFloat, width: CGFloat) {
        let x = clamp(value: sourceViewOrigin.x, from: edgeInsets.left, to: screenSize.width - preferredSize.width - edgeInsets.right)
        let width = clamp(value: preferredSize.width, from: 0, to: screenSize.width - edgeInsets.left - edgeInsets.right)
        
        return (x, width)
    }
    
    private func calculateVertical() -> (y: CGFloat, height: CGFloat) {
        var y: CGFloat
        var height: CGFloat
        
        let heightAboveSourceView = sourceViewOrigin.y - edgeInsets.top
        let heightBelowSourceView = screenSize.height - sourceViewOrigin.y - sourceViewSize.height - edgeInsets.bottom
        let displayBelowSourceView = preferredSize.height <= heightBelowSourceView || heightBelowSourceView >= heightAboveSourceView
        
        if displayBelowSourceView {
            y = sourceViewOrigin.y + sourceViewSize.height
            height = clamp(value: preferredSize.height, from: 0, to: heightBelowSourceView)
        } else {
            y = clamp(value: sourceViewOrigin.y - preferredSize.height, from: edgeInsets.top, to: sourceViewOrigin.y)
            height = clamp(value: preferredSize.height, from: 0, to: heightAboveSourceView)
        }
        
        return (y: y, height: height)
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
