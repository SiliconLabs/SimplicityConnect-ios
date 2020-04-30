//
//  SILDiscoveredPeripheral.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/14/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILDiscoveredPeripheral.h"
#import "SILRSSIMeasurementTable.h"
#import "SILBluetoothBrowser+Constants.h"
#import "SILConstants.h"

@interface SILDiscoveredPeripheral ()

@property (strong, nonatomic) NSMutableArray *RSSIMeasurements;
@property (nonatomic) double lastTimestamp;
@property (nonatomic) long long packetReceivedCount;

@end

@implementation SILDiscoveredPeripheral

NSString* const RSSIAppendingString = @" RSSI";
NSString* const ConnectableDevice = @"Connectable";
NSString* const NonConnectableDevice = @"Non-connectable";

+ (NSString *)connectableDevice { return ConnectableDevice; }
+ (NSString *)nonConnectableDevice { return NonConnectableDevice; }

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                 advertisementData:(NSDictionary *)advertisementData
                              RSSI:(NSNumber *)RSSI
            andDiscoveringTimestamp:(double)timestamp {
    self = [super init];
    if (self) {
        self.peripheral = peripheral;
        self.uuid = self.peripheral.identifier;
        self.identityKey = [SILDiscoveredPeripheralIdentifierProvider provideKeyForCBPeripheral:self.peripheral];
        self.RSSIMeasurementTable = [[SILRSSIMeasurementTable alloc] init];
        self.advertisingInterval = 0;
        self.packetReceivedCount = 0;
        self.isConnectable = NO;
        self.lastTimestamp = timestamp;
        [self updateWithAdvertisementData:advertisementData RSSI:RSSI andDiscoveringTimestamp:timestamp];
        self.advertisedLocalName = DefaultDeviceName;
    }
    return self;
}

- (void)updateWithAdvertisementData:(NSDictionary *)advertisementData
                               RSSI:(NSNumber *)RSSI
        andDiscoveringTimestamp:(double)timestamp {
    self.advertisedLocalName = advertisementData[CBAdvertisementDataLocalNameKey] ?: self.peripheral.name;
    self.advertisedServiceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey];
    self.txPowerLevel = advertisementData[CBAdvertisementDataTxPowerLevelKey];
    if (!self.isConnectable) {
        self.isConnectable = [advertisementData[CBAdvertisementDataIsConnectable] boolValue];
    }
    self.manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey];
    self.beacon = [self parseBeaconData:advertisementData];
    if ([self isCorrectAdvertisingPacket:timestamp]) {
        self.packetReceivedCount++;
        [self calculateAdvertisingIntervalWith:timestamp];
        self.lastTimestamp = timestamp;
    }
    [self.RSSIMeasurementTable addRSSIMeasurement:RSSI];
    [self.delegate peripheral:self didUpdateWithAdvertisementData:advertisementData andRSSI:RSSI];
}

- (BOOL)isCorrectAdvertisingPacket:(double)currentTimestamp {
    double currentInterval = currentTimestamp - self.lastTimestamp;
    if (currentInterval < 0.005) {
        return NO;
    }
    return YES;
}

- (void)calculateAdvertisingIntervalWith:(double)currentTimestamp {
    const double Add3MsToInterval = 0.003;
    const double MultiplierForBegginingCalculating = 0.0007;
    const double MultiplierForAverageInterval = 0.0014;
    const int ReliableForCalculatingPacketAmount = 29;
    const int MinimumCount = 10;
    
    double currentInterval = currentTimestamp - self.lastTimestamp;

    if (currentInterval <= 0) {
        return;
    }
    
    if (self.advertisingInterval == 0) {
        self.advertisingInterval = currentInterval;
    } else if ((currentInterval < self.advertisingInterval * MultiplierForBegginingCalculating) && self.packetReceivedCount < MinimumCount) {
        self.advertisingInterval = currentInterval;
    } else if (currentInterval < self.advertisingInterval + Add3MsToInterval) {
        long long limitedCount = MIN(self.packetReceivedCount, MinimumCount);
        self.advertisingInterval = (((self.advertisingInterval * (limitedCount - 1) + currentInterval)) / limitedCount);
    } else if (currentInterval < self.advertisingInterval * MultiplierForAverageInterval) {
        self.advertisingInterval = (((self.advertisingInterval * ReliableForCalculatingPacketAmount + currentInterval)) / (ReliableForCalculatingPacketAmount + 1));
    }
}

- (void)resetLastTimestampValue {
    self.lastTimestamp = 0.0;
}

- (SILBeacon*)parseBeaconData:(NSDictionary*)adverisement {
    if (self.manufacturerData) {
        NSError* error = nil;
        SILBeacon* beacon = [SILBeacon beaconWithAdvertisment:adverisement name:self.advertisedLocalName error:&error];
        if (error == nil) {
            return beacon;
        }
    }
    
    SILBeacon* unknownBeacon = [[SILBeacon alloc] init];
    unknownBeacon.name = @"Unspecified";
    unknownBeacon.type = SILBeaconTypeUnspecified;
    
    return unknownBeacon;
}

- (instancetype)initWithIBeacon:(CLBeacon*)iBeacon andDiscoveringTimestamp:(double)timestamp {
    self = [super init];
    if (self) {
        self.peripheral = nil;
        if (@available(iOS 13.0, *)) {
            self.uuid = iBeacon.UUID;
        } else {
            self.uuid = iBeacon.proximityUUID;
        }
        self.identityKey = [SILDiscoveredPeripheralIdentifierProvider provideKeyForCLBeacon:iBeacon];
        self.beacon = [SILBeacon beaconWithIBeacon:iBeacon];
        self.beacon.name = SILBeaconIBeacon;
        self.beacon.beacon = iBeacon;
        self.RSSIMeasurementTable = [[SILRSSIMeasurementTable alloc] init];
        self.advertisingInterval = 0;
        self.packetReceivedCount = 0;
        self.isConnectable = NO;
        self.lastTimestamp = timestamp;
        [self updateWithIBeacon:iBeacon andDiscoveringTimestamp:timestamp];
        self.advertisedLocalName = DefaultDeviceName;
    }
    return self;
}

- (void)updateWithIBeacon:(CLBeacon*)iBeacon andDiscoveringTimestamp:(double)timestamp {
    self.advertisedServiceUUIDs = nil;
    self.txPowerLevel = nil;
    self.isConnectable = NO;
    self.manufacturerData = nil;
    if ([self isCorrectAdvertisingPacket:timestamp]) {
        self.packetReceivedCount++;
        [self calculateAdvertisingIntervalWith:timestamp];
        self.lastTimestamp = timestamp;
    }
    NSNumber* rssi = [NSNumber numberWithLong:iBeacon.rssi];
    [self.RSSIMeasurementTable addRSSIMeasurement:rssi];
    [self.delegate peripheral:self didUpdateWithAdvertisementData:nil andRSSI:rssi];
}

- (BOOL)isDMPConnectedLightConnect {
    return [self isContainService:SILServiceNumberConnectedLightingConnect];
}

- (BOOL)isDMPConnectedLightProprietary {
    return [self isContainService:SILServiceNumberConnectedLightingProprietary];
}

- (BOOL)isDMPConnectedLightThread {
    return [self isContainService:SILServiceNumberConnectedLightingThread];
}

- (BOOL)isDMPConnectedLightZigbee {
    return [self isContainService:SILServiceNumberConnectedLightingZigbee];
}

- (BOOL)isRangeTest {
    return [self isContainService:SILServiceNumberRangeTest];
}

- (BOOL)isContainService:(NSString *)serviceUUID {
    CBUUID * const service = [CBUUID UUIDWithString:serviceUUID];
    return [self.advertisedServiceUUIDs containsObject:service];
}

- (NSString *)rssiDescription {
    NSString *rssi = [self.RSSIMeasurementTable.lastRSSIMeasurement stringValue];
    NSMutableString* rssiDescription = [[NSMutableString alloc] initWithString:rssi];
    [rssiDescription appendString:RSSIAppendingString];
    return rssiDescription;
}

@end
