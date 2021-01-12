//
//  UIViewController+Context.swift
//  BlueGecko
//
//  Created by Michal Lenart on 03/12/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

extension UIViewController {
    /// Provide any context down to the UIViewController tree. Context can be retrieved with sil_useContext method in any UIViewController descendant.
    func sil_provideContext<T>(type: T.Type, value: T?) {
        let key = String(describing: T.self)
        self.sil_setAssociatedObject(value, forKey: key)
    }
   
    /// Get context with given type that was provider in any UIViewController ancestor.
    func sil_useContext<T>(type: T.Type) -> T? {
        let key = String(describing: T.self)

        if let value = self.sil_associatedObject(key) as? T {
            return value
        } else {
            return parent?.sil_useContext(type: type)
        }
    }
}
