//
//  DispatchBlockHelpers.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

typealias DispatchBlock = ( () -> Void )
func delay(_ after: TimeInterval, run: @escaping DispatchBlock) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(after * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
        run()
    }
}

func dispatch_main_async(_ block: @escaping DispatchBlock) {
    OperationQueue.main.addOperation { () -> Void in
        block()
    }
}

func dispatch_main_sync(_ block: DispatchBlock) {
    DispatchQueue.main.sync { () -> Void in
        block()
    }
}
