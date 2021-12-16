//
//  Logging.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

typealias log = Logging
class Logging {
    
    enum Level: String {
        case Error = "error"
        case Info  = "info"
        case Debug = "debug"
    }
    
    #if DEBUG
    static var levels: [Level] = [.Error, .Info, .Debug]
    #else
    static var levels: [Level] = [.Error, .Info]
    #endif
    
    class func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        if levels.contains(.Error) {
            writeMessage(message, level: .Error, file: file, function: function, line: line)
        }
    }
    
    class func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        if levels.contains(.Info) {
            writeMessage(message, level: .Info, file: file, function: function, line: line)
        }
    }
    
    class func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        if levels.contains(.Debug) {
            writeMessage(message, level: .Debug, file: file, function: function, line: line)
        }
    }
    
    fileprivate class func writeMessage(_ message: String, level: Level, file: String, function: String, line: Int) {
        let filename = NSString(string: file).pathComponents.last! as String
        NSLog("[\(level)] \(filename):\(line) \(function) \(message)")
    }
}
