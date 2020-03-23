//
//  SILMap.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 03/03/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation
import RealmSwift

public protocol SILMap: class {
    dynamic var uuid: String { get set }
    dynamic var name: String { get set }
    
    static func remove(map uuid: String) -> Bool
}
