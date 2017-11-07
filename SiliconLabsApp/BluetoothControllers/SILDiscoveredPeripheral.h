//
//  SILDiscoveredPeripheral.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/14/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
@class SILRSSIMeasurementTable;

@interface SILDiscoveredPeripheral : NSObject

@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) SILRSSIMeasurementTable *RSSIMeasurementTable;
@property (strong, nonatomic) NSString *advertisedLocalName;
@property (strong, nonatomic) NSArray *advertisedServiceUUIDs;
@property (strong, nonatomic) NSNumber *txPowerLevel;
@property (nonatomic) BOOL isConnectable;
@property (nonatomic, readonly) BOOL isBlueGeckoBeacon;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                 advertisementData:(NSDictionary *)advertisementData
                              RSSI:(NSNumber *)RSSI;

- (void)updateWithAdvertisementData:(NSDictionary *)advertisementData
                                         RSSI:(NSNumber *)RSSI;

@end
