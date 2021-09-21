//
//  SILGattConfiguratorEntity.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 02/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import AEXML
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

struct SILGattXMLAttribute {
    let name: String
    var value: String
    
    init(name: String, value: String) {
        self.name = name
        self.value = value
    }
    
    init(pairString: String) {
        let pair = String(pairString).split(separator: ":")
        self.name = String(pair[0])
        self.value = pair.count == 2 ? String(pair[1]) : ""
    }
    
    func getPairString() -> String {
        return "\(self.name):\(self.value)"
    }
}

protocol SILGattXmlNodeInfo {
    dynamic var _additionalXmlAttributes: String? { get set }
    var additionalXmlAttributes: [SILGattXMLAttribute] { get set }
    dynamic var _additionalXmlChildren: String? { get set }
    var additionalXmlChildren: [AEXMLElement] { get set }
    var xmlNodeName: String { get }
    func getAttributeValue(attribute: DatabaseXmlAttribute) -> String?
}

extension SILGattXmlNodeInfo {
    var additionalXmlAttributes: [SILGattXMLAttribute] {
        get {
            if let attributes = _additionalXmlAttributes, attributes.count != 0 {
                return attributes.components(separatedBy: ":::").map { SILGattXMLAttribute(pairString: $0) }
            } else {
                return []
            }
        }
        set {
            _additionalXmlAttributes = newValue.map({ $0.getPairString() }).joined(separator: ":::")
        }
    }
    
    var additionalXmlChildren: [AEXMLElement] {
        get {
            if let children = _additionalXmlChildren, children.count != 0 {
                return children.components(separatedBy: ":::").map { try! AEXMLDocument(xml: $0.data).root }
            } else {
                return []
            }
        }
        set {
            _additionalXmlChildren = newValue.map({ "\($0.xml)"}).joined(separator: ":::")
        }
    }
    
    func getAttributeValue(attribute: DatabaseXmlAttribute) -> String? {
        if let foundAttribute = self.additionalXmlAttributes.first(where: { $0.name == attribute.name }) {
            return foundAttribute.value
        } else {
            return attribute.defaultValue
        }
    }
}

@objc enum SILGattConfigurationValueType: Int, RealmEnum {
    case none
    case hex
    case text
    
    var xmlTag: String? {
        switch self {
        case .text:
            return SILGattConfiguratorXmlDatabase.GattConfigurationValue.textTypeString
        case .hex:
            return SILGattConfiguratorXmlDatabase.GattConfigurationValue.hexTypeString
        default:
            return nil
        }
    }
}

enum SILGattConfigurationPropertyType: String, CaseIterable {
    case read = "read"
    case write = "write"
    case writeWithoutResponse = "writeWithoutResponse"
    case notify = "notify"
    case indicate = "indicate"
    
    var xmlTag: String {
        switch self {
        case .read, .write, .notify, .indicate:
            return self.rawValue
        case .writeWithoutResponse:
            return "write_no_response"
        }
    }
}

enum SILGattConfigurationAttributePermission: String {
    case none = "none"
    case bonded = "bonded"
}

struct SILGattConfigurationProperty: Equatable, SILGattXmlNodeInfo {
    static func == (lhs: SILGattConfigurationProperty, rhs: SILGattConfigurationProperty) -> Bool {
        return lhs.type == rhs.type && lhs.permission == rhs.permission
    }
    
    var type: SILGattConfigurationPropertyType
    var permission: SILGattConfigurationAttributePermission
    
    dynamic var _additionalXmlAttributes: String? = nil
    dynamic var _additionalXmlChildren: String? = nil
    var xmlNodeName: String {
        get {
            return self.type.xmlTag
        }
    }
    
    func getDescription() -> String {
        return "\(self.type.rawValue):\(self.permission.rawValue)"
    }
}

@objcMembers
class SILGattConfigurationDescriptorEntity: Object, SILRealmObjectCopyable, SILGattEntityComparable, SILGattXmlNodeInfo {
    
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
    dynamic var fixedVariableLength = false
    dynamic var canBeModified: Bool = true
    dynamic var createdAt: Date = Date()
    
    dynamic var _additionalXmlAttributes: String?
    dynamic var _additionalXmlChildren: String?
    var xmlNodeName: String = "descriptor"
    
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
        copiedDescriptor.fixedVariableLength = self.fixedVariableLength
        copiedDescriptor.canBeModified = self.canBeModified
        copiedDescriptor._additionalXmlAttributes = _additionalXmlAttributes
        copiedDescriptor._additionalXmlChildren = _additionalXmlChildren
        return copiedDescriptor
    }
    
    func isEqualTo(_ entity: SILGattConfigurationDescriptorEntity) -> Bool {
        return name == entity.name && cbuuidString == entity.cbuuidString && properties == entity.properties
            && initialValueType == entity.initialValueType && initialValue == entity.initialValue && canBeModified == entity.canBeModified && fixedVariableLength == entity.fixedVariableLength
    }
}

@objcMembers
class SILGattConfigurationCharacteristicEntity: Object, SILRealmObjectCopyable, SILGattEntityComparable, SILGattXmlNodeInfo {
    
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
    dynamic var fixedVariableLength = false
    var descriptors = List<SILGattConfigurationDescriptorEntity>()
    dynamic var createdAt: Date = Date()
    
    dynamic var _additionalXmlAttributes: String?
    dynamic var _additionalXmlChildren: String?
    var xmlNodeName: String = "characteristic"

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
        copiedCharacteristic.fixedVariableLength = self.fixedVariableLength
        for descriptor in self.descriptors {
            copiedCharacteristic.descriptors.append(SILGattConfigurationDescriptorEntity(value: descriptor.getCopy()))
        }
        copiedCharacteristic._additionalXmlAttributes = _additionalXmlAttributes
        copiedCharacteristic._additionalXmlChildren = _additionalXmlChildren
        return copiedCharacteristic
    }
    
    func isEqualTo(_ entity: SILGattConfigurationCharacteristicEntity) -> Bool {
        if name != entity.name || cbuuidString != entity.cbuuidString || properties != entity.properties
            || initialValueType != entity.initialValueType || initialValue != entity.initialValue || fixedVariableLength != entity.fixedVariableLength || descriptors.count != entity.descriptors.count {
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
class SILGattConfigurationServiceEntity: Object, SILRealmObjectCopyable, SILGattEntityComparable, SILGattXmlNodeInfo {
    dynamic var uuid: String = UUID().uuidString
    dynamic var name: String?
    dynamic var cbuuidString: String = ""
    dynamic var isPrimary: Bool = true
    var characteristics = List<SILGattConfigurationCharacteristicEntity>()
    dynamic var createdAt: Date = Date()
    
    dynamic var _additionalXmlAttributes: String?
    dynamic var _additionalXmlChildren: String?
    var xmlNodeName: String = "service"
    
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
        copiedService._additionalXmlAttributes = _additionalXmlAttributes
        copiedService._additionalXmlChildren = _additionalXmlChildren
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
class SILGattProjectEntity: Object, SILRealmObjectCopyable, SILGattEntityComparable, SILGattXmlNodeInfo {
    dynamic var uuid: String = UUID().uuidString
    dynamic var createdAt: Date = Date()
    
    var _additionalXmlAttributes: String?
    var _additionalXmlChildren: String?
    var xmlNodeName: String = "project"
    
    override public static func primaryKey() -> String? {
        return "uuid"
    }
    
    func getCopy() -> SILGattProjectEntity {
        let copiedConfiguration = SILGattProjectEntity()
        copiedConfiguration._additionalXmlChildren = _additionalXmlChildren
        copiedConfiguration._additionalXmlAttributes = _additionalXmlAttributes
        return copiedConfiguration
    }
    
    func isEqualTo(_ entity: SILGattProjectEntity) -> Bool {
        return self._additionalXmlAttributes == entity._additionalXmlAttributes && self._additionalXmlChildren == entity._additionalXmlChildren
    }
}

@objcMembers
class SILGattConfigurationEntity: Object, SILRealmObjectCopyable, SILGattEntityComparable, SILGattXmlNodeInfo {
    dynamic var uuid: String = UUID().uuidString
    dynamic var name: String = ""
    dynamic var createdAt: Date = Date()
    var services = List<SILGattConfigurationServiceEntity>()
    dynamic var projectEntity: SILGattProjectEntity? = nil
    
    dynamic var _additionalXmlAttributes: String?
    dynamic var _additionalXmlChildren: String?
    var xmlNodeName: String = "gatt"

    override public static func primaryKey() -> String? {
        return "uuid"
    }
    
    func getCopy() -> SILGattConfigurationEntity {
        let copiedConfiguration = SILGattConfigurationEntity()
        copiedConfiguration.name = self.name
        for service in self.services {
            copiedConfiguration.services.append(SILGattConfigurationServiceEntity(value: service.getCopy()))
        }
        copiedConfiguration._additionalXmlAttributes = _additionalXmlAttributes
        copiedConfiguration._additionalXmlChildren = _additionalXmlChildren
        return copiedConfiguration
    }
    
    func isEqualTo(_ entity: SILGattConfigurationEntity) -> Bool {
        if name != entity.name || services.count != entity.services.count {
            return false
        }
        return true
    }
}
