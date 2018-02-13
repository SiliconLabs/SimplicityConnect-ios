//
//  SILBeaconRegistryEntry.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/21/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILBeaconRegistryEntry.h"
#import "SILRSSIMeasurementTable.h"

NSString * const SILBeaconRegistryEntryDateKey = @"date";
NSString * const SILBeaconRegistryEntryRSSIKey = @"RSSI";

@interface SILBeaconRegistryEntry ()

@end

@implementation SILBeaconRegistryEntry

#pragma mark - Instance Methods

- (instancetype)initWithBeacon:(SILBeacon *)beacon {
    self = [super init];
    if (self) {
        self.beacon = beacon;
        self.RSSIMeasurementTable = [[SILRSSIMeasurementTable alloc] init];
    }
    return self;
}

@end
