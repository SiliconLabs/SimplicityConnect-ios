//
//  SILBeaconRegistryEntryViewModel.m
//  SiliconLabsApp
//
//  Created by Bob Gilmore on 3/16/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILBeaconRegistryEntryViewModel.h"
#import "SILBGBeaconViewModel.h"
#import "SILIBeaconViewModel.h"
#import "SILAltBeaconViewModel.h"
#import "SILEddystoneBeaconViewModel.h"

CGFloat const SILRetailBeaconAppDistanceInterval = 5.0;

@class SILDoubleKeyDictionaryPair;

@interface SILBeaconRegistryEntryViewModel()
@property (strong, nonatomic, readwrite) SILBeaconRegistryEntry *entry;
@property (strong, nonatomic, readwrite) SILBeaconViewModel *beaconViewModel;
@end

@implementation SILBeaconRegistryEntryViewModel

- (instancetype)initWithBeaconRegistryEntry:(SILBeaconRegistryEntry *)entry {
    self = [super init];
    if (self) {
        _entry = entry;
        _beaconViewModel = [self beaconViewModelForBeacon:entry.beacon];
    }
    return self;
}

- (SILBeaconViewModel *)beaconViewModelForBeacon:(SILBeacon *)beacon {
    SILBeaconViewModel *viewModel = nil;
    switch (beacon.type) {
        case SILBeaconTypeIBeacon:
            viewModel = [[SILIBeaconViewModel alloc] initWithBeacon:beacon];
            break;
        case SILBeaconTypeAltBeacon:
            viewModel = [[SILAltBeaconViewModel alloc] initWithBeacon:beacon];
            break;
        case SILBeaconTypeEddystone:
            viewModel = [[SILEddystoneBeaconViewModel alloc] initWithBeacon:beacon];
            break;
        default:
            break;
    }
    return viewModel;
}

- (NSString *)name {
    return _beaconViewModel.name;
}

- (NSString *)imageName {
    return _beaconViewModel.imageName;
}

- (UIImage *)image {
    return [UIImage imageNamed:[self imageName]];
}

- (NSString *)type {
    return _beaconViewModel.type;
}

- (NSNumber *)rssi {
    return _beaconViewModel.rssi;
}

- (NSNumber *)lastRSSI {
    return [_entry.RSSIMeasurementTable lastRSSIMeasurement];
}

- (SILBeaconProximity)proximity {
    return _entry.beacon.beacon ?
    [SILProximityCalculator proximityWithBeacon:_entry.beacon.beacon] :
    [SILProximityCalculator estimatedProximityWithRSSI:[self lastRSSI]
                                      calibrationPower:_entry.beacon.txPower];
}

- (UIImage *)distanceImage {
    UIImage* image = nil;
    switch ([self proximity]) {
        case SILBeaconProximityImmediate:
            image = [UIImage imageNamed:SILImageNameBeaconRangeImmediate];
            break;
        case SILBeaconProximityNear:
            image = [UIImage imageNamed:SILImageNameBeaconRangeNear];
            break;
        case SILBeaconProximityFar:
            image = [UIImage imageNamed:SILImageNameBeaconRangeFar];
        default:
            break;
    }
    return image;
}

- (NSString *)distanceName {
    return [SILBeaconProximityDisplayName([self proximity]) uppercaseString];
}

- (NSString *)formattedRSSI {
    int RSSI = [[self lastRSSI] intValue];
    return [NSString stringWithFormat:@"%i", RSSI];
}

- (NSString *)formattedTx {
    int tx = [_beaconViewModel.tx intValue];
    return [NSString stringWithFormat:@"%i", tx];
}

@end
