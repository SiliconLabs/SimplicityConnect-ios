//
//  SILCentralManager.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/4/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class SILDiscoveredPeripheral;
@class CBUUID;

extern NSString * _Nonnull const SILCentralManagerDidConnectPeripheralNotification;
extern NSString * _Nonnull const SILCentralManagerDidDisconnectPeripheralNotification;
extern NSString * _Nonnull const SILCentralManagerDidFailToConnectPeripheralNotification;

extern NSString * _Nonnull const SILCentralManagerDiscoveredPeripheralsKey;
extern NSString * _Nonnull const SILCentralManagerPeripheralKey;
extern NSString * _Nonnull const SILCentralManagerErrorKey;

@interface SILCentralManager : NSObject <CBCentralManagerDelegate, CLLocationManagerDelegate>

@property (nonnull, strong, nonatomic, readonly) NSArray *serviceUUIDs;
@property (nonnull, strong, nonatomic) CBCentralManager *centralManager;
@property (nullable, strong, nonatomic) CBPeripheral *connectedPeripheral;

- (nonnull instancetype)initWithServiceUUID:(nonnull CBUUID *)serviceUUID;
- (nonnull instancetype)initWithServiceUUIDs:(nonnull NSArray *)serviceUUIDs;

- (nonnull NSArray<SILDiscoveredPeripheral *> *)discoveredPeripherals;
- (nullable SILDiscoveredPeripheral *)discoveredPeripheralForPeripheral:(nonnull CBPeripheral *)peripheral;

- (void)insertOrUpdateDiscoveredPeripheral:(nonnull CBPeripheral *)peripheral advertisementData:(nullable NSDictionary *)advertisementData RSSI:(nullable NSNumber *)RSSI andDiscoveringTimestamp:(double)timestamp;

- (BOOL)canConnectToDiscoveredPeripheral:(nonnull SILDiscoveredPeripheral *)discoveredPeripheral;
- (void)connectToDiscoveredPeripheral:(nonnull SILDiscoveredPeripheral *)discoveredPeripheral;
- (void)disconnectConnectedPeripheral;
- (void)removeAllDiscoveredPeripherals;

- (void)addScanForPeripheralsObserver:(nonnull id)observer selector:(nonnull SEL)aSelector;
- (void)removeScanForPeripheralsObserver:(nonnull id)observer;

- (void)disconnectFromPeripheral:(CBPeripheral *)peripheral;

@end
