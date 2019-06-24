open class Url: Object {
    
    //MARK: Properties
    fileprivate(set) open var url: URL
    
    //MARK: Initializations
    init(url: URL, signalStrength: Beacon.SignalStrength, identifier: String) {
        self.url = url

        super.init(signalStrength: signalStrength, identifier: url.absoluteString + identifier)
    }
    
}
