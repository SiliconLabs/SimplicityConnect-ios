//
//  SILCentralManager.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/4/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import "SILCentralManager.h"
#import "SILBrowserConnectionsViewModel.h"
#import "NSError+SILHelpers.h"
#import "SILWeakTargetWrapper.h"
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
NSString * const SILCentralManagerBluetoothDisabledNotification = @"SILCentralManagerBluetoothWasDisabledNotification";

NSString * const SILCentralManagerDiscoveredPeripheralsKey = @"SILCentralManagerDiscoveredPeripheralsKey";
NSString * const SILCentralManagerPeripheralKey = @"SILCentralManagerPeripheralKey";
NSString * const SILCentralManagerErrorKey = @"SILCentralManagerErrorKey";

NSString * const kIBeaconUUIDString = @"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0";
NSString * const kIBeaconDMPUUIDString = @"0047E70A-5DC1-4725-8799-830544AE04F6";
NSString * const kAltBeaconUUIDString = @"511AB500511AB500511AB500511AB500";
CGFloat const kIBeaconMajorNumber = 34987.0f;
CGFloat const kIBeaconMinorNumber = 1025.0f;
NSString * const kIBeaconIdentifier = @"com.silabs.retailbeacon";
CGFloat const kIBeaconDMPZigbeeMajorNumber = 256.0f;
CGFloat const kIBeaconDMPProprietaryMajorNumber = 512.0f;
NSString * const kIBeaconDMPZigbeeIdentifier = @"com.silabs.retailbeacon.dmpZigbee";
NSString * const kIBeaconDMPProprietaryIdentifier = @"com.silabs.retailbeacon.dmpProprietary";
CGFloat const kAltBeaconMfgId = 0x0047;

NSTimeInterval const SILCentralManagerDiscoveryTimeoutThreshold = 5.0;
NSTimeInterval const SILCentralManagerConnectionTimeoutThreshold = 20.0;

@interface SILCentralManager ()

@property (assign, nonatomic) BOOL isScanning;
@property (strong, nonatomic) NSMutableDictionary *discoveredPeripheralMapping;
@property (strong, nonatomic) NSTimer *discoveryTimeoutTimer;

@property (strong, nonatomic) NSTimer *connectionTimeoutTimer;
@property (strong, nonatomic) CBPeripheral *connectingPeripheral;
@property (strong, nonatomic) CBPeripheral *disconnectingPeripheral;
@property (strong, nonatomic) SILBrowserConnectionsViewModel* connectionsViewModel;
@property (strong, nonatomic) NSMutableArray *scanForPeripheralsObservers;

@property (nonatomic, strong) NSArray<CLBeaconRegion *> *regions;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation SILCentralManager

- (instancetype)initWithServiceUUIDs:(NSArray *)serviceUUIDs {
    self = [super init];
    if (self) {
        self.serviceUUIDs = [serviceUUIDs copy];
        self.discoveredPeripheralMapping = [NSMutableDictionary dictionary];
        self.scanForPeripheralsObservers = [NSMutableArray array];
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
        [self setupNotifications];
        [self setupBeaconMonitoring];
        self.connectionsViewModel = [SILBrowserConnectionsViewModel sharedInstance];
    }
    return self;
}

- (void)setupBeaconMonitoring {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];
    NSUUID *iBeaconUUID = [[NSUUID alloc] initWithUUIDString:kIBeaconUUIDString];
    CLBeaconRegion* beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:iBeaconUUID identifier:kIBeaconIdentifier];
    self.regions = @[beaconRegion];
}

- (void)startRanging {
    for (CLBeaconRegion *beaconRegion in self.regions) {
        [self.locationManager startRangingBeaconsInRegion:beaconRegion];
    }
}

- (void)stopRanging {
    for (CLBeaconRegion *beaconRegion in self.regions) {
        [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
    }
}

- (void)dealloc {
    [self.discoveryTimeoutTimer invalidate];
    [self.connectionTimeoutTimer invalidate];
    [self.centralManager stopScan];
    [self stopRanging];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

- (NSArray *)discoveredPeripherals {
    return [self.discoveredPeripheralMapping allValues];
}

- (SILDiscoveredPeripheral *)discoveredPeripheralForPeripheral:(CBPeripheral *)peripheral {
    NSString* peripheralIdentifier = [SILDiscoveredPeripheralIdentifierProvider provideKeyForCBPeripheral:peripheral];
    return self.discoveredPeripheralMapping[peripheralIdentifier];
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

- (void)insertOrUpdateDiscoveredPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI andDiscoveringTimestamp:(double)timestamp {
    NSString* peripheralIdentifier = [SILDiscoveredPeripheralIdentifierProvider provideKeyForCBPeripheral:peripheral];
    SILDiscoveredPeripheral *discoveredPeripheral = self.discoveredPeripheralMapping[peripheralIdentifier];
    if (discoveredPeripheral) {
        [discoveredPeripheral updateWithAdvertisementData:advertisementData RSSI:RSSI andDiscoveringTimestamp:timestamp];
    } else {
        discoveredPeripheral = [[SILDiscoveredPeripheral alloc] initWithPeripheral:peripheral
                                                                 advertisementData:advertisementData
                                                                                  RSSI:RSSI
                                                           andDiscoveringTimestamp:timestamp];
        self.discoveredPeripheralMapping[peripheralIdentifier] = discoveredPeripheral;
    }
    [self postDidUpdateDiscoveredPeripheralsNotification];
}

- (void)removeDiscoveredPeripheral:(SILDiscoveredPeripheral *)discoveredPeripheral {
    [self.discoveredPeripheralMapping removeObjectForKey:discoveredPeripheral.identityKey];
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
        if (![discoveredPeripheral.rssiMeasurementTable hasRSSIMeasurementInPastTimeInterval:SILCentralManagerDiscoveryTimeoutThreshold]
            && discoveredPeripheral.peripheral.state != CBPeripheralStateConnected) {
            didRemovePeripherals = YES;
            discoveredPeripheral.hasTimedOut = YES;
        }
    }
    if (didRemovePeripherals) {
        [self postDidUpdateDiscoveredPeripheralsNotification];
    }
}

#pragma mark - Connecting Peripherals

- (BOOL)canConnectToDiscoveredPeripheral:(SILDiscoveredPeripheral *)discoveredPeripheral {
    return (self.discoveredPeripheralMapping[discoveredPeripheral.identityKey] != nil);
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
    if (self.centralManager.state == CBManagerStateUnknown) {
        [NSTimer scheduledTimerWithTimeInterval:1 repeats:false block:^(NSTimer * _Nonnull timer) {
            [self toggleScanning];
        }];
    } else if ([self shouldScanForDevices]) {
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
        [self startRanging];
    }
}

- (void)stopScanning {
    if (self.isScanning) {
        self.isScanning = NO;

        [self stopDiscoveryTimeoutTimer];
        [self filterDiscoveredPeripheralByTimeout];
        [self.centralManager stopScan];
        [self stopRanging];
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    [self checkBluetoothState:central.state];
    [self toggleScanning];
}

- (void)checkBluetoothState:(CBManagerState)state {
    if (state == CBManagerStatePoweredOff) {
        [self postBluetoothWasDisabledNotification];
        [self.connectionsViewModel clearViewModelData];
        NSLog(@"BLUETOOTH DISABLED!");
    } else if (state == CBManagerStatePoweredOn) {
        NSLog(@"Blutooth enabled");
    }
}

- (void)postBluetoothWasDisabledNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:SILCentralManagerBluetoothDisabledNotification
                                                        object:self
                                                      userInfo:nil];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if (![self isProbablyIBeacon:advertisementData]) {
        if (peripheral.identifier) {
            double timestamp = [self getTimestampWithAdvertisementData:advertisementData];
            [self insertOrUpdateDiscoveredPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI andDiscoveringTimestamp:timestamp];
        }
    }
}

- (BOOL)isProbablyIBeacon:(NSDictionary*)advertisementData {
    const NSArray* nonIBeaconKeys = @[CBAdvertisementDataManufacturerDataKey,
                                      CBAdvertisementDataLocalNameKey,
                                      CBAdvertisementDataServiceDataKey,
                                      CBAdvertisementDataServiceUUIDsKey,
                                      CBAdvertisementDataOverflowServiceUUIDsKey,
                                      CBAdvertisementDataTxPowerLevelKey,
                                      CBAdvertisementDataSolicitedServiceUUIDsKey];
    
    for (int i = 0; i < nonIBeaconKeys.count; i++) {
        if ([advertisementData.allKeys containsObject:nonIBeaconKeys[i]]) {
            return NO;
        }
    }
    
    if ([advertisementData[CBAdvertisementDataIsConnectable] boolValue] == YES) {
        return NO;
    }
    
    return YES;
}

- (double)getTimestampWithAdvertisementData:(NSDictionary *)advertisementData {
    double timestamp = 0;
    if (@available(iOS 13, *)) {
        NSString* stringValue = advertisementData[@"kCBAdvDataTimestamp"];
        timestamp = [stringValue doubleValue];
    } else {
        timestamp = [[NSDate date] timeIntervalSinceReferenceDate];
    }
    return timestamp;
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
    [self postFailedToConnectPeripheral:peripheral andError:error];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"didDisconnectPeripheral: %@", peripheral.name);
    NSLog(@"error: %@", error);
    
    BOOL wasConnected = [self.connectionsViewModel isConnectedPeripheral:peripheral];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[SILCentralManagerPeripheralKey] = peripheral;
    userInfo[SILNotificationKeyUUID] = peripheral.identifier.UUIDString;
    if (error) {
        userInfo[SILCentralManagerErrorKey] = error;
    }
        
    [[NSNotificationCenter defaultCenter] postNotificationName:SILCentralManagerDidDisconnectPeripheralNotification
                                                        object:self
                                                        userInfo:userInfo];
    [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didDisconnectPeripheral: " andPeripheral:peripheral andError:error]];
    if (wasConnected) {
        [self postDeleteDisconnectedPeripheral:peripheral andError:error];
    } else {
        [self postFailedToConnectPeripheral:peripheral andError:error];
    }
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
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationRegisterLog
                                                        object:self
                                                      userInfo:@{
                                                          SILNotificationKeyDescription : description
                                                      }];
}

- (void)postDeleteDisconnectedPeripheral:(CBPeripheral*)peripheral andError:(NSError*)error {
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationDeleteDisconnectedPeripheral
                                                        object:self
                                                      userInfo:@{
                                                          SILNotificationKeyUUID: peripheral.identifier.UUIDString,
                                                          SILNotificationKeyError: [NSString stringWithFormat:@"%ld", (long)error.code]
                                                      }];
}

- (void)postFailedToConnectPeripheral:(CBPeripheral*)peripheral andError:(NSError*)error {
    NSString* peripheralName = peripheral.name ?: @"N/A";
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationFailedToConnectPeripheral
                                                        object:self
                                                      userInfo:@{
                                                          SILNotificationKeyPeripheralName: peripheralName,
                                                          SILNotificationKeyError: [NSString stringWithFormat:@"%ld", (long)error.code]
                                                      }];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    for (CLBeaconRegion *beaconRegion in self.regions) {
        if ([beaconRegion isEqual:region]) {
           [self.locationManager startRangingBeaconsInRegion:beaconRegion];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    for (CLBeaconRegion *beaconRegion in self.regions) {
        if ([beaconRegion isEqual:region]) {
            [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region {
    for (CLBeacon *foundBeacon in beacons) {
        if (foundBeacon.rssi != 0) {
            [self insertOrUpdateDiscoveredIBeacon:foundBeacon];
        }
    }
}

- (void)insertOrUpdateDiscoveredIBeacon:(CLBeacon*)iBeacon {
    NSString* iBeaconIdentifier = [SILDiscoveredPeripheralIdentifierProvider provideKeyForCLBeacon:iBeacon];
    double timestamp = [self getTimestamptForIBeacons:iBeacon];
    SILDiscoveredPeripheral* discoveredPeripheral = self.discoveredPeripheralMapping[iBeaconIdentifier];
    if (discoveredPeripheral) {
        [discoveredPeripheral updateWithIBeacon:iBeacon andDiscoveringTimestamp:timestamp];
    } else {
        discoveredPeripheral = [[SILDiscoveredPeripheral alloc] initWithIBeacon:iBeacon andDiscoveringTimestamp:timestamp];
        self.discoveredPeripheralMapping[iBeaconIdentifier] = discoveredPeripheral;
    }
    [self postDidUpdateDiscoveredPeripheralsNotification];
}

- (double)getTimestamptForIBeacons:(CLBeacon*)iBeacon {
    if (@available(iOS 13.0, *)) {
        return [iBeacon.timestamp timeIntervalSinceReferenceDate];
    } else {
        return [[NSDate date] timeIntervalSinceReferenceDate];
    }
}

@end
