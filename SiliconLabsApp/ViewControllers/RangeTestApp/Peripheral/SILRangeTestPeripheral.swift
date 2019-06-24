//
//  SILRangeTestPeripheral.swift
//  SiliconLabsApp
//
//  Created by Piotr Sarna on 29.05.2018.
//  Copyright © 2018 SiliconLabs. All rights reserved.
//

import UIKit

//MARK: - Peripheral delegate
protocol SILRangeTestPeripheralDelegate {
    func didUpdate(connectionState: CBPeripheralState)
    func didUpdate(manufacturerData: SILRangeTestManufacturerData?)
}

// MARK: - SILRangeTestPeripheral implementation
@objc
@objcMembers
class SILRangeTestPeripheral: NSObject {
    private typealias RawCharacteristics = [CBUUID: [CBUUID: CBCharacteristic]]
    private typealias Characteristics = [CBUUID: [CBUUID: SILRangeTestCharacteristic]]
    private typealias ValueCallbacks = [CBUUID: [CBUUID: (SILRangeTestCharacteristic) -> Void]]
    
    private var peripheral: CBPeripheral
    private let manager: SILCentralManager
    private var valuesCallbacks: ValueCallbacks = [:]
    private var characteristics: Characteristics = [:]
    private var alreadyDiscoveredCharacteristics: RawCharacteristics = [:]
    
    var delegate: SILRangeTestPeripheralDelegate? = nil
    private(set) var manufacturerData: SILRangeTestManufacturerData? = nil
    var state: CBPeripheralState {
        get {
            return peripheral.state
        }
    }
    
    init(withPeripheral peripheral: CBPeripheral, andCentralManager manager: SILCentralManager) {
        self.manager = manager
        self.peripheral = peripheral
        
        super.init()
        
        prepareCharacteristics()
        self.peripheral.delegate = self
        registerForConnectingNotifications()
    }
    
    func discoveredPeripheral() -> SILDiscoveredPeripheral? {
        return manager.discoveredPeripheral(for: peripheral)
    }
    
    func clearCallbacks() {
        valuesCallbacks.removeAll()
    }
    
    func connect() {
        guard let peripheral = discoveredPeripheral() else {
            return
        }
        
        prepareCharacteristics()
        alreadyDiscoveredCharacteristics = [:]
        manager.connect(to: peripheral)
    }
    
    func disconnect() {
        manager.disconnectConnectedPeripheral()
    }
    
    private func prepareCharacteristics() {
        var characteristics: Characteristics = [:]
        
        for (characteristic, _) in SILRangeTestCharacteristic.deviceInformationServiceCharacteristics {
            let rtChar = SILRangeTestCharacteristic(characteristic, forPeripheral: self)
            
            if characteristics[rtChar.serviceUuid] == nil {
                characteristics[rtChar.serviceUuid] = [:]
            }
            
            characteristics[rtChar.serviceUuid]![rtChar.uuid] = rtChar
        }
        
        for (characteristic, _) in SILRangeTestCharacteristic.rangeTestServiceCharacteristics {
            let rtChar = SILRangeTestCharacteristic(characteristic, forPeripheral: self)
            
            if characteristics[rtChar.serviceUuid] == nil {
                characteristics[rtChar.serviceUuid] = [:]
            }
            
            characteristics[rtChar.serviceUuid]![rtChar.uuid] = rtChar
        }
        
        self.characteristics = characteristics
    }

    private func getValue(forCharacteristic characteristicUUID: CBUUID, inService serviceUUID: CBUUID, withDataCallback dataCallback: @escaping (SILRangeTestCharacteristic) -> Void) {
        registerForGetValue(dataRequest: dataCallback, forCharacteristic: characteristicUUID, inService: serviceUUID)
        
        let peripheralService = peripheral.services?.first { $0.uuid == serviceUUID }
        
        guard let service = peripheralService else {
            peripheral.discoverServices([serviceUUID])
            return
        }
        
        let peripheralCharacteristic = service.characteristics?.first { $0.uuid == characteristicUUID }
        
        guard let characteristic = peripheralCharacteristic else {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
            return
        }
        
        peripheral.readValue(for: characteristic)
    }
    
    private func setValue(withData data: Data, forCharacteristic characteristicUUID: CBUUID, inService serviceUUID: CBUUID) {
        let peripheralService = peripheral.services?.first { $0.uuid == serviceUUID }
        let peripheralCharacteristic = peripheralService?.characteristics?.first { $0.uuid == characteristicUUID }
        
        if let characteristic = peripheralCharacteristic {
            let rtCharacteristic = characteristics[serviceUUID]![characteristicUUID]!
            let currentValue = rtCharacteristic.valueData
            
            if currentValue != data {
                peripheral.writeValue(data, for: characteristic, type: .withResponse)
            }
        }
    }
    
    private func registerForGetValue(dataRequest: @escaping (SILRangeTestCharacteristic) -> Void, forCharacteristic characteristicUUID: CBUUID, inService serviceUUID: CBUUID) {
        if valuesCallbacks[serviceUUID] == nil {
            valuesCallbacks[serviceUUID] = [:]
        }
        
        valuesCallbacks[serviceUUID]![characteristicUUID] = dataRequest
    }
}

// MARK: - Connecting
extension SILRangeTestPeripheral {
    private func registerForConnectingNotifications() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.SILCentralManagerDidConnectPeripheral,
                                               object: nil,
                                               queue: nil,
                                               using: didConnectPeripheral)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.SILCentralManagerDidFailToConnectPeripheral,
                                               object: nil,
                                               queue: nil,
                                               using: didFailToConnectPeripheral)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.SILCentralManagerDidDisconnectPeripheral,
                                               object: nil,
                                               queue: nil,
                                               using: didDisconnectPeripheral)
    }
    
    private func didConnectPeripheral(_ notification: Notification) {
        delegate?.didUpdate(connectionState: state)
    }
    
    private func didFailToConnectPeripheral(_ notification: Notification) {
        delegate?.didUpdate(connectionState: state)
    }
    
    private func didDisconnectPeripheral(_ notification: Notification) {
        delegate?.didUpdate(connectionState: state)
    }
}

// MARK: - Converters
extension SILRangeTestPeripheral {
    private func convertToData(_ boolValue: Bool) -> Data {
        let intValue: UInt8 = boolValue ? 1 : 0
        
        return convertToData(intValue)
    }
    
    private func convertToData<T>(_ value: T) -> Data {
        var valueCopy = value
        
        return Data(bytes: &valueCopy, count: MemoryLayout.size(ofValue: valueCopy))
    }
}

// MARK: - GenericAccessService
extension SILRangeTestPeripheral {
    func deviceName() -> String? {
        return self.peripheral.name
    }
}

// MARK: - DeviceInformationService
extension SILRangeTestPeripheral {
    private func registerForValues(ofCharacteristic characteristicEnum: SILDeviceInformationServiceCharacteristics, withCallback callback: @escaping  (SILRangeTestCharacteristic) -> Void) {
        let characteristic = CBUUID(string: SILRangeTestCharacteristic.deviceInformationServiceCharacteristics[characteristicEnum]!)
        let service = CBUUID(string: SILRangeTestCharacteristic.services[.deviceInformation]!)
        let rtCharacteristic = characteristics[service]![characteristic]!
    
        getValue(forCharacteristic: characteristic, inService: service, withDataCallback: callback)
        callback(rtCharacteristic)
    }
    
    func manufacturerName(callback: @escaping (String?) -> Void) {
        registerForValues(ofCharacteristic: .manufacturerName) { characteristic in
            callback(characteristic.value())
        }
    }
    
    func modelNumber(callback: @escaping (String?) -> Void) {
        registerForValues(ofCharacteristic: .modelNumber) { characteristic in
            callback(characteristic.value())
        }
    }
    
    func systemId(callback: @escaping (String?) -> Void) {
        registerForValues(ofCharacteristic: .systemId) { characteristic in
            callback(characteristic.value())
        }
    }
}

// MARK: - RangeTestService
extension SILRangeTestPeripheral {
    private func registerForValues(ofCharacteristic characteristicEnum: SILRangeTestServiceCharacteristics, withCallback callback: @escaping  (SILRangeTestCharacteristic) -> Void) {
        let characteristic = CBUUID(string: SILRangeTestCharacteristic.rangeTestServiceCharacteristics[characteristicEnum]!)
        let service = CBUUID(string: SILRangeTestCharacteristic.services[.rangeTest]!)
        let rtCharacteristic = characteristics[service]![characteristic]!
        
        getValue(forCharacteristic: characteristic, inService: service, withDataCallback: callback)
        callback(rtCharacteristic)
    }
    
    private func set(value: Data, forCharacteristic characteristicEnum: SILRangeTestServiceCharacteristics) {
        let characteristic = CBUUID(string: SILRangeTestCharacteristic.rangeTestServiceCharacteristics[characteristicEnum]!)
        let service = CBUUID(string: SILRangeTestCharacteristic.services[.rangeTest]!)
        
        setValue(withData: value, forCharacteristic: characteristic, inService: service)
    }
    
    func per(callback: @escaping (Double?) -> Void) {
        registerForValues(ofCharacteristic: .per) { characteristic in
            let value: UInt16? = characteristic.value()
            let doubleValue = (value != nil) ? Double(value!)/10 : nil
            
            callback(doubleValue)
        }
    }
    
    func ma(callback: @escaping (Double?) -> Void) {
        registerForValues(ofCharacteristic: .ma) { characteristic in
            let value: UInt16? = characteristic.value()
            let doubleValue = (value != nil) ? Double(value!)/10 : nil
            
            callback(doubleValue)
        }
    }
    
    func packetsSent(callback: @escaping (Int?) -> Void) {
        registerForValues(ofCharacteristic: .packetsSent) { characteristic in
            let value: UInt16? = characteristic.value()
            let intValue = (value != nil) ? Int(value!) : nil
            
            callback(intValue)
        }
    }
    
    func packetsCnt(callback: @escaping (Int?) -> Void) {
        registerForValues(ofCharacteristic: .packetsCount) { characteristic in
            let value: UInt16? = characteristic.value()
            let intValue = (value != nil) ? Int(value!) : nil
            
            callback(intValue)
        }
    }
    
    func packetsReceived(callback: @escaping (Int?) -> Void) {
        registerForValues(ofCharacteristic: .packetsReceived) { characteristic in
            let value: UInt16? = characteristic.value()
            let intValue = (value != nil) ? Int(value!) : nil
            
            callback(intValue)
        }
    }
    
    func packetCount(callback: @escaping (Double?, Double?, Double?) -> Void) {
        registerForValues(ofCharacteristic: .packetsRequired) { characteristic in
            let value: UInt16? = characteristic.value()
            let minValue: UInt16? = characteristic.minValue()
            let maxValue: UInt16? = characteristic.maxValue()
            let doubleValue = (value != nil) ? Double(value!) : nil
            let doubleMinValue = (minValue != nil) ? Double(minValue!) : nil
            let doubleMaxValue = (maxValue != nil) ? Double(maxValue!) : nil
            
            callback(doubleValue, doubleMinValue, doubleMaxValue)
        }
    }
    
    func setPacketCount(_ packetCount: Double) {
        let data = convertToData(UInt16(packetCount))
        
        set(value: data, forCharacteristic: .packetsRequired)
    }
    
    func channel(callback: @escaping (Double?, Double?, Double?) -> Void) {
        registerForValues(ofCharacteristic: .channel) { characteristic in
            let value: UInt16? = characteristic.value()
            let minValue: UInt16? = characteristic.minValue()
            let maxValue: UInt16? = characteristic.maxValue()
            let doubleValue = (value != nil) ? Double(value!) : nil
            let doubleMinValue = (minValue != nil) ? Double(minValue!) : nil
            let doubleMaxValue = (maxValue != nil) ? Double(maxValue!) : nil
            
            callback(doubleValue, doubleMinValue, doubleMaxValue)
        }
    }
    
    func setChannel(_ channel: Double) {
        let data = convertToData(UInt16(channel))
        
        set(value: data, forCharacteristic: .channel)
    }
    
    func radioMode(callback: @escaping (Int?) -> Void) {
        registerForValues(ofCharacteristic: .radioMode) { characteristic in
            let value: UInt8? = characteristic.value()
            
            callback((value != nil) ? Int(value!) : nil)
        }
    }
    
    func setRadioMode(_ radioMode: Int) {
        let data = convertToData(UInt8(radioMode))
        
        set(value: data, forCharacteristic: .radioMode)
    }
    
    func frequency(callback: @escaping (Int?, Int?, Int?) -> Void) {
        registerForValues(ofCharacteristic: .frequency) { characteristic in
            let value: UInt16? = characteristic.value()
            let minValue: UInt16? = characteristic.minValue()
            let maxValue: UInt16? = characteristic.maxValue()
            let intValue = (value != nil) ? Int(value!) : nil
            let intMinValue = (minValue != nil) ? Int(minValue!) : nil
            let intMaxValue = (maxValue != nil) ? Int(maxValue!) : nil
            
            callback(intValue, intMinValue, intMaxValue)
        }
    }
    
    func phyConfigList(callback: @escaping ([Int : String]?) -> Void) {
        registerForValues(ofCharacteristic: .phyConfigList) { characteristic in
            let value: String? = characteristic.value()
            let csvComponents: [String]? = value?
                .components(separatedBy: ",")
                .filter { $0.count != 0 }
            let phyValues: [[Substring]]? = csvComponents?
                .map { $0.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true) }
            let phyConfigs: [Int : String]? = phyValues?
                .reduce(into: [Int : String]()) { $0[Int($1.first!)!] = String($1.last!) }

            callback(phyConfigs)
        }
    }
    
    func phyConfig(callback: @escaping (Double?) -> Void) {
        registerForValues(ofCharacteristic: .phyConfig) { [weak self] characteristic in
            let value: Int16? = characteristic.value()
            let doubleValue = (value != nil) ? Double(value!) : nil
            
            callback(doubleValue)
            
            self?.rereadDescriptorsValues(ofCharacteristic: .payload)
        }
    }
    
    func setPhyConfig(_ phyConfig: Double) {
        let data = convertToData(Int16(phyConfig))
        
        set(value: data, forCharacteristic: .phyConfig)
    }
    
    func txPower(callback: @escaping (Double?, Double?, Double?) -> Void) {
        registerForValues(ofCharacteristic: .txPower) { characteristic in
            let value: Int16? = characteristic.value()
            let minValue: Int16? = characteristic.minValue()
            let maxValue: Int16? = characteristic.maxValue()
            let doubleValue = (value != nil) ? Double(value!)/10 : nil
            let doubleMinValue = (minValue != nil) ? Double(minValue!)/10 : nil
            let doubleMaxValue = (maxValue != nil) ? Double(maxValue!)/10 : nil
            
            callback(doubleValue, doubleMinValue, doubleMaxValue)
        }
    }
    
    func setTxPower(_ txPower: Double) {
        let data = convertToData(Int16(txPower * 10))
        
        set(value: data, forCharacteristic: .txPower)
    }
    
    func remoteId(callback: @escaping (Double?, Double?, Double?) -> Void) {
        registerForValues(ofCharacteristic: .destinationId) { characteristic in
            let value: UInt8? = characteristic.value()
            let minValue: UInt8? = characteristic.minValue()
            let maxValue: UInt8? = characteristic.maxValue()
            let doubleValue = (value != nil) ? Double(value!) : nil
            let doubleMinValue = (minValue != nil) ? Double(minValue!) : nil
            let doubleMaxValue = (maxValue != nil) ? Double(maxValue!) : nil
            
            callback(doubleValue, doubleMinValue, doubleMaxValue)
        }
    }
    
    func setRemoteId(_ remoteId: Double) {
        let data = convertToData(UInt8(remoteId))
        
        set(value: data, forCharacteristic: .destinationId)
    }
    
    func selfId(callback: @escaping (Double?, Double?, Double?) -> Void) {
        registerForValues(ofCharacteristic: .sourceId) { characteristic in
            let value: UInt8? = characteristic.value()
            let minValue: UInt8? = characteristic.minValue()
            let maxValue: UInt8? = characteristic.maxValue()
            let doubleValue = (value != nil) ? Double(value!) : nil
            let doubleMinValue = (minValue != nil) ? Double(minValue!) : nil
            let doubleMaxValue = (maxValue != nil) ? Double(maxValue!) : nil
            
            callback(doubleValue, doubleMinValue, doubleMaxValue)
        }
    }
    
    func setSelfId(_ selfId: Double) {
        let data = convertToData(UInt8(selfId))
        
        set(value: data, forCharacteristic: .sourceId)
    }
    
    func payloadLength(callback: @escaping (Double?, Double?, Double?) -> Void) {
        registerForValues(ofCharacteristic: .payload) { characteristic in
            let value: UInt8? = characteristic.value()
            let minValue: UInt8? = characteristic.minValue()
            let maxValue: UInt8? = characteristic.maxValue()
            let doubleValue = (value != nil) ? Double(value!) : nil
            let doubleMinValue = (minValue != nil) ? Double(minValue!) : nil
            let doubleMaxValue = (maxValue != nil) ? Double(maxValue!) : nil
            
            callback(doubleValue, doubleMinValue, doubleMaxValue)
        }
    }
    
    func setPayloadLength(_ payloadLength: Double) {
        let data = convertToData(UInt8(payloadLength))
        
        set(value: data, forCharacteristic: .payload)
    }
    
    func maWindowSize(callback: @escaping (Double?, Double?, Double?) -> Void) {
        registerForValues(ofCharacteristic: .maSize) { characteristic in
            let value: UInt8? = characteristic.value()
            let minValue: UInt8? = characteristic.minValue()
            let maxValue: UInt8? = characteristic.maxValue()
            let doubleValue = (value != nil) ? Double(value!) : nil
            let doubleMinValue = (minValue != nil) ? Double(minValue!) : nil
            let doubleMaxValue = (maxValue != nil) ? Double(maxValue!) : nil
            
            callback(doubleValue, doubleMinValue, doubleMaxValue)
        }
    }
    
    func setMaWindowSize(_ maWindowSize: Double) {
        let data = convertToData(UInt8(maWindowSize))
        
        set(value: data, forCharacteristic: .maSize)
    }
    
    func isUartLogEnabled(callback: @escaping (Bool?) -> Void) {
        registerForValues(ofCharacteristic: .log) { characteristic in
            let value: UInt8? = characteristic.value()
            
            callback((value == nil) ? nil : (value! > 0 ? true : false))
        }
    }
    
    func setUartLogEnabled(_ isUartLogEnabled: Bool) {
        let data = convertToData(isUartLogEnabled)
        
        set(value: data, forCharacteristic: .log)
    }
    
    func isRunning(callback: @escaping (Bool?) -> Void) {
        registerForValues(ofCharacteristic: .isRunning) { characteristic in
            let value: UInt8? = characteristic.value()
            
            callback((value == nil) ? nil : (value! > 0 ? true : false))
        }
    }
    
    func setIsRunning(_ isRunning: Bool) {
        let data = convertToData(isRunning)
        
        set(value: data, forCharacteristic: .isRunning)
    }
    
    private func rereadDescriptorsValues(ofCharacteristic characteristicEnum: SILRangeTestServiceCharacteristics) {
        let characteristicUUID = CBUUID(string: SILRangeTestCharacteristic.rangeTestServiceCharacteristics[characteristicEnum]!)
        let serviceUUID = CBUUID(string: SILRangeTestCharacteristic.services[.rangeTest]!)
        
        if let rawCharacteristic = self.alreadyDiscoveredCharacteristics[serviceUUID]?[characteristicUUID],
            let descriptors = rawCharacteristic.descriptors {
            for descriptor in descriptors {
                self.peripheral.readValue(for: descriptor)
            }
        }
    }
}

// MARK: - CBPeripheralDelegate
extension SILRangeTestPeripheral: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let err = error {
            print("didDiscoverServices: \(peripheral) - \(err)")
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        
        
        for service in services {
            if let characteristicsKeys = valuesCallbacks[service.uuid]?.keys {
                peripheral.discoverCharacteristics(Array(characteristicsKeys), for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let err = error {
            print("didDiscoverCharacteristicsFor: \(service) - \(err)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        let serviceUUID = service.uuid
        
        for characteristic in characteristics {
            let characteristicUUID = characteristic.uuid
            let isCharacteristicAlreadyDiscovered = alreadyDiscoveredCharacteristics[serviceUUID]?[characteristicUUID] != nil
            let isValueCallbackExist = valuesCallbacks[serviceUUID]?[characteristicUUID] != nil
            
            if !isCharacteristicAlreadyDiscovered && isValueCallbackExist {
                if alreadyDiscoveredCharacteristics[serviceUUID] == nil {
                    alreadyDiscoveredCharacteristics[serviceUUID] = [:]
                }
                
                alreadyDiscoveredCharacteristics[serviceUUID]?[characteristicUUID] = characteristic
                
                peripheral.readValue(for: characteristic)
                peripheral.discoverDescriptors(for: characteristic)
                
                if let rtCharacteristic = self.characteristics[serviceUUID]?[characteristicUUID],
                    rtCharacteristic.supportsNotifications {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            print("didWriteValueFor: \(characteristic) - \(err)")
            return
        }
        
        peripheral.readValue(for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            print("didUpdateValueFor: \(characteristic) - \(err)")
            return
        }
        
        let serviceUUID = characteristic.service.uuid
        let characteristicUUID = characteristic.uuid
        
        guard let rtCharacteristic = characteristics[serviceUUID]?[characteristicUUID] else {
            return
        }
        
        let containsNewValues = rtCharacteristic.update(withCharacteristic: characteristic)
        
        guard containsNewValues, let dataCallback = self.valuesCallbacks[serviceUUID]?[characteristicUUID] else {
            return
        }
        
        dataCallback(rtCharacteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            print("didDiscoverDescriptorsFor: \(characteristic) - \(err)")
            return
        }
        
        guard let descriptors = characteristic.descriptors else {
            return
        }
        
        for descriptor in descriptors {
            peripheral.readValue(for: descriptor)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        if let err = error {
            print("didUpdateValueFor: \(descriptor) - \(err)")
            return
        }
        
        let serviceUUID = descriptor.characteristic.service.uuid
        let characteristicUUID = descriptor.characteristic.uuid
        
        guard let rtCharacteristic = characteristics[serviceUUID]?[characteristicUUID] else {
            return
        }
        
        let containsNewValues = rtCharacteristic.update(withDescriptor: descriptor)
        
        guard containsNewValues, let dataCallback = self.valuesCallbacks[serviceUUID]?[characteristicUUID] else {
            return
        }
        
        dataCallback(rtCharacteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            print("didUpdateNotificationStateFor: \(characteristic) - \(err)")
            return
        }
        
        let serviceUUID = characteristic.service.uuid
        let characteristicUUID = characteristic.uuid
        
        guard let rtCharacteristic = characteristics[serviceUUID]?[characteristicUUID] else {
            return
        }
        
        let containsNewValues = rtCharacteristic.update(withCharacteristic: characteristic)
        
        guard containsNewValues, let dataCallback = self.valuesCallbacks[serviceUUID]?[characteristicUUID] else {
            return
        }
        
        dataCallback(rtCharacteristic)
    }
}

//MARK: - Advartisement data handling
extension SILRangeTestPeripheral: SILDiscoveredPeripheralDelegate {
    func startGetheringAdvertisementData() {
        self.manufacturerData = nil
        manager.addScan(forPeripheralsObserver: self, selector: #selector(handleCentralManagerDidUpdateDiscoveredPeripheralsNotification(_:)))
    }
    
    func stopGetheringAdvertisementData() {
        manager.removeScan(forPeripheralsObserver: self)
        self.manufacturerData = nil
        
        discoveredPeripheral()?.delegate = nil
    }
    
    func handleCentralManagerDidUpdateDiscoveredPeripheralsNotification(_ notification: NSNotification) {
        if let peripheral = discoveredPeripheral(), peripheral.delegate == nil {
            peripheral.delegate = self
        }
    }
    
    func peripheral(_ peripheral: SILDiscoveredPeripheral!, didUpdateWithAdvertisementData dictionary: [AnyHashable : Any]!, andRSSI rssi: NSNumber!) {
        var manufacturerData: SILRangeTestManufacturerData? = nil
        
        if let data = peripheral.manufacturerData {
            manufacturerData = SILRangeTestManufacturerData(manufacturerData: data)
            self.manufacturerData = manufacturerData
        }
        
        delegate?.didUpdate(manufacturerData: manufacturerData)
    }
}
