//
//  SILGattConfiguratorEntity.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 02/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import RealmSwift

protocol SILRealmObjectCopyable : class {
    associatedtype T
    func getCopy() -> T
}

protocol SILGattEntityComparable: class {
    associatedtype T
    func isEqualTo(_ entity: T) -> Bool
}

@objc enum SILGattConfigurationValueType: Int, RealmEnum {
    case none
    case hex
    case text
}

enum SILGattConfigurationPropertyType: String {
    case read = "read"
    case write = "write"
    case writeWithoutResponse = "writeWithoutResponse"
    case notify = "notify"
    case indicate = "indicate"
}

enum SILGattConfigurationAttributePermission: String {
    case none = "none"
    case bonded = "bonded"
}

struct SILGattConfigurationProperty: Equatable {
    var type: SILGattConfigurationPropertyType
    var permission: SILGattConfigurationAttributePermission
    
    func getDescription() -> String {
        return "\(self.type.rawValue):\(self.permission.rawValue)"
    }
}

@objcMembers
class SILGattConfigurationDescriptorEntity: Object, SILRealmObjectCopyable, SILGattEntityComparable {
    dynamic var uuid: String = UUID().uuidString
    dynamic var name: String?
    dynamic var cbuuidString: String = ""
    dynamic var _properties: String?
    var properties: [SILGattConfigurationProperty] {
        get {
            if let list = _properties {
                return list.split(separator: ",").map({
                    let properties = String($0).split(separator: ":")
                    let type = SILGattConfigurationPropertyType(rawValue: String(properties[0]))!
                    let attributePermission = SILGattConfigurationAttributePermission(rawValue: String(properties[1]))!
                    return SILGattConfigurationProperty(type: type, permission: attributePermission)
                })
            } else {
                return []
            }
        }
        set {
            _properties = newValue.map( { $0.getDescription() }).joined(separator: ",")
        }
    }
    dynamic var initialValueType: SILGattConfigurationValueType = .none
    dynamic var initialValue: String?
    dynamic var canBeModified: Bool = true
    dynamic var createdAt: Date = Date()
    
    override public static func primaryKey() -> String? {
        return "uuid"
    }
    
    func getCopy() -> SILGattConfigurationDescriptorEntity  {
        let copiedDescriptor = SILGattConfigurationDescriptorEntity()
        copiedDescriptor.name = self.name
        copiedDescriptor.cbuuidString = self.cbuuidString
        copiedDescriptor.properties = self.properties
        copiedDescriptor.initialValueType = self.initialValueType
        copiedDescriptor.initialValue = self.initialValue
        copiedDescriptor.canBeModified = self.canBeModified
        return copiedDescriptor
    }
    
    func isEqualTo(_ entity: SILGattConfigurationDescriptorEntity) -> Bool {
        return name == entity.name && cbuuidString == entity.cbuuidString && properties == entity.properties
            && initialValueType == entity.initialValueType && initialValue == entity.initialValue && canBeModified == entity.canBeModified
    }
}

@objcMembers
class SILGattConfigurationCharacteristicEntity: Object, SILRealmObjectCopyable, SILGattEntityComparable {
    dynamic var uuid: String = UUID().uuidString
    dynamic var name: String?
    dynamic var cbuuidString: String = ""
    dynamic var _properties: String?
    var properties: [SILGattConfigurationProperty] {
        get {
            if let list = _properties {
                return list.split(separator: ",").map({
                    let properties = String($0).split(separator: ":")
                    let type = SILGattConfigurationPropertyType(rawValue: String(properties[0]))!
                    let attributePermission = SILGattConfigurationAttributePermission(rawValue: String(properties[1]))!
                    return SILGattConfigurationProperty(type: type, permission: attributePermission)
                })
            } else {
                return []
            }
        }
        set {
            _properties = newValue.map( { $0.getDescription() }).joined(separator: ",")
        }
    }
    dynamic var initialValueType: SILGattConfigurationValueType = .none
    dynamic var initialValue: String?
    var descriptors = List<SILGattConfigurationDescriptorEntity>()
    dynamic var createdAt: Date = Date()
    
    override public static func primaryKey() -> String? {
        return "uuid"
    }
    
    func getCopy() -> SILGattConfigurationCharacteristicEntity  {
        let copiedCharacteristic = SILGattConfigurationCharacteristicEntity()
        copiedCharacteristic.name = self.name
        copiedCharacteristic.cbuuidString = self.cbuuidString
        copiedCharacteristic.properties = self.properties
        copiedCharacteristic.initialValueType = self.initialValueType
        copiedCharacteristic.initialValue = self.initialValue
        for descriptor in self.descriptors {
            copiedCharacteristic.descriptors.append(SILGattConfigurationDescriptorEntity(value: descriptor.getCopy()))
        }
        return copiedCharacteristic
    }
    
    func isEqualTo(_ entity: SILGattConfigurationCharacteristicEntity) -> Bool {
        if name != entity.name || cbuuidString != entity.cbuuidString || properties != entity.properties
            || initialValueType != entity.initialValueType || initialValue != entity.initialValue
            || descriptors.count != entity.descriptors.count {
            return false
        }
        for descriptor in descriptors {
            if let descriptorInComparingCharacteristic = entity.descriptors.first(where: { $0.cbuuidString == descriptor.cbuuidString }) {
                if !descriptor.isEqualTo(SILGattConfigurationDescriptorEntity(value: descriptorInComparingCharacteristic)) {
                    return false
                }
            } else {
                return false
            }
        }
        return true
    }
}

@objcMembers
class SILGattConfigurationServiceEntity: Object, SILRealmObjectCopyable, SILGattEntityComparable {
    dynamic var uuid: String = UUID().uuidString
    dynamic var name: String?
    dynamic var cbuuidString: String = ""
    dynamic var isPrimary: Bool = true
    var characteristics = List<SILGattConfigurationCharacteristicEntity>()
    dynamic var createdAt: Date = Date()
    
    override public static func primaryKey() -> String? {
        return "uuid"
    }
    
    func getCopy() -> SILGattConfigurationServiceEntity  {
        let copiedService = SILGattConfigurationServiceEntity()
        copiedService.name = self.name
        copiedService.cbuuidString = self.cbuuidString
        copiedService.isPrimary = self.isPrimary
        for characteristic in self.characteristics {
            copiedService.characteristics.append(SILGattConfigurationCharacteristicEntity(value: characteristic.getCopy()))
        }
        return copiedService
    }
    
    func isEqualTo(_ entity: SILGattConfigurationServiceEntity) -> Bool {
        if name != entity.name || cbuuidString != entity.cbuuidString || isPrimary != entity.isPrimary || characteristics.count != entity.characteristics.count {
            return false
        }
        for characteristic in characteristics {
            if let characteristicInComparingService = entity.characteristics.first(where: { $0.uuid == characteristic.uuid }) {
                if !characteristic.isEqualTo(SILGattConfigurationCharacteristicEntity(value: characteristicInComparingService)) {
                    return false
                }
            } else {
                return false
            }
        }
        return true
    }
}

@objcMembers
class SILGattConfigurationEntity: Object, SILRealmObjectCopyable, SILGattEntityComparable {
    dynamic var uuid: String = UUID().uuidString
    dynamic var name: String = ""
    dynamic var createdAt: Date = Date()
    var services = List<SILGattConfigurationServiceEntity>()
    
    override public static func primaryKey() -> String? {
        return "uuid"
    }
    
    func getCopy() -> SILGattConfigurationEntity {
        let copiedConfiguration = SILGattConfigurationEntity()
        copiedConfiguration.name = self.name
        for service in self.services {
            copiedConfiguration.services.append(SILGattConfigurationServiceEntity(value: service.getCopy()))
        }
        return copiedConfiguration
    }
    
    func isEqualTo(_ entity: SILGattConfigurationEntity) -> Bool {
        if name != entity.name || services.count != entity.services.count {
            return false
        }
        return true
    }
}
