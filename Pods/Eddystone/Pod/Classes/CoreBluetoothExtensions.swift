/**
    CoreBluetoothExtensions.swift

    Easily identify which state a CBCentralManager or CBPeripheralManager is in

    <https://gist.github.com/f6ba585244afa80b06d2.git>
*/

import CoreBluetooth

extension CBCentralManager {
    var stateString: String {
        get {
            switch (self.state) {
            case .poweredOn:
                return "Powered On"
            case .poweredOff:
                return "Powered Off"
            case .resetting:
                return "Resetting"
            case .unauthorized:
                return "Unauthorized"
            case .unknown:
                return "Unknown"
            case .unsupported:
                return "Unsupported"
            }
            
        }
    }
}

extension CBPeripheralManager {
    var stateString: String {
        get {
            switch (self.state) {
            case .poweredOn:
                return "Powered On"
            case .poweredOff:
                return "Powered Off"
            case .resetting:
                return "Resetting"
            case .unauthorized:
                return "Unauthorized"
            case .unknown:
                return "Unknown"
            case .unsupported:
                return "Unsupported"
            }
            
        }
    }
}
