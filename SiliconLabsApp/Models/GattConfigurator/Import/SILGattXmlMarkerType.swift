//
//  SILGattXmlMarkerType.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 31.5.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML

protocol SILGattConfigurationEntityType { }

extension SILGattConfigurationEntity: SILGattConfigurationEntityType { }
extension SILGattConfigurationServiceEntity: SILGattConfigurationEntityType { }
extension SILGattConfigurationCharacteristicEntity: SILGattConfigurationEntityType { }
extension SILGattConfigurationDescriptorEntity: SILGattConfigurationEntityType { }
extension SILGattPropertyEntity: SILGattConfigurationEntityType { }
extension SILGattPropertiesEntity: SILGattConfigurationEntityType { }
extension SILGattConfigurationProperty: SILGattConfigurationEntityType { }
extension SILGattValueEntity: SILGattConfigurationEntityType { }
extension SILGattCapabilitiesDeclareEntity: SILGattConfigurationEntityType { }
extension SILGattCapabilitiesEntity: SILGattConfigurationEntityType { }
extension SILGattProjectEntity: SILGattConfigurationEntityType { }

protocol SILGattXmlMarkerType {
    associatedtype GattConfigurationEntity where GattConfigurationEntity: SILGattConfigurationEntityType
    var element: AEXMLElement { get set }
    mutating func parse() -> Result<GattConfigurationEntity, SILGattXmlParserError>
}

