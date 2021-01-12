//
//  SILDeviceSelectionViewModel.m
//  SiliconLabsApp
//
//  Created by jamaal.sedayao on 10/17/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILDeviceSelectionViewModel.h"
#import "SILApp+AttributedProfiles.h"
#import "SILRSSIMeasurementTable.h"

CGFloat const SILDeviceSelectionViewModelRSSIThreshold = 1.0;

@implementation SILDeviceSelectionViewModel

- (instancetype)initWithAppType:(SILApp *)app {
    self = [super init];
    self.app = app;
    self.filter = ^BOOL(SILDiscoveredPeripheral* _) {
        return YES;
    };
    
    return self;
}

- (void)updateDiscoveredPeripheralsWithDiscoveredPeripherals:(NSArray<SILDiscoveredPeripheral*>*)discoveredPeripherals {
    self.discoveredDevices = [self sortedDiscoveredDevices:[self removeNonConnectableDevices:discoveredPeripherals]];
    self.hasDataChanged = YES;
}

- (NSArray<SILDiscoveredPeripheral*>*)removeNonConnectableDevices:(NSArray<SILDiscoveredPeripheral*>*)discoveredPeripherals {
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
    if (self.app.appType == SILAppTypeHealthThermometer) {
        return @"Select a Bluetooth Device";
    } else if (self.app.appType == SILAppTypeConnectedLighting || self.app.appType == SILAppTypeRangeTest) {
        return @"Select a Wireless Gecko Device";
    } else {
        return @"";
    }
}

@end
