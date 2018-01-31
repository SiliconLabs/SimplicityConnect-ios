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
    
    [self.RSSIMeasurementTable addRSSIMeasurement:RSSI];
}

- (BOOL)isBlueGeckoBeacon {
    return [self.peripheral.name hasPrefix:@"BG"] ||
           [self.peripheral.name rangeOfString:@"Blue Gecko"].location != NSNotFound;
}

- (BOOL)isDMPConnectedLightZigbee {
    CBUUID *lightService = [CBUUID UUIDWithString:SILServiceNumberConnectedLightingZigbee];
    return [self.advertisedServiceUUIDs containsObject:lightService];
}

- (BOOL)isDMPConnectedLightProprietary {
    CBUUID *lightService = [CBUUID UUIDWithString:SILServiceNumberConnectedLightingProprietary];
    return [self.advertisedServiceUUIDs containsObject:lightService];
}

@end
