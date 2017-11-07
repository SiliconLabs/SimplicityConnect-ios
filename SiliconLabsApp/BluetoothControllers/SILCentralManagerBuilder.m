//
//  SILCentralManagerBuilder.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/14/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "SILCentralManagerBuilder.h"
#import "SILCentralManager.h"
#import "SILConstants.h"

@implementation SILCentralManagerBuilder

+ (SILCentralManager *)buildCentralManagerWithAppType:(SILAppType)appType {
    NSArray *serviceUUIDs = @[];
    switch (appType) {
        case SILAppTypeHealthThermometer:
            serviceUUIDs = @[
                             [CBUUID UUIDWithString:SILServiceNumberHealthThermometer],
                             [CBUUID UUIDWithString:@"FFF0"], // Temporarily added to support connecting to 3rd Party Thermometer...
                             ];
            break;
        default:
            break;
    }
    return [[SILCentralManager alloc] initWithServiceUUIDs:serviceUUIDs];
}

@end
