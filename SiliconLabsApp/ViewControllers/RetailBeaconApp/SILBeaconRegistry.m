//
//  SILBeaconRegistry.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/21/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILBeaconRegistry.h"
#import "SILBeacon.h"
#import "SILBeaconRegistryEntry.h"
#import "SILRSSIMeasurementTable.h"

NSTimeInterval const SILBeaconRegistryTimeoutThreshold = 5.0;

@interface SILBeaconRegistry ()
@property (strong, nonatomic) NSMutableDictionary *beaconEntries;
@end

@implementation SILBeaconRegistry

+ (NSString *)beaconKeyWithBeacon:(SILBeacon *)beacon {
    return [NSString stringWithFormat:@"%@_%d_%d_%@", beacon.UUIDString, beacon.major, beacon.minor, beacon.url.absoluteString];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.beaconEntries = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)removeLostBeacons {
    NSMutableArray *timeoutBeaconKeys = [NSMutableArray array];
    for (NSString *beaconKey in self.beaconEntries) {
        SILBeaconRegistryEntry *entry = self.beaconEntries[beaconKey];
        if (![entry.RSSIMeasurementTable hasRSSIMeasurementInPastTimeInterval:SILBeaconRegistryTimeoutThreshold]) {
            [timeoutBeaconKeys addObject:beaconKey];
        }
    }
    if (timeoutBeaconKeys.count > 0) {
        [self.beaconEntries removeObjectsForKeys:timeoutBeaconKeys];
    }
}

- (void)removeIBeaconEntriesWithUUID:(NSUUID *)proximityUUID {
    NSMutableArray *uuidBeaconKeys = [NSMutableArray array];
    for (NSString *beaconKey in self.beaconEntries) {
        if ([beaconKey containsString:proximityUUID.UUIDString]) {
            [uuidBeaconKeys addObject:beaconKey];
        }
    }
    if (uuidBeaconKeys.count > 0) {
        [self.beaconEntries removeObjectsForKeys:uuidBeaconKeys];
    }
}

- (void)updateWithAdvertisment:(NSDictionary *)advertisement name:(NSString *)name RSSI:(NSNumber *)RSSI {
    [self removeLostBeacons];

    NSError *error = nil;
    SILBeacon *beacon = [SILBeacon beaconWithAdvertisment:advertisement name:name error:&error];
    if (error == nil) {
        NSString *beaconKey = [SILBeaconRegistry beaconKeyWithBeacon:beacon];

        SILBeaconRegistryEntry *entry = [self.beaconEntries objectForKey:beaconKey];
        if (entry == nil) {
            entry = [[SILBeaconRegistryEntry alloc] initWithBeacon:beacon];
            self.beaconEntries[beaconKey] = entry;
        } else {
            entry.beacon.calibrationPower = beacon.calibrationPower;
        }

        [entry.RSSIMeasurementTable addRSSIMeasurement:RSSI];
    }
}

- (void)updateWithIBeacon:(CLBeacon *)beacon {
    SILBeacon *silBeacon = [SILBeacon beaconWithIBeacon:beacon];
    
    NSString *beaconKey = [SILBeaconRegistry beaconKeyWithBeacon:silBeacon];
    
    SILBeaconRegistryEntry *entry = [self.beaconEntries objectForKey:beaconKey];
    if (entry == nil) {
        entry = [[SILBeaconRegistryEntry alloc] initWithBeacon:silBeacon];
        self.beaconEntries[beaconKey] = entry;
    } else {
        entry.beacon.calibrationPower = silBeacon.calibrationPower;
    }
    
    entry.beacon.beacon = beacon;
    [entry.RSSIMeasurementTable addRSSIMeasurement:@(beacon.rssi)];
}

- (void)updateWithEddystoneBeacon:(EddystoneBeacon *)beacon {
    SILBeacon *silBeacon = [SILBeacon beaconWithEddystone:beacon];

    NSString *beaconKey = [SILBeaconRegistry beaconKeyWithBeacon:silBeacon];

    SILBeaconRegistryEntry *entry = [self.beaconEntries objectForKey:beaconKey];
    if (entry == nil) {
        entry = [[SILBeaconRegistryEntry alloc] initWithBeacon:silBeacon];
        self.beaconEntries[beaconKey] = entry;
    } else {
        entry.beacon.calibrationPower = silBeacon.calibrationPower;
        entry.beacon.tlmData = silBeacon.tlmData;
        entry.beacon.url = silBeacon.url;
    }

    [entry.RSSIMeasurementTable addRSSIMeasurement:@(beacon.rssi)];
}

- (NSArray *)beaconRegistryEntries {
    [self removeLostBeacons];
    
    NSArray *allValues = [self.beaconEntries allValues];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"RSSIMeasurementTable.lastRSSIMeasurement" ascending:NO];
    return [allValues sortedArrayUsingDescriptors:@[sortDescriptor]];
}

@end
