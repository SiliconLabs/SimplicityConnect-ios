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
@class SILDiscoveredPeripheral;

@protocol SILDiscoveredPeripheralDelegate <NSObject>

- (void)peripheral:(SILDiscoveredPeripheral*)peripheral didUpdateWithAdvertisementData:(NSDictionary*)dictionary andRSSI:(NSNumber*)rssi;

@end

@interface SILDiscoveredPeripheral : NSObject

@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) SILRSSIMeasurementTable *RSSIMeasurementTable;
@property (strong, nonatomic) NSString *advertisedLocalName;
@property (strong, nonatomic) NSArray *advertisedServiceUUIDs;
@property (strong, nonatomic) NSNumber *txPowerLevel;
@property (strong, nonatomic) NSData *manufacturerData;

@property (nonatomic, weak) id<SILDiscoveredPeripheralDelegate> delegate;

@property (nonatomic) BOOL isConnectable;
@property (nonatomic, readonly) BOOL isBlueGeckoBeacon;
@property (nonatomic, readonly) BOOL isDMPConnectedLightConnect;
@property (nonatomic, readonly) BOOL isDMPConnectedLightProprietary;
@property (nonatomic, readonly) BOOL isDMPConnectedLightThread;
@property (nonatomic, readonly) BOOL isDMPConnectedLightZigbee;
@property (nonatomic, readonly) BOOL isRangeTest;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                 advertisementData:(NSDictionary *)advertisementData
                              RSSI:(NSNumber *)RSSI;

- (void)updateWithAdvertisementData:(NSDictionary *)advertisementData
                                         RSSI:(NSNumber *)RSSI;

@end
