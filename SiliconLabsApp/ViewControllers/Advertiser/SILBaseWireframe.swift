//
//  BaseWireframe.swift
//  BlueGecko
//
//  Created by Michał Lenart on 29/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILBaseWireframeType : class {
    var viewController: UIViewController { get }
    var navigationController: UINavigationController? { get }
    
    init(viewController: UIViewController)
    func releaseViewController()
    func presentToastAlert(message : String, toastType: ToastType, shouldHasSizeOfText: Bool, completion: @escaping () -> ())
    func presentContextMenu(sourceView: UIView, options: [ContextMenuOption])
    func open(url: String)
}

class SILBaseWireframe: NSObject, SILBaseWireframeType {
    private(set) unowned var viewController: UIViewController
    private var viewControllerReference: UIViewController?
    
    var navigationController: UINavigationController? {
        return viewController.navigationController
    }

    required init(viewController: UIViewController) {
        self.viewController = viewController
        self.viewControllerReference = viewController
    }

    func releaseViewController() {
        self.viewControllerReference = nil
    }
    
    func presentToastAlert(message : String, toastType: ToastType, shouldHasSizeOfText: Bool, completion: @escaping () -> ()) {
        self.viewController.showToast(message: message, toastType: toastType, shouldHasSizeOfText: shouldHasSizeOfText, completion: completion)
    }
}

extension UIViewController {
    func presentWireframe(_ wireframe: SILBaseWireframe, animated: Bool = true, completion: (()->())? = nil) {
        present(wireframe.viewController, animated: animated, completion: completion)
        wireframe.releaseViewController()
    }
}

extension UINavigationController {
    func pushWireframe(_ wireframe: SILBaseWireframe, animated: Bool = true) {
        self.pushViewController(wireframe.viewController, animated: animated)
        wireframe.releaseViewController()
    }

    func setRootWireframe(_ wireframe: SILBaseWireframe, animated: Bool = true) {
        self.setViewControllers([wireframe.viewController], animated: animated)
        wireframe.releaseViewController()
    }
}
