import Foundation

public var logging = false

func log(_ message: AnyObject) {
    if logging {
        print("[Eddystone] \(message)")
    }
}

func log(_ message: String) {
    if logging {
        print("[Eddystone] \(message)")
    }
}

enum FrameType {
    case url, uid, tlm
}

typealias Byte = Int
