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

@end

@implementation SILDiscoveredPeripheral

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                 advertisementData:(NSDictionary *)advertisementData
                              RSSI:(NSNumber *)RSSI {
    self = [super init];
    if (self) {
        self.peripheral = peripheral;
        self.RSSIMeasurementTable = [[SILRSSIMeasurementTable alloc] init];
        [self updateWithAdvertisementData:advertisementData RSSI:RSSI];
    }
    return self;
}

- (void)updateWithAdvertisementData:(NSDictionary *)advertisementData
                               RSSI:(NSNumber *)RSSI {
    self.advertisedLocalName = advertisementData[CBAdvertisementDataLocalNameKey] ?: self.peripheral.name;
    self.advertisedServiceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey];
    self.txPowerLevel = advertisementData[CBAdvertisementDataTxPowerLevelKey];
    self.isConnectable = [advertisementData[CBAdvertisementDataIsConnectable] boolValue];
    self.manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey];
    
    [self.RSSIMeasurementTable addRSSIMeasurement:RSSI];
    [self.delegate peripheral:self didUpdateWithAdvertisementData:advertisementData andRSSI:RSSI];
}

- (BOOL)isBlueGeckoBeacon {
    return self.peripheral.name && ([self.peripheral.name hasPrefix:@"BG"] ||
           [self.peripheral.name rangeOfString:@"Blue Gecko"].location != NSNotFound);
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

@end
