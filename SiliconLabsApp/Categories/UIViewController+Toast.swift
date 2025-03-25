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
    case info
    case characteristicPasteAlert
    case characteristicError
    case advertiserTimeLimitError
}

@objc
extension UIViewController {
    @objc
    func showToast(message: String, toastType: ToastType, completion: @escaping () -> ()) {
        showToast(message: message, toastType: toastType, shouldHasSizeOfText: false, completion: completion)
    }
    
    @objc
    func showToast(message : String, toastType: ToastType, shouldHasSizeOfText: Bool, completion: @escaping () -> ()) {
        let animationDuration = 5.0
        let AnimationDelay = displayParameters(for: toastType).delay
        let toastLabel = getToastLabel(shouldHasSizeOfText: shouldHasSizeOfText, withMessage: message, toastType: toastType)
        self.view.addSubview(toastLabel)
                
        UIView.animate(withDuration: 1, delay: 0.2, options: .curveEaseOut, animations: {
            toastLabel.alpha = 1
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                UIView.animate(withDuration: 1) {
                    toastLabel.alpha = 0
                    toastLabel.removeFromSuperview()
                }
                completion()
            }
        }
    }
    
    @objc
    func getToastLabel(shouldHasSizeOfText:Bool, withMessage message: String, toastType: ToastType) -> UILabel {
        let values = displayParameters(for: toastType)
        let toastMargin = values.margin
        let toastTopSpacing = values.topSpacing
        let toastLabel = UILabel()
        if shouldHasSizeOfText {
            let toastSize = countSizeOfText(message, withFont: UIFont.robotoMedium(size: 14.0)!)
            toastLabel.frame =  CGRect(x: (self.view.frame.width - toastSize.width - toastMargin) / 2, y: self.view.safeAreaInsets.top + toastTopSpacing, width: toastSize.width + toastMargin, height: toastSize.height + toastMargin)
        }
        else {
            let toastHeight = values.height
            toastLabel.frame = CGRect(x: toastMargin, y: self.view.safeAreaInsets.top + toastTopSpacing, width: self.view.frame.size.width - 2 * toastMargin, height: toastHeight)
        }
        toastLabel.backgroundColor = values.backgroundColor.withAlphaComponent(0.8)
        toastLabel.textColor = values.labelTextColor
        toastLabel.font = UIFont.robotoMedium(size: 14.0)
        toastLabel.textAlignment = .center
        toastLabel.numberOfLines = 0
        toastLabel.text = message
        toastLabel.alpha = 0.0
        toastLabel.layer.cornerRadius = CornerRadiusStandardValue
        toastLabel.clipsToBounds = true
        return toastLabel
    }
    
    private func countSizeOfText(_ text: String, withFont font: UIFont) -> CGSize {
        return text.size(withAttributes: [.font: font])
    }
    
    @nonobjc
    private func displayParameters(for toastType: ToastType) -> (delay: Double, height: CGFloat, margin: CGFloat,  topSpacing: CGFloat, labelTextColor: UIColor, backgroundColor: UIColor) {
        switch toastType {
        case .disconnectionError:
            return (3.0, 60.0, 16.0, 24.0, UIColor.white, UIColor.sil_siliconLabsRed())
        case .gattPropertiesError:
            return (3.0, 60.0, 16.0, 24.0, UIColor.white, UIColor.sil_siliconLabsRed())
        case .info:
            return (3.0, 60.0, 32.0, 24.0, UIColor.black, UIColor.sil_bgGrey())
        case .characteristicPasteAlert:
            return (3.0, 60.0, 32.0, 24.0, UIColor.white, UIColor.sil_siliconLabsRed())
        case .characteristicError:
            return (3.0, 60.0, 16.0, 24.0, UIColor.white, UIColor.sil_siliconLabsRed())
        case .advertiserTimeLimitError:
            return (3.0, 60.0, 32.0, 24.0, UIColor.white, UIColor.sil_siliconLabsRed())
        @unknown default:
            return (0.0, 0.0, 0.0, 0.0, UIColor.white, .white)
        }
    }
    
    class func topViewController(controller: UIViewController? = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
    
    func addObserverForDisplayToastResponse() {
        NotificationCenter.default.addObserver(self, selector:#selector(displayToast(_:)), name: NSNotification.Name(rawValue: SILNotificationDisplayToastResponse), object: nil)
    }
    
    @objc private func displayToast(_ notification: Notification) {
        let ErrorMessage = notification.userInfo?[SILNotificationKeyDescription] as? String ?? ""
        self.showToast(message: ErrorMessage, toastType: .disconnectionError) {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: SILNotificationDisplayToastRequest), object: nil)
        }
    }
}
