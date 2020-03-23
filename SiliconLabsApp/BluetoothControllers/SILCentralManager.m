//
//  SILCentralManager.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/4/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "SILCentralManager.h"
#import "SILBrowserConnectionsViewModel.h"
#import "SILDiscoveredPeripheral.h"
#import "NSError+SILHelpers.h"
#import "SILWeakTargetWrapper.h"
#import "SILRSSIMeasurementTable.h"
#import "SILLogDataModel.h"
#import "SILWeakNotificationPair.h"
#import "SILConstants.h"
#import "NSString+SILBrowserNotifications.h"
#if ENABLE_HOMEKIT
#import <HomeKit/HomeKit.h>
#endif

NSString * const SILCentralManagerDidConnectPeripheralNotification = @"SILCentralManagerDidConnectPeripheralNotification";
NSString * const SILCentralManagerDidDisconnectPeripheralNotification = @"SILCentralManagerDidDisconnectPeripheralNotification";
NSString * const SILCentralManagerDidFailToConnectPeripheralNotification = @"SILCentralManagerDidFailToConnectPeripheralNotification";

NSString * const SILCentralManagerDiscoveredPeripheralsKey = @"SILCentralManagerDiscoveredPeripheralsKey";
NSString * const SILCentralManagerPeripheralKey = @"SILCentralManagerPeripheralKey";
NSString * const SILCentralManagerErrorKey = @"SILCentralManagerErrorKey";

NSTimeInterval const SILCentralManagerDiscoveryTimeoutThreshold = 5.0;
NSTimeInterval const SILCentralManagerConnectionTimeoutThreshold = 20.0;

@interface SILCentralManager ()

@property (strong, nonatomic) NSArray *serviceUUIDs;

@property (assign, nonatomic) BOOL isScanning;
@property (strong, nonatomic) NSMutableDictionary *discoveredPeripheralMapping;
@property (strong, nonatomic) NSTimer *discoveryTimeoutTimer;

@property (strong, nonatomic) NSTimer *connectionTimeoutTimer;
@property (strong, nonatomic) CBPeripheral *connectingPeripheral;
@property (strong, nonatomic) CBPeripheral *disconnectingPeripheral;
@property (strong, nonatomic) SILBrowserConnectionsViewModel* connectionsViewModel;
@property (strong, nonatomic) NSMutableArray *scanForPeripheralsObservers;

@end

@implementation SILCentralManager

- (instancetype)initWithServiceUUID:(CBUUID *)serviceUUID {
    NSAssert(serviceUUID != nil, @"initWithServiceUUID with a nil serviceUUID");
    return [self initWithServiceUUIDs:@[serviceUUID]];
}

- (instancetype)initWithServiceUUIDs:(NSArray *)serviceUUIDs {
    self = [super init];
    if (self) {
        self.serviceUUIDs = [serviceUUIDs copy];
        self.discoveredPeripheralMapping = [NSMutableDictionary dictionary];
        self.scanForPeripheralsObservers = [NSMutableArray array];
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
        [self setupNotifications];
        self.connectionsViewModel = [SILBrowserConnectionsViewModel sharedInstance];
    }
    return self;
}

- (void)dealloc {
    [self.discoveryTimeoutTimer invalidate];
    [self.connectionTimeoutTimer invalidate];
    [self.centralManager stopScan];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

- (NSArray *)discoveredPeripherals {
    return [self.discoveredPeripheralMapping allValues];
}

- (SILDiscoveredPeripheral *)discoveredPeripheralForPeripheral:(CBPeripheral *)peripheral {
    return self.discoveredPeripheralMapping[peripheral.identifier];
}

#pragma MARK: - Notifications

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminateNotification:) name:UIApplicationWillTerminateNotification object:nil];
}

- (void)applicationWillTerminateNotification:(NSNotification *)notification {
    if (self.connectedPeripheral) {
        NSLog(@"Disconnected from connected peripheral");
        [self disconnectFromPeripheral:self.connectedPeripheral];
    } else if (self.connectingPeripheral) {
        NSLog(@"Disconnect from connecting peripheral");
        [self disconnectFromPeripheral:self.connectingPeripheral];
    }
}

#pragma mark - Discovering Peripherals

- (void)insertOrUpdateDiscoveredPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI andDiscoveringTimestamp:(long long)timestamp {
    SILDiscoveredPeripheral *discoveredPeripheral = self.discoveredPeripheralMapping[peripheral.identifier];
    if (discoveredPeripheral) {
        [discoveredPeripheral updateWithAdvertisementData:advertisementData RSSI:RSSI andDiscoveringTimestamp:timestamp];
    } else {
        discoveredPeripheral = [[SILDiscoveredPeripheral alloc] initWithPeripheral:peripheral
                                                                 advertisementData:advertisementData
                                                                                  RSSI:RSSI
                                                           andDiscoveringTimestamp:timestamp];
        self.discoveredPeripheralMapping[peripheral.identifier] = discoveredPeripheral;
    }
    [self postDidUpdateDiscoveredPeripheralsNotification];
}

- (void)removeDiscoveredPeripheral:(SILDiscoveredPeripheral *)discoveredPeripheral {
    [self.discoveredPeripheralMapping removeObjectForKey:discoveredPeripheral.peripheral.identifier];
    [self postDidUpdateDiscoveredPeripheralsNotification];
}

- (void)removeAllDiscoveredPeripherals {
    [self.discoveredPeripheralMapping removeAllObjects];
    [self postDidUpdateDiscoveredPeripheralsNotification];
}

- (void)startDiscoveryTimeoutTimer {
    [self.discoveryTimeoutTimer invalidate];
    self.discoveryTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:SILCentralManagerDiscoveryTimeoutThreshold
                                                                  target:[[SILWeakTargetWrapper alloc] initWithTarget:self selector:@selector(didFireDiscoveryTimeoutTimer:)]
                                                                selector:@selector(triggerSelector:)
                                                                userInfo:nil
                                                                 repeats:YES];
}

- (void)stopDiscoveryTimeoutTimer {
    [self.discoveryTimeoutTimer invalidate];
    self.discoveryTimeoutTimer = nil;
}

- (void)didFireDiscoveryTimeoutTimer:(NSTimer *)timer {
    [self filterDiscoveredPeripheralByTimeout];
}

- (void)filterDiscoveredPeripheralByTimeout {
    BOOL didRemovePeripherals = NO;
    for (SILDiscoveredPeripheral *discoveredPeripheral in [self discoveredPeripherals]) {
        if (![discoveredPeripheral.RSSIMeasurementTable hasRSSIMeasurementInPastTimeInterval:SILCentralManagerDiscoveryTimeoutThreshold]) {
            didRemovePeripherals = YES;
            [self.discoveredPeripheralMapping removeObjectForKey:discoveredPeripheral.peripheral.identifier];
        }
    }
    if (didRemovePeripherals) {
        [self postDidUpdateDiscoveredPeripheralsNotification];
    }
}

#pragma mark - Connecting Peripherals

- (BOOL)canConnectToDiscoveredPeripheral:(SILDiscoveredPeripheral *)discoveredPeripheral {
    return (self.discoveredPeripheralMapping[discoveredPeripheral.peripheral.identifier] != nil);
}

- (void)connectToDiscoveredPeripheral:(SILDiscoveredPeripheral *)discoveredPeripheral {
    if ([self canConnectToDiscoveredPeripheral:discoveredPeripheral]) {
        [self connectPeripheral:discoveredPeripheral.peripheral];
    }
}

- (void)connectPeripheral:(CBPeripheral *)peripheral {
    if (!self.connectionTimeoutTimer) {
        self.connectionTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:SILCentralManagerConnectionTimeoutThreshold
                                                                       target:self
                                                                     selector:@selector(didFireConnectionTimeoutTimer:)
                                                                     userInfo:nil
                                                                      repeats:NO];
        if (self.connectingPeripheral == nil) {
            [self stopScanning];

            self.connectingPeripheral = peripheral;
            if (self.connectingPeripheral.state == CBPeripheralStateConnected) {
                [self centralManager:self.centralManager didConnectPeripheral:self.connectingPeripheral];
            } else {
                [self.centralManager connectPeripheral:peripheral options:nil];
            }
        }
    }
}

- (void)disconnectConnectedPeripheral {
    if (self.connectedPeripheral) {
        [self disconnectFromPeripheral:self.connectedPeripheral];
    }
}

- (void)disconnectFromPeripheral:(CBPeripheral *)peripheral {
    self.disconnectingPeripheral = peripheral;
    [self.centralManager cancelPeripheralConnection:peripheral];
}

- (void)removeUnfiredConnectionTimeoutTimer {
    if (self.connectionTimeoutTimer) {
        [self.connectionTimeoutTimer invalidate];
        self.connectionTimeoutTimer = nil;
    }
}

- (void)didFireConnectionTimeoutTimer:(NSTimer *)timer {
    if (self.connectingPeripheral) {
        self.connectionTimeoutTimer = nil;

        [self.centralManager cancelPeripheralConnection:self.connectingPeripheral];
        NSError *error = [NSError sil_errorWithCode:SILErrorCodePeripheralConnectionTimeout
                                           userInfo:nil];
        [self handleConnectionFailureWithError:error];
    }
}

- (void)handleConnectionFailureWithError:(NSError *)error {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[SILCentralManagerPeripheralKey] = self.connectingPeripheral;
    if (error) {
        userInfo[SILCentralManagerErrorKey] = error;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SILCentralManagerDidFailToConnectPeripheralNotification
                                                        object:self
                                                      userInfo:userInfo];
    self.connectingPeripheral = nil;
}

#pragma mark - Scanning

- (BOOL)shouldScanForDevices {
    return ((self.centralManager.state == CBManagerStatePoweredOn) &&
            (self.scanForPeripheralsObservers.count > 0));
}

- (void)toggleScanning {
    if ([self shouldScanForDevices]) {
        [self startScanning];
    } else {
        [self stopScanning];
    }
}

- (void)startScanning {
    if (self.centralManager.state == CBManagerStatePoweredOn) {
        if (!self.isScanning) {
            self.isScanning = YES;

            [self startDiscoveryTimeoutTimer];
            [self filterDiscoveredPeripheralByTimeout];
            [self.centralManager scanForPeripheralsWithServices:self.serviceUUIDs
                                                        options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
        }
    }
}

- (void)stopScanning {
    if (self.isScanning) {
        self.isScanning = NO;

        [self stopDiscoveryTimeoutTimer];
        [self filterDiscoveredPeripheralByTimeout];
        [self.centralManager stopScan];
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    [self toggleScanning];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if (peripheral.identifier) {
        long long timestampInterval = (long long)([[NSDate date] timeIntervalSince1970] * 1000000000);
        [self insertOrUpdateDiscoveredPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI andDiscoveringTimestamp:timestampInterval];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"didConnectPeripheral: %@", peripheral);
    [self removeUnfiredConnectionTimeoutTimer];
    self.connectingPeripheral = nil;
    self.connectedPeripheral = peripheral;
    [[NSNotificationCenter defaultCenter] postNotificationName:SILCentralManagerDidConnectPeripheralNotification
                                                        object:self
                                                      userInfo:@{
                                                                 SILCentralManagerPeripheralKey : peripheral
                                                                 }];
    [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didConnectPeripheral: " andPeripheral:peripheral andError:nil]];
    [self.connectionsViewModel addNewConnectedPeripheral:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"didFailToConnectPeripheral: %@", peripheral.name);
    NSLog(@"error: %@", error);
    [self removeUnfiredConnectionTimeoutTimer];
    [self handleConnectionFailureWithError:error];
    [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didFailToConnectPeripheral: " andPeripheral:peripheral andError:error]];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"didDisconnectPeripheral: %@", peripheral.name);
    NSLog(@"error: %@", error);
    if (self.connectedPeripheral && [self.connectedPeripheral isEqual:peripheral]) {
        self.connectedPeripheral = nil;

        NSMutableDictionary *userInfo = nil;
        if(self.disconnectingPeripheral) {
            self.disconnectingPeripheral = nil;
        } else {
            userInfo = [NSMutableDictionary dictionary];
            userInfo[SILCentralManagerPeripheralKey] = peripheral;
            if (error) {
                userInfo[SILCentralManagerErrorKey] = error;
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SILCentralManagerDidDisconnectPeripheralNotification
                                                            object:self
                                                          userInfo:userInfo];
    }
    [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didDisconnectPeripheral: " andPeripheral:peripheral andError:error]];
    [self postDeleteDisconnectedPeripheral:peripheral];
}

#pragma mark - Notifications

- (void)postDidUpdateDiscoveredPeripheralsNotification {
    for (SILWeakNotificationPair *pair in self.scanForPeripheralsObservers) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [pair.object performSelector:pair.selector
                          withObject:@{
                                       SILCentralManagerDiscoveredPeripheralsKey : [self discoveredPeripherals],
                                       }];
#pragma clang diagnostic pop
    }
}

- (void)addScanForPeripheralsObserver:(id)observer selector:(SEL)aSelector {
    BOOL alreadyObserving = NO;
    for (SILWeakNotificationPair *pair in self.scanForPeripheralsObservers) {
        if ([pair.object isEqual:observer]) {
            alreadyObserving = YES;
        }
    }

    if (!alreadyObserving) {
        [self.scanForPeripheralsObservers addObject:[SILWeakNotificationPair pairWithObject:observer selector:aSelector]];
        [self toggleScanning];
    }
}

- (void)removeScanForPeripheralsObserver:(id)observer {
    NSMutableArray *pairsToRemove = [NSMutableArray array];
    for (SILWeakNotificationPair *pair in self.scanForPeripheralsObservers) {
        if (!pair.object || [pair.object isEqual:observer]) {
            [pairsToRemove addObject:pair];
        }
    }
    [self.scanForPeripheralsObservers removeObjectsInArray:pairsToRemove];

    [self toggleScanning];
}

- (void)postRegisterLogNotification:(NSString*)description {
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationRegisterLog object:self userInfo:@{ SILNotificationKeyDescription : description}];
}

- (void)postDeleteDisconnectedPeripheral:(CBPeripheral*)peripheral {
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationDeleteDisconnectedPeripheral object:self userInfo:@{ SILNotificationKeyUUID: peripheral.identifier.UUIDString}];
}

@end
