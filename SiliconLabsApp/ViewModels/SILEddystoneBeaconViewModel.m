//
//  SILEddystoneBeaconViewModel.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 2/23/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILEddystoneBeaconViewModel.h"
#import "SILBeacon.h"
#import "SILDoubleKeyDictionaryPair.h"

@implementation SILEddystoneBeaconViewModel

- (NSString *)imageName {
    return SILImageNameBeaconTypeEddystone;
}

- (NSString *)type {
    return @"Eddystone";
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
    [orderedDetails addObject:self.beacon.beaconNamespace nameKey:@"NAMESPACE" idKey:@(1)];
    [orderedDetails addObject:self.beacon.instance nameKey:@"INSTANCE" idKey:@(2)];
    [orderedDetails addObject:self.beacon.url.absoluteString nameKey:@"URL" idKey:@(3)];
    return orderedDetails;
}

@end
