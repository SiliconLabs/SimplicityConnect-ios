//
//  SILDeviceSelectionViewModel.m
//  SiliconLabsApp
//
//  Created by jamaal.sedayao on 10/17/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILDeviceSelectionViewModel.h"
#import "SILApp+AttributedProfiles.h"

CGFloat const SILDeviceSelectionViewModelRSSIThreshold = 1.0;

@implementation SILDeviceSelectionViewModel

- (instancetype)initWithAppType:(SILApp *)app {
    self = [super init];
    self.app = app;
    self.discoveredDevices = @[];
    self.filter = ^BOOL(SILDiscoveredPeripheral* peripheral) {
        for (CBUUID * cbuuid in [SILDeviceSelectionViewModel serviceListForAppType:app.appType]) {
            if ([peripheral.advertisedServiceUUIDs containsObject:cbuuid]) {
                return YES;
            }
        }
        return NO;
    };
    
    return self;
}

- (instancetype)initWithAppType:(SILApp *)app withFilter:(DiscoveredPeripheralFilter)filter {
    self = [super init];
    self.app = app;
    self.discoveredDevices = @[];
    self.filter = filter;
    
    return self;
}

+ (NSArray*)serviceListForAppType:(SILAppType)appType {
    NSArray *serviceUUIDs = @[];
    switch (appType) {
        case SILAppTypeHealthThermometer:
            serviceUUIDs = @[
                             [CBUUID UUIDWithString:SILServiceNumberHealthThermometer],
                             [CBUUID UUIDWithString:@"FFF0"], // Temporarily added to support connecting to 3rd Party Thermometer...
                             ];
            break;
        case SILAppTypeConnectedLighting:
            serviceUUIDs = @[[CBUUID UUIDWithString:SILServiceNumberConnectedLightingConnect],
                             [CBUUID UUIDWithString:SILServiceNumberConnectedLightingProprietary],
                             [CBUUID UUIDWithString:SILServiceNumberConnectedLightingThread],
                             [CBUUID UUIDWithString:SILServiceNumberConnectedLightingZigbee],];
            break;
        default:
            break;
    }
    return serviceUUIDs;
}

- (void)updateDiscoveredPeripheralsWithDiscoveredPeripherals:(NSArray<SILDiscoveredPeripheral*>*)discoveredPeripherals {
    self.discoveredDevices = [self sortedDiscoveredDevices:[self removeDevicesNotMatchRequirements:discoveredPeripherals]];
    self.hasDataChanged = YES;
}

- (NSArray<SILDiscoveredPeripheral*>*)removeDevicesNotMatchRequirements:(NSArray<SILDiscoveredPeripheral*>*)discoveredPeripherals {
    NSPredicate* filterPredicate = [NSPredicate predicateWithBlock:^BOOL(SILDiscoveredPeripheral* evaluatedObject, NSDictionary<NSString *,id>* bindings) {
        return evaluatedObject.isConnectable && self.filter(evaluatedObject);
    }];
    
    return [discoveredPeripherals filteredArrayUsingPredicate:filterPredicate];
}

- (NSArray<SILDiscoveredPeripheral*>*)sortedDiscoveredDevices:(NSArray<SILDiscoveredPeripheral*>*)discoveredPeripherals {
    return [discoveredPeripherals sortedArrayUsingComparator:^NSComparisonResult(SILDiscoveredPeripheral* obj1, SILDiscoveredPeripheral* obj2) {
        return [self compareFirstPeripheral:obj1 withSecondPeripheral:obj2];
    }];
}

- (NSInteger)compareFirstPeripheral:(SILDiscoveredPeripheral*)obj1 withSecondPeripheral:(SILDiscoveredPeripheral*)obj2 {
    NSString *nameOfObj1 = obj1.advertisedLocalName;
    NSString *nameOfObj2 = obj2.advertisedLocalName;
    
    if (nameOfObj1 != nil) {
        return [nameOfObj1 localizedCaseInsensitiveCompare:nameOfObj2];
    } else if (nameOfObj2 != nil) {
        return [nameOfObj2 localizedCaseInsensitiveCompare:nameOfObj1];
    } else {
        return NSOrderedSame;
    }
}

- (NSString *)selectDeviceString {
    switch (self.app.appType) {
        case SILAppTypeHealthThermometer:
        case SILAppTypeThroughput:
        case SILAppIopTest:
        case SILAppTypeBlinky:
        case SILAppTypeWifiCommissioning:
            return @"Select a Bluetooth Device";
        case SILAppTypeConnectedLighting:
        case SILAppTypeRangeTest:
            return @"Select a Wireless Gecko Device";
        default:
            return @"";
    }
}

@end
