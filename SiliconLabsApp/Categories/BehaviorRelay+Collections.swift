//
//  BehaviorRelay+Collections.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 08/03/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation
import RxCocoa

extension BehaviorRelay {
    func addElement<T>(element: T) where Element == [T] {
        accept(value + [element])
    }

    func removeElement<T>(element: T) where Element == [T], T: Equatable {
        accept(value.filter {$0 != element})
    }

    func addElement<T, U>(key: T, value: U) where Element == [T: U] {
        accept(self.value.merging([key: value]) { (_, new) in new })
    }
    
    func removeElement<T, U>(key: T) where Element == [T: U], U: Any {
        accept(self.value.filter {dictElement in dictElement.key != key})
    }
}
