//
//  SILRSSIMeasurementTable.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/6/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILRSSIMeasurementTable.h"
#import "SILRSSIMeasurement.h"

@interface SILRSSIMeasurementTable ()

@property (strong, nonatomic) NSMutableArray *RSSIMeasurements;

@end

@implementation SILRSSIMeasurementTable

- (instancetype)init {
    self = [super init];
    if (self) {
        self.RSSIMeasurements = [NSMutableArray array];
    }
    return self;
}

- (void)addRSSIMeasurement:(NSNumber *)RSSI {
    NSInteger RSSIInteger = [RSSI integerValue];
    if (RSSIInteger <= 20 && RSSIInteger >= -100) {
        [self.RSSIMeasurements addObject:[[SILRSSIMeasurement alloc] initWithRSSI:RSSI date:[NSDate date]]];
    }
}

- (NSNumber *)lastRSSIMeasurement {
    return [[self.RSSIMeasurements lastObject] RSSI];
}

- (BOOL)hasRSSIMeasurementInPastTimeInterval:(NSTimeInterval)timeInterval {
    NSDate *referenceDate = [NSDate date];
    NSDate *lastRSSIMeasurementDate = [[self.RSSIMeasurements lastObject] date];
    return [referenceDate timeIntervalSinceDate:lastRSSIMeasurementDate] < timeInterval;
}

- (NSNumber *)averageRSSIMeasurementInPastTimeInterval:(NSTimeInterval)timeInterval {
    NSDate *date = [NSDate date];
    NSArray *filtered = [self.RSSIMeasurements filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(SILRSSIMeasurement *measurement, NSDictionary *bindings) {
        NSDate *measurementDate = measurement.date;
        return [date timeIntervalSinceDate:measurementDate] < timeInterval;
    }]];

    if (filtered.count > 0) {
        return [filtered valueForKeyPath:@"@avg.RSSI.shortValue"];
    } else {
        return [NSNumber numberWithShort:0];
    }
}

@end
