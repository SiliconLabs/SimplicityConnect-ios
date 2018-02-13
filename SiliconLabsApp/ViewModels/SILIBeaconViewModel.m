//
//  SILIBeaconViewModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/18/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILIBeaconViewModel.h"
#import "SILBeacon.h"
#import "SILDoubleKeyDictionaryPair.h"

@implementation SILIBeaconViewModel

- (NSString *)imageName {
    return SILImageNameBeaconTypeIBeacon;
}

- (NSString *)type {
    return @"iBeacon";
}

- (NSNumber *)rssi {
    return @(self.beacon.beacon.rssi);
}

- (NSNumber *)tx {
    return self.beacon.txPower;
}

- (SILDoubleKeyDictionaryPair *)beaconDetails {
    SILDoubleKeyDictionaryPair *orderedDetails = [[SILDoubleKeyDictionaryPair alloc] init];
    //ids are added as a way to order the entries
    [orderedDetails addObject:self.beacon.UUIDString nameKey:@"UUID" idKey:@(1)];
    [orderedDetails addObject:[@(self.beacon.major) stringValue] nameKey:@"MAJOR NUMBER" idKey:@(2)];
    [orderedDetails addObject:[@(self.beacon.minor) stringValue] nameKey:@"MINOR NUMBER" idKey:@(3)];
    return orderedDetails;
}

@end
