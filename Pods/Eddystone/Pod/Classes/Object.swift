open class Object: Equatable {
    
    //MARK: Properties
    /// The signal strength of the nearby entity
    fileprivate(set) open var signalStrength: Beacon.SignalStrength
    /// A unique identifier for the beacon
    fileprivate(set) open var identifier: String
    /// The percent battery left on the beacon
    fileprivate(set) open var battery: Double?
    /// The temperature of the beacon in degrees Celsius
    fileprivate(set) open var temperature: Double?
    /// The amount of packets the beacon has sent
    fileprivate(set) open var advertisementCount: Int?
    /// The amount of time the beacon has been on in seconds
    fileprivate(set) open var onTime: TimeInterval?
    
    //MARK: Initilizations
    init (signalStrength: Beacon.SignalStrength, identifier: String) {
        self.signalStrength = signalStrength
        self.identifier = identifier
    }
    
    func parseTlmFrame(_ frame: TlmFrame) {
        self.battery = Object.batteryLevelInPercent(frame.batteryVolts)
        self.temperature = frame.temperature
        self.advertisementCount = frame.advertisementCount
        self.onTime = TimeInterval(frame.onTime / 10)
    }
    
    //MARK: Class
    class func batteryLevelInPercent(_ mvolts: Int) -> Double
    {
        var batteryLevel: Double
        let mvoltsDouble = Double(mvolts)
        
        if (mvolts >= 3000) {
            batteryLevel = 100
        } else if (mvolts > 2900) {
            batteryLevel = 100 - ((3000 - mvoltsDouble) * 58) / 100
        } else if (mvolts > 2740) {
            batteryLevel = 42 - ((2900 - mvoltsDouble) * 24) / 160
        } else if (mvolts > 2440) {
            batteryLevel = 18 - ((2740 - mvoltsDouble) * 12) / 300
        } else if (mvolts > 2100) {
            batteryLevel = 6 - ((2440 - mvoltsDouble) * 6) / 340
        } else {
            batteryLevel = 0
        }
        
        return batteryLevel
    }
    
}

public func ==(lhs: Object, rhs: Object) -> Bool {
    return lhs.identifier == rhs.identifier
}
