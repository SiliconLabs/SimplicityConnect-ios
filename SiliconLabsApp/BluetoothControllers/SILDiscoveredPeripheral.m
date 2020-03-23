//
//  SILDiscoveredPeripheral.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/14/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILDiscoveredPeripheral.h"
#import "SILRSSIMeasurementTable.h"
#import "SILConstants.h"

@interface SILDiscoveredPeripheral ()

@property (strong, nonatomic) NSMutableArray *RSSIMeasurements;
@property long long lastTimestamp;
@property long long packetReceivedCount;

@end

@implementation SILDiscoveredPeripheral

NSString* const DefaultDeviceName = @"Unknown";
NSString* const RSSIAppendingString = @" RSSI";
NSString* const ConnectableDevice = @"Connectable";
NSString* const NonConnectableDevice = @"Non-connectable";

+ (NSString *)connectableDevice { return ConnectableDevice; }
+ (NSString *)nonConnectableDevice { return NonConnectableDevice; }

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                 advertisementData:(NSDictionary *)advertisementData
                              RSSI:(NSNumber *)RSSI
            andDiscoveringTimestamp:(long long)timestamp {
    self = [super init];
    if (self) {
        self.peripheral = peripheral;
        self.RSSIMeasurementTable = [[SILRSSIMeasurementTable alloc] init];
        self.advertisingInterval = 0;
        self.packetReceivedCount = 0;
        self.lastTimestamp = timestamp;
        [self updateWithAdvertisementData:advertisementData RSSI:RSSI andDiscoveringTimestamp:timestamp];
        self.advertisedLocalName = DefaultDeviceName;
    }
    return self;
}

- (void)updateWithAdvertisementData:(NSDictionary *)advertisementData
                               RSSI:(NSNumber *)RSSI
        andDiscoveringTimestamp:(long long)timestamp {
    self.advertisedLocalName = advertisementData[CBAdvertisementDataLocalNameKey] ?: self.peripheral.name;
    self.advertisedServiceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey];
    self.txPowerLevel = advertisementData[CBAdvertisementDataTxPowerLevelKey];
    self.isConnectable = [advertisementData[CBAdvertisementDataIsConnectable] boolValue];
    self.manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey];
    self.beacon = [self parseBeaconData:advertisementData];
    self.packetReceivedCount++;
    [self calculateAdvertisingIntervalWith:timestamp];
    self.lastTimestamp = timestamp;
    [self.RSSIMeasurementTable addRSSIMeasurement:RSSI];
    [self.delegate peripheral:self didUpdateWithAdvertisementData:advertisementData andRSSI:RSSI];
}

- (void)calculateAdvertisingIntervalWith:(long long)currentTimestamp {
    long long currentInterval = currentTimestamp - self.lastTimestamp;
    long long ms3 = 3000000;
    int minimumCount = 10;

    if (currentInterval <= 0) {
        return;
    }
    
    if (self.advertisingInterval == 0) {
        self.advertisingInterval = currentInterval;
    } else if ((currentInterval < self.advertisingInterval * 0.7) && self.packetReceivedCount < minimumCount) {
        self.advertisingInterval = currentInterval;
    } else if (currentInterval < self.advertisingInterval + ms3) {
        long long limitedCount = MIN(self.packetReceivedCount, minimumCount);
        self.advertisingInterval = (((self.advertisingInterval * (limitedCount - 1) + currentInterval)) / limitedCount);
    } else if (currentInterval < self.advertisingInterval * 1.4) {
        self.advertisingInterval = (((self.advertisingInterval * (29) + currentInterval)) / 30);
    }
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
