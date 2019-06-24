open class Generic: Object {
   
    //MARK: Properties
    fileprivate(set) open var url: URL?
    fileprivate(set) open var namespace: String?
    fileprivate(set) open var instance: String?
    fileprivate(set) open var rssi: Double
    fileprivate(set) open var txPower: Int
    open var uid: String? {
        get {
            if  let namespace = self.namespace,
                let instance = self.instance {
                    return namespace + instance
            }
            return nil
        }
    }
    
    //MARK: Initializations
    init(url: URL?, namespace: String?, instance: String?, signalStrength: Beacon.SignalStrength, identifier: String, rssi: Double, txPower: Int) {
        self.url = url
        self.namespace = namespace
        self.instance = instance
        self.rssi = rssi
        self.txPower = txPower

        var urlString = ""
        if let absoluteString = url?.absoluteString {
            urlString = absoluteString
        }
        
        var uid = ""
        if  let namespace = self.namespace,
            let instance = self.instance {
                uid = namespace + instance
        }
        
        super.init(signalStrength: signalStrength, identifier: urlString + uid + identifier)
    }
    
}
