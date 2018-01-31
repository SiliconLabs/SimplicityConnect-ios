//
//  SILBGBeaconViewModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/18/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILBGBeaconViewModel.h"
#import "SILBeacon.h"
#import "SILDoubleKeyDictionaryPair.h"

@implementation SILBGBeaconViewModel

- (NSString *)imageName {
    return SILImageNameBeaconTypeBlueGecko;
}

- (NSString *)type {
    return @"Blue Gecko";
}

- (NSNumber *)rssi {
    return @(self.beacon.calibrationPower);
}

- (NSNumber *)tx {
    return self.beacon.txPower;
}

- (SILDoubleKeyDictionaryPair *)beaconDetails {
    SILDoubleKeyDictionaryPair *orderedDetails = [[SILDoubleKeyDictionaryPair alloc] init];
    [orderedDetails addObject:self.beacon.UUIDString nameKey:@"UUID" idKey:@(1)];
    return orderedDetails;
}

@end
