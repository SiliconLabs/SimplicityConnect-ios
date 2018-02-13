//
//  SILBeaconRegistry.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/21/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
@class EddystoneBeacon;

@interface SILBeaconRegistry : NSObject

- (void)updateWithAdvertisment:(NSDictionary *)advertisement name:(NSString *)name RSSI:(NSNumber *)RSSI;
- (void)updateWithIBeacon:(CLBeacon *)beacon;
- (void)updateWithEddystoneBeacon:(EddystoneBeacon *)beacon;
- (NSArray *)beaconRegistryEntries;
- (void)removeIBeaconEntriesWithUUID:(NSUUID *)proximityUUID;

@end
