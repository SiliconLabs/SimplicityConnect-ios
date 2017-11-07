//
//  SILBeaconRegistryEntry.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/21/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SILBeacon;
@class SILRSSIMeasurementTable;

@interface SILBeaconRegistryEntry : NSObject

@property (strong, nonatomic) SILBeacon *beacon;
@property (strong, nonatomic) SILRSSIMeasurementTable *RSSIMeasurementTable;

- (instancetype)initWithBeacon:(SILBeacon *)beacon;

@end
