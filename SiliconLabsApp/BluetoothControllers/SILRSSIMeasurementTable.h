//
//  SILRSSIMeasurementTable.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/6/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SILRSSIMeasurementTable : NSObject

- (void)addRSSIMeasurement:(NSNumber *)RSSI;
- (NSNumber *)lastRSSIMeasurement;
- (BOOL)hasRSSIMeasurementInPastTimeInterval:(NSTimeInterval)timeInterval;
- (NSNumber *)averageRSSIMeasurementInPastTimeInterval:(NSTimeInterval)timeInterval;

@end
