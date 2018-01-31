//
//  SILProximityCalculator.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/6/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSInteger, SILBeaconProximity) {
    SILBeaconProximityUnknown,
    SILBeaconProximityImmediate,
    SILBeaconProximityNear,
    SILBeaconProximityFar,
};

extern NSString *SILBeaconProximityDisplayName(SILBeaconProximity proximity);

@interface SILProximityCalculator : NSObject

+ (float)estimatedDistanceWithRSSI:(NSNumber *)RSSI calibrationPower:(NSNumber *)calibrationPower;
+ (SILBeaconProximity)estimatedProximityWithRSSI:(NSNumber *)RSSI calibrationPower:(NSNumber *)calibrationPower;
+ (float)estimatedDistancewithBeacon:(CLBeacon *)beacon;
+ (SILBeaconProximity)proximityWithBeacon:(CLBeacon *)beacon;

@end
