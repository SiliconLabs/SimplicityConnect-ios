//
//  SILBeaconRegistryEntryViewModel.h
//  SiliconLabsApp
//
//  Created by Bob Gilmore on 3/16/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILBeacon.h"
#import "SILBeaconRegistryEntry.h"
#import "SILBeaconViewModel.h"
#import "SILProximityCalculator.h"
#import "SILRSSIMeasurementTable.h"

#ifndef SILBeaconRegistryEntryViewModel_h
#define SILBeaconRegistryEntryViewModel_h

@interface SILBeaconRegistryEntryViewModel : NSObject
@property (strong, nonatomic, readonly) SILBeaconRegistryEntry *entry;
@property (strong, nonatomic, readonly) SILBeaconViewModel *beaconViewModel;
@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSString *imageName;
@property (strong, nonatomic, readonly) UIImage *image;
@property (strong, nonatomic, readonly) NSString *type;
@property (strong, nonatomic, readonly) UIImage *distanceImage;
@property (strong, nonatomic, readonly) NSString *distanceName;
@property (strong, nonatomic, readonly) NSString *formattedRSSI;
@property (strong, nonatomic, readonly) NSString *formattedTx;

- (instancetype)initWithBeaconRegistryEntry:(SILBeaconRegistryEntry *)entry;

@end

#endif /* SILBeaconRegistryEntryViewModel_h */
