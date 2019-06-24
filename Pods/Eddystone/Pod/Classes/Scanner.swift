import CoreBluetooth

open class Scanner: NSObject {
    
    //MARK: Public
    open class func start(_ delegate: ScannerDelegate) {
        
        self.shared.centralManager = CBCentralManager(delegate: self.shared, queue: nil)
        self.shared.delegate = delegate
        
    }

    open class func stopScan() {
        self.shared.centralManager.stopScan()
        self.shared.delegate = nil
    }
    
    //Returns an array of Url objects that are nearby
    open class var nearbyUrls: [Url] {
        get {
            var urls = [Url]()
            
            for beacon in self.beacons {
                if let urlFrame = beacon.frames.url {
                    let url = Url(url: urlFrame.url, signalStrength: beacon.signalStrength, identifier: beacon.identifier)
                    if let tlmFrame = beacon.frames.tlm {
                        url.parseTlmFrame(tlmFrame)
                    }
                    urls.append(url)
                }
            }
            
            return urls
        }
    }
    
    //Returns an array of Uid objects that are nearby
    open class var nearbyUids: [Uid] {
        get {
            var uids = [Uid]()
            
            for beacon in self.beacons {
                if let uidFrame = beacon.frames.uid {
                    let uid = Uid(namespace: uidFrame.namespace, instance: uidFrame.instance, signalStrength: beacon.signalStrength, identifier: beacon.identifier)
                    if let tlmFrame = beacon.frames.tlm {
                        uid.parseTlmFrame(tlmFrame)
                    }
                    uids.append(uid)
                }
            }
            
            return uids
        }
    }
    
    //Returns an array of all nearby Eddystone objects
    open class var nearby: [Generic] {
        get {
            var generics = [Generic]()
            
            for beacon in self.beacons {
                var url: URL?
                var namespace: String?
                var instance: String?
                
                if let uidFrame = beacon.frames.uid {
                    namespace = uidFrame.namespace
                    instance = uidFrame.instance
                }
                
                if let urlFrame = beacon.frames.url {
                    url = urlFrame.url as URL
                }
                
                let generic = Generic(url: url, namespace: namespace, instance: instance, signalStrength: beacon.signalStrength, identifier: beacon.identifier, rssi: beacon.rssiBuffer.first ?? 0, txPower: beacon.txPower)
                if let tlmFrame = beacon.frames.tlm {
                    generic.parseTlmFrame(tlmFrame)
                }
                generics.append(generic)
            }
            
            return generics

        }
    }
    
    //MARK: Singleton
    static let shared = Scanner()
    
    //MARK: Constants
    static let eddystoneServiceUUID = CBUUID(string: "FEAA")
    
    //MARK: Properties
    var centralManager = CBCentralManager()
    var discoveredBeacons = [String: Beacon]()
    var beaconTimers = [String: Timer]()
    
    //MARK: Delegate
    var delegate: ScannerDelegate?
    func notifyChange() {
        self.delegate?.eddystoneNearbyDidChange()
    }
    
    //MARK: Internal Class
    class var beacons: [Beacon] {
        get {
            var orderedBeacons = [Beacon]()
            
            for beacon in self.shared.discoveredBeacons.values {
                orderedBeacons.append(beacon)
            }
            
            orderedBeacons.sort { beacon1, beacon2 in
                return beacon1.distance < beacon2.distance
            }
            
            return orderedBeacons
        }
    }
    
}

extension Scanner: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: [Scanner.eddystoneServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        } else {
            log("Bluetooth not powered on. Current state: \(central.state)")
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let identifier = peripheral.identifier.uuidString

        if let beacon = self.discoveredBeacons[identifier] {
            beacon.parseAdvertisementData(advertisementData, rssi: RSSI.doubleValue)
        } else {
            if let beacon = Beacon.beaconWithAdvertisementData(advertisementData, rssi: RSSI.doubleValue, identifier: identifier) {
                beacon.delegate = self
                self.discoveredBeacons[peripheral.identifier.uuidString] = beacon
            }
        }
        
        self.notifyChange()
        self.beaconTimers[identifier]?.invalidate()
        self.beaconTimers[identifier] = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(Scanner.beaconTimerExpire(_:)), userInfo: identifier, repeats: false)
    }
    
    @objc func beaconTimerExpire(_ timer: Timer) {
        if let identifier = timer.userInfo as? String {
            log("Beacon lost")
            
            self.discoveredBeacons.removeValue(forKey: identifier)
            self.notifyChange()
        }
    }
}

extension Scanner: BeaconDelegate {
    
    func beaconDidChange() {
        self.notifyChange()
    }
    
}

//MARK: Protocol
public protocol ScannerDelegate {
    
    func eddystoneNearbyDidChange()
    
}
