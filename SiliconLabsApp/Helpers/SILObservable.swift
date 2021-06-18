//
//  SILObservable.swift
//  BlueGecko
//
//  Created by Michał Lenart on 24/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILObservableToken {
    private var unsubscribe: (() -> Void)?
    
    init(unsubscribe: @escaping () -> Void) {
        self.unsubscribe = unsubscribe
    }
    
    deinit {
        invalidate()
    }
    
    func invalidate() {
        unsubscribe?()
        unsubscribe = nil
    }
}

class SILObservable<T> {
    var value: T {
        didSet {
            for callback in callbacks.values {
                callback(value)
            }
        }
    }
    
    private var callbacks: [String: (T) -> Void]
    
    init(initialValue: T) {
        value = initialValue
        callbacks = [:]
    }
    
    func observe(_ callback: @escaping (T) -> Void) -> SILObservableToken {
        return observe(sendInitial: true, callback)
    }
    
    func observe(sendInitial: Bool, _ callback: @escaping (T) -> Void) -> SILObservableToken {
        let id = UUID().uuidString
        callbacks[id] = callback
        
        if (sendInitial) {
            callback(value)
        }
        
        weak var weakSelf = self
        
        return SILObservableToken {
            weakSelf?.callbacks.removeValue(forKey: id)
        }
    }
}

class SILObservableTokenBag {
    private var tokens: [SILObservableToken] = []
    
    func add(token: SILObservableToken) {
        tokens.append(token)
    }
    
    func invalidateTokens() {
        for token in tokens {
            token.invalidate()
        }
    }
}

extension SILObservableToken {
    func putIn(bag: SILObservableTokenBag) {
        bag.add(token: self)
    }
}
