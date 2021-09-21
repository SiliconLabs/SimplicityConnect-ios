//
//  SILGattXmlExportable.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 21/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML

protocol SILGattXmlExportable {
    func export() -> AEXMLElement
}
