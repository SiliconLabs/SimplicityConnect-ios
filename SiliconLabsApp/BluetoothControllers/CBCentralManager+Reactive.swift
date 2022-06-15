//
//  CBCentralManager+Reactive.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 03/03/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import RxSwift
import RxCocoa
import CoreBluetooth

typealias DiscoverData = (peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber)

extension CBCentralManager: HasDelegate {
    public typealias Delegate = CBCentralManagerDelegate
}

class CBCentralManagerDelegateProxy: DelegateProxy<CBCentralManager, CBCentralManagerDelegate>, DelegateProxyType, CBCentralManagerDelegate {

    init(parentObject: CBCentralManager) {
        super.init(parentObject: parentObject, delegateProxy: CBCentralManagerDelegateProxy.self)
    }

    deinit {
        _didUpdateState.onCompleted()
    }

    static func registerKnownImplementations() {
        register { CBCentralManagerDelegateProxy(parentObject: $0) }
    }

    static func currentDelegate(for object: CBCentralManager) -> CBCentralManagerDelegate? {
        return object.delegate
    }

    static func setCurrentDelegate(_ delegate: CBCentralManagerDelegate?, to object: CBCentralManager) {
        object.delegate = delegate
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        _didUpdateState.onNext(central.state)
    }

    fileprivate let _didUpdateState = BehaviorSubject<CBManagerState>(value: .unknown)
}

extension Reactive where Base: CBCentralManager {
    
    var delegate: CBCentralManagerDelegateProxy {
        return CBCentralManagerDelegateProxy.proxy(for: base)
    }

    var state: BehaviorSubject<CBManagerState> {
        return delegate._didUpdateState
    }

    var didUpdateState: Observable<Void> {
        return delegate._didUpdateState.map { _ in }
    }
    
    var didDiscover: Observable<DiscoverData> {
        return delegate.methodInvoked(#selector(CBCentralManagerDelegate.centralManager(_:didDiscover:advertisementData:rssi:)))
            .map { ($0[1] as! CBPeripheral, $0[2] as! [String: Any], $0[3] as! NSNumber)}
            .share()
    }
    
    var didConnect: Observable<CBPeripheral> {
        return delegate.methodInvoked(#selector(CBCentralManagerDelegate.centralManager(_:didConnect:)))
            .map { $0[1] as! CBPeripheral }
            .share()
    }
    
    var didFailToConnect: Observable<(peripheral: CBPeripheral, error: Error?)> {
        return delegate.methodInvoked(#selector(CBCentralManagerDelegate.centralManager(_:didFailToConnect:error:)))
            .map { ($0[1] as! CBPeripheral, $0[2] as? Error )}
            .share()
    }
    
    var didDisconnect: Observable<(peripheral: CBPeripheral, error: Error?)> {
        return delegate.methodInvoked(#selector(CBCentralManagerDelegate.centralManager(_:didDisconnectPeripheral:error:)))
            .map { ($0[1] as! CBPeripheral, $0[2] as? Error )}
            .share()
    }
}
