open class Uid: Object {
    
    //MARK: Properties
    fileprivate(set) open var namespace: String
    fileprivate(set) open var instance: String
    open var uid: String {
        get {
            return self.namespace + self.instance
        }
    }
    
    //MARK: Initializations
    init(namespace: String, instance: String, signalStrength: Beacon.SignalStrength, identifier: String) {
        self.namespace = namespace
        self.instance = instance
        
        super.init(signalStrength: signalStrength, identifier: namespace + instance + identifier)
    }
    
}
