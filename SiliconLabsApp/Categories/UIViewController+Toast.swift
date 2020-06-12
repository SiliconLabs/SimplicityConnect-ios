//
//  UIViewController+Toast.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 11/05/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

@objc
public enum ToastType: Int {
    case disconnectionError
    case gattPropertiesError
}

@objc
extension UIViewController {
    @objc
    func showToast(message : String, toastType: ToastType, completion: @escaping () -> ()) {
        let values = displayParameters(for: toastType)
        let AnimationDuration = 0.5
        let AnimationDelay = values.delay
        let ToastHeight: CGFloat = values.height
        let ToastMargin: CGFloat = 16.0
        let ToastBottomSpacing: CGFloat = values.bottomSpacing
        let toastLabel = UILabel(frame: CGRect(x: ToastMargin, y: self.view.frame.size.height - ToastBottomSpacing, width: self.view.frame.size.width - 2 * ToastMargin, height: ToastHeight))
        toastLabel.backgroundColor = values.backgroundColor.withAlphaComponent(0.8)
        toastLabel.textColor = UIColor.white
        toastLabel.font = UIFont.robotoMedium(size: 14.0)
        toastLabel.textAlignment = .center
        toastLabel.numberOfLines = 0
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = CornerRadiusStandardValue
        toastLabel.clipsToBounds = true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: AnimationDuration, delay: AnimationDelay, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
            completion()
        })
    }
    
    @nonobjc
    private func displayParameters(for toastType: ToastType) -> (delay: Double, height: CGFloat, bottomSpacing: CGFloat, backgroundColor: UIColor) {
        switch toastType {
        case .disconnectionError:
            return (3.0, 60.0, 130.0, UIColor.sil_siliconLabsRed())
        case .gattPropertiesError:
            return (3.0, 60.0, 65.0, UIColor.sil_siliconLabsRed())
        @unknown default:
            return (0.0, 0.0, 0.0, .white)
        }
    }
}
