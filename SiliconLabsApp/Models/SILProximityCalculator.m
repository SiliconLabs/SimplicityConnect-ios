//
//  SILProximityCalculator.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/6/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILProximityCalculator.h"
#import "SILSettings.h"

NSString *SILBeaconProximityDisplayName(SILBeaconProximity proximity) {
    switch (proximity) {
        case SILBeaconProximityUnknown:
            return @"Unknown";
        case SILBeaconProximityImmediate:
            return @"Immediate";
        case SILBeaconProximityNear:
            return @"Near";
        case SILBeaconProximityFar:
            return @"Far";
    }
}

@implementation SILProximityCalculator

// based on http://developer.radiusnetworks.com/2014/12/04/fundamentals-of-beacon-ranging.html
+ (float)estimatedDistanceWithRSSI:(NSNumber *)RSSI calibrationPower:(NSNumber *)calibrationPower {
    if (calibrationPower == 0) {
        return -1.0; // if we cannot determine distance, return -1.
    }

    float rssi = [RSSI floatValue];
    if (rssi == 0) {
        return -1.0; // if we cannot determine distance, return -1.
    }

    double ratio = rssi*1.0/[calibrationPower floatValue];
    if (ratio < 1.0) {
        return pow(ratio,10);
    } else {
        double accuracy =  (0.89976)*pow(ratio,7.7095) + 0.111;
        return accuracy;
    }
}

+ (SILBeaconProximity)estimatedProximityWithRSSI:(NSNumber *)RSSI calibrationPower:(NSNumber *)calibrationPower {
    float estimatedDistance = [self estimatedDistanceWithRSSI:RSSI calibrationPower:calibrationPower];
    if (estimatedDistance < 0) {
        return SILBeaconProximityUnknown;
    } else if (estimatedDistance < [SILSettings nearProximityThreshold]) {
        return SILBeaconProximityImmediate;
    } else if (estimatedDistance < [SILSettings farProximityThreshold]) {
        return SILBeaconProximityNear;
    } else {
        return SILBeaconProximityFar;
    }
}

+ (float)estimatedDistancewithBeacon:(CLBeacon *)beacon {
    return beacon.accuracy;
}

+ (SILBeaconProximity)proximityWithBeacon:(CLBeacon *)beacon {
    CLProximity distance = beacon.proximity;
    switch (distance) {
        case CLProximityUnknown:
            return SILBeaconProximityUnknown;
        case CLProximityImmediate:
            return SILBeaconProximityImmediate;
        case CLProximityNear:
            return SILBeaconProximityNear;
        case CLProximityFar:
            return SILBeaconProximityFar;
        default:
            return SILBeaconProximityUnknown;
    }
}

@end
