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
    return self;
}

- (void)updateDiscoveredPeripheralsWithDiscoveredPeripherals:(NSArray *)discoveredPeripherals {
    self.discoveredCompatibleDevices = [NSMutableArray array];
    self.discoveredOtherDevices = [NSMutableArray array];
    
    for (SILDiscoveredPeripheral *discoveredPeripheral in discoveredPeripherals) {
        const BOOL isCompatibleDevice = [self isCompatibleDevice:discoveredPeripheral];
        
        if (isCompatibleDevice) {
            [self.discoveredCompatibleDevices addObject:discoveredPeripheral];
        } else {
            [self.discoveredOtherDevices addObject:discoveredPeripheral];
        }
    }
    
    [self sortDiscoveredDevices:self.discoveredCompatibleDevices];
    [self sortDiscoveredDevices:self.discoveredOtherDevices];
    
    self.hasDataChanged = YES;
}

- (BOOL)isCompatibleDevice:(SILDiscoveredPeripheral *)discoveredPeripheral {
    NSArray * compatibleServices;
    
    if (self.app.appType == SILAppTypeRangeTest) {
        compatibleServices = @[
                               @([discoveredPeripheral isRangeTest]),
                               ];
    } else {
        compatibleServices = @[
                               @([discoveredPeripheral isBlueGeckoBeacon]),
                               @([discoveredPeripheral isDMPConnectedLightConnect]),
                               @([discoveredPeripheral isDMPConnectedLightProprietary]),
                               @([discoveredPeripheral isDMPConnectedLightThread]),
                               @([discoveredPeripheral isDMPConnectedLightZigbee]),
                               ];
    }
    
    return [compatibleServices containsObject:@(YES)];
}

- (void)sortDiscoveredDevices:(NSMutableArray*)devices {
    [devices sortUsingComparator:^NSComparisonResult(SILDiscoveredPeripheral* obj1, SILDiscoveredPeripheral* obj2) {
        NSString *nameOfObj1 = obj1.advertisedLocalName;
        NSString *nameOfObj2 = obj2.advertisedLocalName;
        
        if (nameOfObj1 != nil) {
            return [nameOfObj1 localizedCaseInsensitiveCompare:nameOfObj2];
        } else if (nameOfObj2 != nil) {
            return [nameOfObj2 localizedCaseInsensitiveCompare:nameOfObj1];
        } else {
            return NSOrderedSame;
        }
    }];
}

- (NSArray *)discoveredDevicesForIndex:(NSInteger)index {
    if (index == 0) {
        return self.discoveredCompatibleDevices;
    } else {
        return self.discoveredOtherDevices;
    }
}

- (NSArray *)availableTabs {
    if (self.app.appType == SILAppTypeHealthThermometer) {
        return @[@"Blue Geckos", @"Other"];
    } else if (self.app.appType == SILAppTypeConnectedLighting || self.app.appType == SILAppTypeRangeTest) {
        return @[@"Wireless Gecko"];
    } else {
        return @[@""];
    }
}

- (NSString *)selectDeviceString {
    if (self.app.appType == SILAppTypeHealthThermometer) {
        return @"Select a Bluetooth Smart Device";
    } else if (self.app.appType == SILAppTypeConnectedLighting || self.app.appType == SILAppTypeRangeTest) {
        return @"Select a Wireless Gecko Device";
    } else {
        return @"";
    }
}

- (NSString *)appTitleLabelString {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? self.app.title : [self.app.title uppercaseString];
}

- (NSString *)appDescriptionString {
    return self.app.appDescription;
}

- (NSAttributedString *)appShowcaseLabelString {
    return [self.app showcasedProfilesAttributedStringWithUserInterfaceIdiom:UI_USER_INTERFACE_IDIOM()];
}

@end
