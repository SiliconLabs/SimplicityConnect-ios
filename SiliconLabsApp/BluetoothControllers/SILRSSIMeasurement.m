//
//  SILRSSIMeasurement.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/6/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILRSSIMeasurement.h"

@implementation SILRSSIMeasurement

- (instancetype)initWithRSSI:(NSNumber *)RSSI date:(NSDate *)date {
    self = [super init];
    if (self) {
        self.RSSI = RSSI;
        self.date = date;
    }
    return self;
}

@end
