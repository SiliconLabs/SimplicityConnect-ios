//
//  SILAltBeaconViewModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/18/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILAltBeaconViewModel.h"
#import "SILBeacon.h"
#import "SILDoubleKeyDictionaryPair.h"

@implementation SILAltBeaconViewModel

- (NSString *)imageName {
    return SILImageNameBeaconTypeAltBeacon;
}

- (NSString *)type {
    return @"AltBeacon";
}

- (NSNumber *)rssi {
    return @(self.beacon.calibrationPower);
}

- (NSNumber *)tx {
    return self.beacon.txPower;
}

- (SILDoubleKeyDictionaryPair *)beaconDetails {
    SILDoubleKeyDictionaryPair *orderedDetails = [[SILDoubleKeyDictionaryPair alloc] init];
    //ids are added as a way to order the entries
    [orderedDetails addObject:self.beacon.UUIDString nameKey:@"BEACON ID" idKey:@(1)];
    [orderedDetails addObject:@"0x0047" nameKey:@"MANUFACTURER ID" idKey:@(2)];
    [orderedDetails addObject:[self.beacon.refRSSI stringValue] nameKey:@"REFERENCE RSSI" idKey:@(3)];
    return orderedDetails;
}

@end
